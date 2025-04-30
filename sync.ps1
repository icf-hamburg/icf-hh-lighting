# Video Folder Sync Script
# This script ensures consistency between a source folder with video files in subfolders
# and a destination folder with MOV files in a flat structure
# It identifies files needing conversion and creates links to them in a "_TO_CONVERT" subfolder

param (
    [Parameter(Mandatory = $true)]
    [string]$SourceFolder,

    [Parameter(Mandatory = $true)]
    [string]$DestinationFolder,

    [Parameter(Mandatory = $false)]
    [switch]$WhatIf = $false,

    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
)

# Function to log messages
function Write-Log
{
    param([string]$Message, [string]$Type = "INFO")

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Type] $Message"

    if ($Type -eq "ERROR")
    {
        Write-Host $logMessage -ForegroundColor Red
    }
    elseif ($Type -eq "WARNING")
    {
        Write-Host $logMessage -ForegroundColor Yellow
    }
    elseif ($Type -eq "SUCCESS")
    {
        Write-Host $logMessage -ForegroundColor Green
    }
    else
    {
        Write-Host $logMessage
    }
}

# Function to convert source filename to destination filename
function Convert-ToDestinationFilename
{
    param([string]$SourcePath)

    # Extract filename without path and replace extension
    $filename = [System.IO.Path]::GetFileNameWithoutExtension($SourcePath)
    return "$filename.mov"
}

# Function to confirm deletion with the user
function Confirm-FileDeletion
{
    param(
        [string[]]$FilesToDelete
    )

    if ($FilesToDelete.Count -eq 0)
    {
        return $true
    }

    Write-Host "`n----------------------------------------------------" -ForegroundColor Yellow
    Write-Host "The following files will be deleted:" -ForegroundColor Yellow
    Write-Host "----------------------------------------------------" -ForegroundColor Yellow

    $counter = 1
    foreach ($file in $FilesToDelete)
    {
        Write-Host "$counter. $file" -ForegroundColor Yellow
        $counter++
    }

    Write-Host "----------------------------------------------------" -ForegroundColor Yellow
    $response = Read-Host "Do you want to proceed with deletion? (Y/N)"

    return $response.ToUpper() -eq 'Y'
}

# Function to create a symbolic link
function New-ConversionLink
{
    param(
        [string]$SourcePath,
        [string]$LinkFolder
    )

    # Ensure the link folder exists
    if (-not (Test-Path -Path $LinkFolder))
    {
        New-Item -Path $LinkFolder -ItemType Directory | Out-Null
    }

    # Create the link
    $linkTarget = Join-Path -Path $LinkFolder -ChildPath (Split-Path -Path $SourcePath -Leaf)

    # Use different methods depending on OS
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6)
    {
        # For Windows, create a shortcut
        $WshShell = New-Object -ComObject WScript.Shell
        $shortcut = $WshShell.CreateShortcut($linkTarget + ".lnk")
        $shortcut.TargetPath = $SourcePath
        $shortcut.Save()
    }
    else
    {
        # For Linux/MacOS, create a symbolic link
        New-Item -ItemType SymbolicLink -Path $linkTarget -Target $SourcePath | Out-Null
    }

    return $linkTarget
}


# Function to get relative path
function Get-RelativePath
{
    param(
        [string]$FullPath,
        [string]$BasePath
    )

    # Ensure paths have consistent format
    $FullPath = $FullPath.Replace('/', '\')
    $BasePath = $BasePath.Replace('/', '\')

    # Ensure base path ends with backslash
    if (-not $BasePath.EndsWith('\'))
    {
        $BasePath = "$BasePath\"
    }

    # If the full path starts with the base path, remove it
    if ( $FullPath.StartsWith($BasePath, [StringComparison]::OrdinalIgnoreCase))
    {
        return $FullPath.Substring($BasePath.Length)
    }

    # Otherwise return the full path
    return $FullPath
}

# Validate folders exist
if (-not (Test-Path -Path $SourceFolder -PathType Container))
{
    Write-Log "Source folder does not exist: $SourceFolder" "ERROR"
    exit 1
}

if (-not (Test-Path -Path $DestinationFolder -PathType Container))
{
    if ($WhatIf)
    {
        Write-Log "Destination folder would be created: $DestinationFolder" "WARNING"
    }
    else
    {
        Write-Log "Creating destination folder: $DestinationFolder" "INFO"
        New-Item -Path $DestinationFolder -ItemType Directory | Out-Null
    }
}

# Create the _TO_CONVERT subfolder path
$toConvertFolder = Join-Path -Path $DestinationFolder -ChildPath "_TO_CONVERT"

# Clean up any existing _TO_CONVERT folder
if (Test-Path -Path $toConvertFolder)
{
    if ($WhatIf)
    {
        Write-Log "Would remove existing _TO_CONVERT folder: $toConvertFolder" "INFO"
    }
    else
    {
        Write-Log "Removing existing _TO_CONVERT folder: $toConvertFolder" "INFO"
        Remove-Item -Path $toConvertFolder -Recurse -Force
    }
}

# Get all video files in source folder (including subfolders)
Write-Log "Scanning source folder for video files..." "INFO"
$sourceFiles = Get-ChildItem -Path $SourceFolder -Recurse -File | Where-Object {
    $_.Extension -match "\.(mp4|mov|avi|wmv|mkv|flv|webm|m4v)$"
}

# Get all MOV files in destination folder
# Write-Log "Scanning destination folder for MOV files..." "INFO"
$destFiles = Get-ChildItem -Path $DestinationFolder -Filter "*.mov" -File

# Write-Log "Found $($destFiles.Count) MOV files in destination folder" "INFO"

# Create hashtable of destination files for faster lookup
$destFilesDict = @{ }
foreach ($file in $destFiles)
{
    $destFilesDict[$file.Name] = $file
}

# Counter variables
$filesToConvert = 0
$filesToDelete = 0

# 1. Check for source files that need to be converted or updated
foreach ($sourceFile in $sourceFiles)
{
    $destFilename = Convert-ToDestinationFilename $sourceFile.Name
    $destFullPath = Join-Path -Path $DestinationFolder -ChildPath $destFilename
    $needsConversion = $false

    # Check if file exists in destination
    if (-not $destFilesDict.ContainsKey($destFilename))
    {
        # File needs to be converted
        $filesToConvert++
        $needsConversion = $true
        $relativePath = Get-RelativePath -FullPath $sourceFile.FullName -BasePath $SourceFolder
        Write-Log "File needs conversion: $relativePath" "INFO"
    }
    else
    {
        # File exists, check if source file is newer
        $sourceFileDate = $sourceFile.LastWriteTime
        $destFileDate = $destFilesDict[$destFilename].LastWriteTime

        if ($sourceFileDate -gt $destFileDate)
        {
            $filesToConvert++
            $needsConversion = $true
            Write-Log "File needs update (source is newer): $( $sourceFile.Name )" "INFO"
        }
        else
        {
            if ($Verbose)
            {
                Write-Log "File is up to date: $( $sourceFile.Name )" "INFO"
            }
        }

        # Remove from the dictionary to keep track of extra files
        $destFilesDict.Remove($destFilename)
    }

    # Create a link in the _TO_CONVERT folder if needed
    if ($needsConversion)
    {
        if ($WhatIf)
        {
            Write-Log "Would create link for $( $sourceFile.Name ) in _TO_CONVERT folder" "INFO"
        }
        else
        {
            try
            {
                $linkPath = New-ConversionLink -SourcePath $sourceFile.FullName -LinkFolder $toConvertFolder
                Write-Log "Created link for conversion: $linkPath" "SUCCESS"
            }
            catch
            {
                Write-Log "Error creating link: $( $_.Exception.Message )" "ERROR"
            }
        }
    }
}

# 2. Check for destination files that no longer have a source
$filesToDeleteList = @()

foreach ($destFile in $destFilesDict.Keys)
{
    $filesToDelete++
    $destFullPath = Join-Path -Path $DestinationFolder -ChildPath $destFile
    $filesToDeleteList += $destFullPath
    Write-Log "File to be deleted (no longer in source): $destFullPath" "WARNING"
}

# If there are files to delete, confirm with the user
if ($filesToDelete -gt 0 -and -not $WhatIf)
{
    $proceedWithDeletion = $Force -or (Confirm-FileDeletion -FilesToDelete $filesToDeleteList)

    if ($proceedWithDeletion)
    {
        foreach ($fileToDelete in $filesToDeleteList)
        {
            try
            {
                Remove-Item -Path $fileToDelete -Force
                Write-Log "Deleted: $( Split-Path -Path $fileToDelete -Leaf )" "SUCCESS"
            }
            catch
            {
                Write-Log "Error deleting file: $( $_.Exception.Message )" "ERROR"
            }
        }
    }
    else
    {
        Write-Log "File deletion canceled by user" "WARNING"
        $filesToDelete = 0  # Reset count since no files were actually deleted
    }
}

if ($filesToConvert -gt 0)
{
    Write-Log "Links to files requiring conversion have been placed in: $toConvertFolder" "WARNING"
    Write-Log "Please convert these files manually to MOV format and place them in: $DestinationFolder" "INFO"
}

if ($WhatIf)
{
    Write-Log "This was a dry run. No files were actually modified." "WARNING"
    Write-Log "Run without -WhatIf to perform the synchronization." "INFO"
}

# Summary
Write-Log "===== Synchronization Summary =====" "INFO"
Write-Log "MP4 files in source: $( $sourceFiles.Count )" "INFO"
Write-Log "MOV files in destination before sync: $( $destFiles.Count )" "INFO"
Write-Log "Files to convert/update: $filesToConvert" "INFO"
Write-Log "Files to delete: $filesToDelete" "INFO"

$expectedFinalCount = $sourceFiles.Count
Write-Log "Expected MOV files after sync: $expectedFinalCount" "INFO"

if ($WhatIf)
{
    Write-Log "This was a dry run. No files were actually modified." "WARNING"
    Write-Log "Run without -WhatIf to perform the synchronization." "INFO"
}

Write-Log "===== Synchronization Complete =====" "SUCCESS"

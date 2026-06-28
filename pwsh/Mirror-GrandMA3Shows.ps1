<#
.SYNOPSIS
    Mirrors the grandMA3 "shows" folders from every installed gMA3 version
    into the user's Google Drive (or the Desktop as a fallback), preserving
    the folder structure.

.DESCRIPTION
    Locates the grandMA3 data folder for the current operating system:
        Windows : C:\ProgramData\MALightingTechnology
        macOS   : ~/MALightingTechnology
    By default only the most recent version folder (highest gma3_<major>.<minor>.<patch>)
    is mirrored; pass -SyncAllVersions to mirror every version.
    For each selected version folder it mirrors the contents of
        <version>/shared/shows
    into
        <TargetRoot>/<version>/shared/shows
    The same relative folder structure is recreated in the target directory.

    Target root (auto-detected, same logic on Windows and macOS):
        1. The user's Google Drive root ("My Drive"), if Google Drive is installed.
        2. Otherwise the Desktop -- but only when -AllowDesktopFallback is given;
           by default the script ABORTS rather than silently backing up to the
           Desktop (important for unattended/scheduled runs).

    "Mirror" means the target is made identical to the source: new/changed files
    are copied and files that no longer exist in the source (or that are on the
    ignore list, e.g. metadatacache.dat) are removed from the target
    (unless -NoDelete is used).

.NOTES
    Requires PowerShell 7+ (pwsh) for cross-platform $IsWindows / $IsMacOS.
    Exit codes:  0 = success,  1 = failure (see the log file).
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    # Override the auto-detected source root if needed.
    [string] $SourceRoot,

    # Override the auto-detected target root if needed.
    [string] $TargetRoot,

    # Mirror every gma3_x.x.x version. By default only the highest version is mirrored.
    [switch] $SyncAllVersions,

    # Don't delete target files that are missing from the source.
    [switch] $NoDelete,

    # Allow falling back to the Desktop when no Google Drive folder is found.
    # Without this the script aborts instead (recommended for scheduled runs).
    [switch] $AllowDesktopFallback,

    # Folder for run logs. Defaults to a "logs" folder next to this script.
    [string] $LogDir,

    # Disable transcript logging entirely.
    [switch] $NoLog,

    # How many recent log files to keep (older ones are pruned).
    [int] $LogRetention = 30
)

# ----------------------------------------------------------------------------
#  CONFIGURATION
# ----------------------------------------------------------------------------

# Name of the backup container folder created inside Google Drive / Desktop.
$BackupFolderName = 'grandMA3-Backup'

# Only file names matching one of these patterns are copied. Anything else
# (e.g. metadatacache.dat, *.show.zip) is ignored and removed from the target.
$IncludeNames = @('*.show')

# Folders named like gma3_2.4.2  (excludes gma3_library, gma3_software_update, ...)
$VersionPattern = '^gma3_\d+\.\d+\.\d+$'
# ----------------------------------------------------------------------------

$ErrorActionPreference = 'Stop'

# --- helper: should this file be copied / kept? -----------------------------
function Test-Included {
    param([string] $Name)
    foreach ($pattern in $IncludeNames) {
        if ($Name -like $pattern) { return $true }
    }
    return $false
}

# --- helper: find the user's Google Drive root, else the Desktop ------------
#     Returns [pscustomobject] @{ Path = <path>; IsGoogleDrive = $true|$false }
function Get-DefaultTargetRoot {
    $candidates = @()

    if ($IsWindows) {
        # 1. Most reliable: Google Drive for Desktop mounts a virtual drive whose
        #    volume label is "Google Drive", regardless of the assigned letter.
        Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
            Where-Object { $_.VolumeName -eq 'Google Drive' } |
            ForEach-Object { $candidates += (Join-Path $_.DeviceID 'My Drive') }

        # 2. Otherwise scan every filesystem drive root for a "My Drive" folder
        #    (covers odd setups the label match misses).
        foreach ($d in (Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue)) {
            $candidates += (Join-Path $d.Root 'My Drive')
        }

        # 3. Folder-mount / legacy "Backup and Sync" locations under the profile.
        $candidates += (Join-Path $HOME 'My Drive')
        $candidates += (Join-Path $HOME 'Google Drive')
        $candidates += (Join-Path $HOME 'Drive')
    }
    else {
        # macOS (and Linux fallback).
        $cloud = Join-Path $HOME 'Library/CloudStorage'
        if (Test-Path -LiteralPath $cloud) {
            Get-ChildItem -LiteralPath $cloud -Directory -Filter 'GoogleDrive-*' -ErrorAction SilentlyContinue |
                Sort-Object Name | ForEach-Object {
                    $candidates += (Join-Path $_.FullName 'My Drive')
                }
        }
        $candidates += (Join-Path $HOME 'Google Drive')   # legacy client
    }

    foreach ($c in $candidates) {
        if ($c -and (Test-Path -LiteralPath $c -PathType Container)) {
            return [pscustomobject]@{ Path = $c; IsGoogleDrive = $true }
        }
    }

    # Fallback: the Desktop.
    $desktop = if ($IsWindows) {
        [Environment]::GetFolderPath('Desktop')
    } else {
        Join-Path $HOME 'Desktop'
    }
    return [pscustomobject]@{ Path = $desktop; IsGoogleDrive = $false }
}

# --- logging setup ----------------------------------------------------------
if (-not $LogDir) {
    $base = if ($PSScriptRoot) { $PSScriptRoot } else { (Get-Location).Path }
    $LogDir = Join-Path $base 'logs'
}

$transcriptStarted = $false
if (-not $NoLog) {
    try {
        if (-not (Test-Path -LiteralPath $LogDir)) {
            New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
        }
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $transcriptPath = Join-Path $LogDir "backup-$stamp.log"
        Start-Transcript -LiteralPath $transcriptPath -Force | Out-Null
        $transcriptStarted = $true

        # Prune old logs, keeping the newest $LogRetention.
        if ($LogRetention -gt 0) {
            Get-ChildItem -LiteralPath $LogDir -Filter 'backup-*.log' -ErrorAction SilentlyContinue |
                Sort-Object LastWriteTime -Descending |
                Select-Object -Skip $LogRetention |
                Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    catch {
        Write-Warning "Could not start transcript logging: $($_.Exception.Message)"
    }
}

# ============================================================================
#  MAIN
# ============================================================================
try {
    Write-Host "grandMA3 show backup -- $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"

    # --- resolve source root for the current OS unless supplied -------------
    if (-not $SourceRoot) {
        if ($IsWindows) {
            $SourceRoot = 'C:\ProgramData\MALightingTechnology'
        } else {
            # macOS / Linux.
            $SourceRoot = Join-Path $HOME 'MALightingTechnology'
        }
    }

    if (-not (Test-Path -LiteralPath $SourceRoot -PathType Container)) {
        throw "Source root not found: $SourceRoot"
    }

    # --- resolve target root -----------------------------------------------
    if (-not $TargetRoot) {
        $detected = Get-DefaultTargetRoot
        if (-not $detected.IsGoogleDrive -and -not $AllowDesktopFallback) {
            throw ("Google Drive folder not found (resolved fallback would be '$($detected.Path)'). " +
                   "Refusing to back up to the Desktop. Make sure Google Drive for Desktop is " +
                   "running and signed in, or pass -AllowDesktopFallback / an explicit -TargetRoot.")
        }
        if (-not $detected.IsGoogleDrive) {
            Write-Warning "Google Drive not found -- using Desktop fallback: $($detected.Path)"
        }
        $TargetRoot = Join-Path $detected.Path $BackupFolderName
    }

    Write-Host "Source : $SourceRoot"
    Write-Host "Target : $TargetRoot"
    Write-Host ''

    if (-not (Test-Path -LiteralPath $TargetRoot)) {
        if ($PSCmdlet.ShouldProcess($TargetRoot, 'Create directory')) {
            New-Item -ItemType Directory -Path $TargetRoot -Force | Out-Null
        }
    }

    # --- find version folders that contain a shared/shows directory --------
    $versionDirs = Get-ChildItem -LiteralPath $SourceRoot -Directory |
        Where-Object { $_.Name -match $VersionPattern }

    if (-not $versionDirs) {
        Write-Warning "No 'gma3_x.x.x' version folders found under $SourceRoot"
        return
    }

    # By default mirror only the highest version number; -SyncAllVersions mirrors all.
    if (-not $SyncAllVersions) {
        $versionDirs = $versionDirs |
            Sort-Object { [version]($_.Name -replace '^gma3_', '') } |
            Select-Object -Last 1
        Write-Host "Mirroring most recent version only: $($versionDirs.Name)  (use -SyncAllVersions for all)"
        Write-Host ''
    }

    $copied = 0; $removed = 0

    foreach ($verDir in $versionDirs) {
        $srcShows = Join-Path $verDir.FullName 'shared/shows'

        if (-not (Test-Path -LiteralPath $srcShows -PathType Container)) {
            Write-Host "  [skip] $($verDir.Name): no shared/shows folder"
            continue
        }

        # Keep the full <version>/shared/shows structure in the target.
        $dstShows = Join-Path (Join-Path $TargetRoot $verDir.Name) 'shared/shows'
        Write-Host "  [mirror] $($verDir.Name)/shared/shows"

        if (-not (Test-Path -LiteralPath $dstShows)) {
            if ($PSCmdlet.ShouldProcess($dstShows, 'Create directory')) {
                New-Item -ItemType Directory -Path $dstShows -Force | Out-Null
            }
        }

        $srcFull = (Resolve-Path -LiteralPath $srcShows).Path

        # Recreate sub-directory structure first.
        Get-ChildItem -LiteralPath $srcShows -Directory -Recurse | ForEach-Object {
            $rel = $_.FullName.Substring($srcFull.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/', '\')
            $target = Join-Path $dstShows $rel
            if (-not (Test-Path -LiteralPath $target)) {
                if ($PSCmdlet.ShouldProcess($target, 'Create directory')) {
                    New-Item -ItemType Directory -Path $target -Force | Out-Null
                }
            }
        }

        # Copy files (only included names; only when new or changed by size / write time).
        Get-ChildItem -LiteralPath $srcShows -File -Recurse | ForEach-Object {
            if (-not (Test-Included $_.Name)) { return }

            $rel = $_.FullName.Substring($srcFull.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/', '\')
            $target = Join-Path $dstShows $rel

            $needCopy = $true
            if (Test-Path -LiteralPath $target) {
                $t = Get-Item -LiteralPath $target
                if ($t.Length -eq $_.Length -and $t.LastWriteTimeUtc -ge $_.LastWriteTimeUtc) {
                    $needCopy = $false
                }
            }

            if ($needCopy) {
                if ($PSCmdlet.ShouldProcess($target, 'Copy file')) {
                    $parent = Split-Path -Parent $target
                    if (-not (Test-Path -LiteralPath $parent)) {
                        New-Item -ItemType Directory -Path $parent -Force | Out-Null
                    }
                    Copy-Item -LiteralPath $_.FullName -Destination $target -Force
                }
                $script:copied++
                Write-Host "      + $rel"
            }
        }

        # --- delete target items that no longer exist (or are excluded) -----
        if (-not $NoDelete -and (Test-Path -LiteralPath $dstShows)) {
            $dstFull = (Resolve-Path -LiteralPath $dstShows).Path

            # Files first.
            Get-ChildItem -LiteralPath $dstShows -File -Recurse | ForEach-Object {
                $rel = $_.FullName.Substring($dstFull.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/', '\')
                $srcItem = Join-Path $srcShows $rel
                if ((-not (Test-Included $_.Name)) -or (-not (Test-Path -LiteralPath $srcItem))) {
                    if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove file')) {
                        Remove-Item -LiteralPath $_.FullName -Force
                    }
                    $script:removed++
                    Write-Host "      - $rel"
                }
            }

            # Then orphaned directories (deepest first).
            Get-ChildItem -LiteralPath $dstShows -Directory -Recurse |
                Sort-Object { $_.FullName.Length } -Descending | ForEach-Object {
                    $rel = $_.FullName.Substring($dstFull.Length).TrimStart([IO.Path]::DirectorySeparatorChar, '/', '\')
                    $srcItem = Join-Path $srcShows $rel
                    if (-not (Test-Path -LiteralPath $srcItem)) {
                        if ($PSCmdlet.ShouldProcess($_.FullName, 'Remove directory')) {
                            Remove-Item -LiteralPath $_.FullName -Recurse -Force
                        }
                    }
                }
        }
    }

    Write-Host ''
    Write-Host "Done. $copied file(s) copied, $removed removed."
    $exitCode = 0
}
catch {
    Write-Host ''
    Write-Error "BACKUP FAILED: $($_.Exception.Message)"
    Write-Host $_.ScriptStackTrace
    $exitCode = 1
}
finally {
    if ($transcriptStarted) {
        try { Stop-Transcript | Out-Null } catch { }
    }
}

exit $exitCode

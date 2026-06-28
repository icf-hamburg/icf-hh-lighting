<#
.SYNOPSIS
    Registers (or re-registers) a Windows Task Scheduler job that runs
    Mirror-GrandMA3Shows.ps1 at one or more times of day.

.DESCRIPTION
    Creates a scheduled task with the settings recommended for this backup:
      * Runs PowerShell 7 (pwsh.exe) with -NoProfile -ExecutionPolicy Bypass -File.
      * Runs ONLY when the user is logged on, in the interactive session, so that
        Google Drive for Desktop's "My Drive" is mounted and visible.
      * Does NOT run with highest privileges (writes go to the user's Drive).
      * Catches up after a missed start (machine was off/asleep).
      * Never starts a second instance if one is still running.
      * Stops a run that exceeds the execution time limit.

    Re-running this script updates the existing task (same -TaskName).

    Windows only. Must be run as the user who is logged in with Google Drive.

.EXAMPLE
    pwsh -File .\Register-Backup-Task.ps1
    Daily backup at 12:00 and 18:00.

.EXAMPLE
    pwsh -File .\Register-Backup-Task.ps1 -At '07:30','19:00' -SyncAllVersions
    Twice daily, mirroring every installed gMA3 version.

.EXAMPLE
    pwsh -File .\Register-Backup-Task.ps1 -Unregister
    Removes the task.
#>

[CmdletBinding()]
param(
    # Times of day to run (24h "HH:mm"). One trigger is created per entry.
    [string[]] $At = @('12:00', '18:00'),

    # Name of the scheduled task.
    [string] $TaskName = 'grandMA3 Show Backup',

    # Path to the backup script. Defaults to the one next to this installer.
    [string] $ScriptPath,

    # Pass-through: mirror every version instead of only the most recent.
    [switch] $SyncAllVersions,

    # Pass-through: never delete files from the target.
    [switch] $NoDelete,

    # Max run time before Task Scheduler force-stops the task.
    [timespan] $ExecutionTimeLimit = (New-TimeSpan -Hours 2),

    # Remove the task instead of creating it.
    [switch] $Unregister
)

$ErrorActionPreference = 'Stop'

if (-not $IsWindows) {
    throw "This installer is for Windows Task Scheduler. On macOS use a launchd LaunchAgent (see README.md)."
}

# --- unregister mode --------------------------------------------------------
if ($Unregister) {
    if (Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue) {
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        Write-Host "Removed scheduled task '$TaskName'."
    } else {
        Write-Host "No scheduled task named '$TaskName' found."
    }
    return
}

# --- locate pwsh and the backup script --------------------------------------
$pwsh = (Get-Command pwsh -ErrorAction SilentlyContinue)?.Source
if (-not $pwsh) {
    throw "PowerShell 7 (pwsh.exe) not found on PATH. Install it (winget install Microsoft.PowerShell) and retry."
}

if (-not $ScriptPath) {
    $ScriptPath = Join-Path $PSScriptRoot 'Mirror-GrandMA3Shows.ps1'
}
$ScriptPath = (Resolve-Path -LiteralPath $ScriptPath).Path
if (-not (Test-Path -LiteralPath $ScriptPath -PathType Leaf)) {
    throw "Backup script not found: $ScriptPath"
}

# --- build the script arguments ---------------------------------------------
$scriptArgs = @()
if ($SyncAllVersions) { $scriptArgs += '-SyncAllVersions' }
if ($NoDelete)        { $scriptArgs += '-NoDelete' }

$argLine = "-NoProfile -ExecutionPolicy Bypass -File `"$ScriptPath`""
if ($scriptArgs.Count) { $argLine += ' ' + ($scriptArgs -join ' ') }

# --- assemble the task ------------------------------------------------------
$action = New-ScheduledTaskAction -Execute $pwsh -Argument $argLine -WorkingDirectory (Split-Path -Parent $ScriptPath)

$triggers = foreach ($t in $At) {
    # Validate the time format.
    $null = [datetime]::ParseExact($t, 'HH:mm', $null)
    New-ScheduledTaskTrigger -Daily -At $t
}

# Interactive logon = runs in the desktop session where Google Drive is mounted.
$principal = New-ScheduledTaskPrincipal -UserId ("{0}\{1}" -f $env:USERDOMAIN, $env:USERNAME) `
    -LogonType Interactive -RunLevel Limited

$settings = New-ScheduledTaskSettingsSet `
    -StartWhenAvailable `
    -MultipleInstances IgnoreNew `
    -ExecutionTimeLimit $ExecutionTimeLimit `
    -DontStopOnIdleEnd `
    -AllowStartIfOnBatteries `
    -DontStopIfGoingOnBatteries

$task = New-ScheduledTask -Action $action -Trigger $triggers -Principal $principal -Settings $settings `
    -Description "Mirror grandMA3 shows to Google Drive. Runs: $($At -join ', ')."

# --- register (replacing any existing task of the same name) ----------------
Register-ScheduledTask -TaskName $TaskName -InputObject $task -Force | Out-Null

Write-Host "Registered scheduled task '$TaskName'."
Write-Host "  Runs at      : $($At -join ', ') (daily)"
Write-Host "  Command      : $pwsh $argLine"
Write-Host ""
Write-Host "Test it now with:"
Write-Host "  Start-ScheduledTask  -TaskName '$TaskName'"
Write-Host "  Get-ScheduledTaskInfo -TaskName '$TaskName'   # check LastTaskResult (0 = success)"

# grandMA3 Show Backup

Mirrors grandMA3 show files into Google Drive, cross-platform (Windows + macOS),
with an optional Windows Task Scheduler installer for automated runs.

## Files

| File | Purpose |
|------|---------|
| `Mirror-GrandMA3Shows.ps1` | The backup script. Run manually or via a scheduler. |
| `Register-Backup-Task.ps1` | Windows-only installer that registers a scheduled task. |
| `logs/` | Per-run transcript logs (auto-created, auto-pruned). |

## Requirements

- **PowerShell 7+ (`pwsh`)** — not Windows PowerShell 5.1.
  Install on Windows: `winget install Microsoft.PowerShell`
- **Google Drive for Desktop**, signed in and running (the backup target).

## What it does

For each installed grandMA3 version under the source folder, it mirrors
`<version>/shared/shows` into `<Target>/grandMA3-Backup/<version>/shared/shows`.

- **Source** — `C:\ProgramData\MALightingTechnology` (Windows) / `~/MALightingTechnology` (macOS).
- **Target** — auto-detected Google Drive `My Drive`, under a `grandMA3-Backup/` folder.
- **By default only the most recent version** is mirrored (`-SyncAllVersions` for all).
- **Only `*.show` files** are copied; `metadatacache.dat` and `*.show.zip` are ignored.
- **Incremental** — unchanged files (same size + mtime) are skipped, so reruns are cheap.
- **Mirror semantics** — files removed from the source are also removed from the target
  (use `-NoDelete` to keep a copy-only/append behavior).
- If Google Drive can't be found it **aborts** rather than backing up to the Desktop
  (override with `-AllowDesktopFallback`).

## Manual use

```powershell
pwsh -File .\Mirror-GrandMA3Shows.ps1                 # most recent version -> Google Drive
pwsh -File .\Mirror-GrandMA3Shows.ps1 -SyncAllVersions
pwsh -File .\Mirror-GrandMA3Shows.ps1 -WhatIf        # dry run, changes nothing
pwsh -File .\Mirror-GrandMA3Shows.ps1 -NoDelete      # never delete from target
```

Key parameters: `-SourceRoot`, `-TargetRoot`, `-SyncAllVersions`, `-NoDelete`,
`-AllowDesktopFallback`, `-LogDir`, `-NoLog`, `-LogRetention`.
Exit codes: `0` = success, `1` = failure (details in the log).

## Scheduling on Windows

Run the installer once (in `pwsh`, as the user who is logged in with Google Drive):

```powershell
pwsh -File .\Register-Backup-Task.ps1                       # daily at 12:00 and 18:00
pwsh -File .\Register-Backup-Task.ps1 -At '07:30','19:00'   # custom times
pwsh -File .\Register-Backup-Task.ps1 -SyncAllVersions      # back up all versions
pwsh -File .\Register-Backup-Task.ps1 -Unregister           # remove the task
```

Then verify:

```powershell
Start-ScheduledTask   -TaskName 'grandMA3 Show Backup'      # run now
Get-ScheduledTaskInfo -TaskName 'grandMA3 Show Backup'      # LastTaskResult should be 0
```

### Why these settings (gotchas)

- **Runs only when the user is logged on, in the interactive session.** Google Drive
  mounts `My Drive` only inside the desktop session. A "run whether logged on or not"
  task runs in session 0 with no Drive mounted — the backup would fail / hit the abort
  guard. **This is the #1 thing to get right.** As a corollary, backups don't run while
  no one is logged in.
- **`pwsh.exe`, not `powershell.exe`** — the script needs PowerShell 7.
- **`-NoProfile -ExecutionPolicy Bypass -File`** — predictable startup, runs unsigned.
- **Not "highest privileges"** — writes go to the user's Drive; elevation can hide the
  user's drive mappings.
- **Start when available** — catches up after the PC was off/asleep at the trigger time.
- **No second instance** — a slow run won't overlap the next trigger.
- **Execution time limit (default 2h)** — a hung run is force-stopped.
- Keep the script in a **stable local path** (e.g. `C:\Scripts\`), not inside the Drive
  folder it writes to.

## Scheduling on macOS

There's no installer for macOS; use a `launchd` LaunchAgent (runs in the user session, so
Google Drive is mounted). Create `~/Library/LaunchAgents/de.icf.gma3-backup.plist` with a
`ProgramArguments` of `pwsh -NoProfile -File /path/to/Mirror-GrandMA3Shows.ps1` and a
`StartCalendarInterval`, then `launchctl load` it.

## Logs

Each run writes a transcript to `logs/backup-<timestamp>.log` next to the script
(override with `-LogDir`, disable with `-NoLog`). The newest 30 are kept
(`-LogRetention`). Check these first when a scheduled run didn't do what you expected.

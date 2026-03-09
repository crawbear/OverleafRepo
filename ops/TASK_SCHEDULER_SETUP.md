# Windows Task Scheduler backup setup

Use this to run nightly backups.

Windows build-in tool. 



## Backup task (daily)

1. Open Task Scheduler -> Create Task.
2. Name: `Overleaf Backup`.
3. Trigger: Daily at `02:00`.
4. Action:
	- Program/script: `powershell.exe`
	- Add arguments: `-ExecutionPolicy Bypass -File ".\scripts\backup.ps1"`
	- Start in: folder that contains `docker-compose.yml`

General tab settings:

- Select: `Run whether user is logged on or not`
- Optional: `Hidden` (to avoid visible windows)

Behavior:

- If the compose stack is down, backup exits quietly and does nothing.

Tip: In File Explorer, open your repo folder, then copy the path from the address bar.

Example setup:

- Start in: `D:\Projects\OverLeafSelf`
- Arguments (normal): `-ExecutionPolicy Bypass -File ".\scripts\backup.ps1"`

How path resolution works:

- Task Scheduler uses the `Start in` folder every run.
- Relative paths like `.\scripts\backup.ps1` are resolved from that folder.
- Running once manually from `OverLeafSelf` does not "save" that path for future runs unless `Start in` is set in the task.

## Recommended schedule

- Trigger: Daily
- Time: 02:00
- Run whether user is logged on or not
- Retry on failure: every 15 minutes, up to 3 times

## Easy toggle

- In Task Scheduler Library, right-click the task and choose `Disable` or `Enable`.
- This is the easiest on/off toggle for casual users.

## Retention

Add a separate scheduled task to delete old backups.

1. Create another task.
2. Name: `Overleaf Backup Prune`.
3. Trigger: Daily at `03:00` (after backup task).
4. Action:
	- Program/script: `powershell.exe`
	- Add arguments: `-ExecutionPolicy Bypass -File ".\scripts\prune-backups.ps1" -KeepDays 90`
	- Start in: folder that contains `docker-compose.yml`

Example retention action:

- Start in: `D:\Projects\OverLeafSelf`
- Arguments: `-ExecutionPolicy Bypass -File ".\scripts\prune-backups.ps1" -KeepDays 90`

General tab settings:

- Select: `Run whether user is logged on or not`
- Optional: `Hidden`

This keeps the last 90 days of backups and removes older files.

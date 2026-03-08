# Windows Task Scheduler backup setup

Use this to run nightly backups.

## Script command

Program/script:

`powershell.exe`

Arguments:

`-ExecutionPolicy Bypass -File "C:\Users\user\Documents\Workspaces VS\OverLeafSelf\scripts\backup.ps1"`

Start in:

`C:\Users\user\Documents\Workspaces VS\OverLeafSelf`

## Recommended schedule

- Trigger: Daily
- Time: 02:00
- Run whether user is logged on or not
- Retry on failure: every 15 minutes, up to 3 times

## Retention

Add a separate scheduled task to delete old backups if desired.

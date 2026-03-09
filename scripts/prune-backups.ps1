param(
    [int]$KeepDays = 90,
    [string]$BackupDir = ""
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($BackupDir)) {
    $BackupDir = Join-Path $ProjectRoot "backups"
}

if (-not (Test-Path $BackupDir)) {
    Write-Host "No backups directory found at: $BackupDir"
    exit 0
}

$cutoff = (Get-Date).AddDays(-1 * $KeepDays)
$oldFiles = Get-ChildItem $BackupDir -File | Where-Object { $_.LastWriteTime -lt $cutoff }

if (-not $oldFiles) {
    Write-Host "No backup files older than $KeepDays days."
    exit 0
}

$count = ($oldFiles | Measure-Object).Count
$oldFiles | Remove-Item -Force
Write-Host "Deleted $count old backup file(s) older than $KeepDays days from: $BackupDir"

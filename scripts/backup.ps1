param(
    [string]$BackupDir = ""
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($BackupDir)) {
    $BackupDir = Join-Path $ProjectRoot "backups"
}

if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir | Out-Null
}

$envFile = Join-Path $ProjectRoot ".env"
$projectName = "overleafself"
if (Test-Path $envFile) {
    $line = Get-Content $envFile | Where-Object { $_ -match '^COMPOSE_PROJECT_NAME=' } | Select-Object -First 1
    if ($line) {
        $projectName = ($line -split '=', 2)[1].Trim()
    }
}
$volumeName = "${projectName}_overleaf-data"

$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
Push-Location $ProjectRoot

try {
    $runningServices = @(docker compose ps --services --filter "status=running" 2>$null)

    if (-not $runningServices -or -not ($runningServices -contains "mongo")) {
        # Silent success path for scheduled tasks when stack is not running.
        exit 0
    }

    Write-Host "[2/3] Creating MongoDB logical backup..."
    $mongoArchive = Join-Path $BackupDir "mongo-$timestamp.archive.gz"
    docker compose exec -T mongo sh -lc "mongodump --archive --gzip" > $mongoArchive

    Write-Host "[3/3] Creating Overleaf data volume backup..."
    $volumeArchive = Join-Path $BackupDir "overleaf-data-$timestamp.tgz"
        docker run --rm -v "${volumeName}:/volume" -v "${BackupDir}:/backup" alpine sh -lc "tar czf /backup/overleaf-data-$timestamp.tgz -C /volume ."

    Write-Host "Backup complete:"
    Write-Host "- $mongoArchive"
    Write-Host "- $volumeArchive"
}
finally {
    Pop-Location
}

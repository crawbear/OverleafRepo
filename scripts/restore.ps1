param(
    [Parameter(Mandatory = $true)]
    [string]$Timestamp,
    [string]$BackupDir = ""
)

$ErrorActionPreference = "Stop"

$ProjectRoot = Split-Path $PSScriptRoot -Parent
if ([string]::IsNullOrWhiteSpace($BackupDir)) {
    $BackupDir = Join-Path $ProjectRoot "backups"
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

$mongoArchive = Join-Path $BackupDir "mongo-$Timestamp.archive.gz"
$volumeArchive = Join-Path $BackupDir "overleaf-data-$Timestamp.tgz"

if (-not (Test-Path $mongoArchive)) {
    throw "Mongo backup not found: $mongoArchive"
}
if (-not (Test-Path $volumeArchive)) {
    throw "Overleaf data backup not found: $volumeArchive"
}

Push-Location $ProjectRoot

try {
    Write-Host "[1/4] Stopping application services..."
    docker compose stop overleaf | Out-Null

    Write-Host "[2/4] Restoring overleaf-data volume..."
        docker run --rm -v "${volumeName}:/volume" -v "${BackupDir}:/backup" alpine sh -lc "rm -rf /volume/*; tar xzf /backup/overleaf-data-$Timestamp.tgz -C /volume"

    Write-Host "[3/4] Restoring MongoDB logical dump..."
    docker compose up -d mongo | Out-Null
        Start-Sleep -Seconds 3
        docker compose exec -T mongo sh -lc "mongorestore --archive --gzip --drop" < $mongoArchive

    Write-Host "[4/4] Starting full stack..."
    docker compose up -d

    Write-Host "Restore complete for timestamp: $Timestamp"
}
finally {
    Pop-Location
}

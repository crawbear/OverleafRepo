# OverLeafSelf (Self-hosted Overleaf Community)

This folder contains a local, self-hosted Overleaf Community stack using Docker.

## What is included

- `docker-compose.yml` for `overleaf`, `mongo`, and `redis`
- `.env` + `.env.example` for runtime settings
- `scripts/backup.ps1` and `scripts/restore.ps1` for backup/restore
- `backups/` folder for backup artifacts

## Prerequisites

- Docker Desktop (Windows)
- At least 8 GB RAM available to Docker

## First start

1. **Create your configuration file** (choose one method):
   
   **Option A - PowerShell terminal:**
   ```powershell
   Copy-Item .env.example .env
   ```
   
   **Option B - Windows Explorer:**
   - Right-click `.env.example`
   - Select "Copy"
   - Right-click in the same folder → "Paste"
   - Rename the copy from `.env.example - Copy` to `.env`

2. **Edit `.env`** (right-click → Open with Notepad) and change:
   - `OVERLEAF_ADMIN_PASSWORD=change-me-now` to a strong password
   - Optionally change `OVERLEAF_PORT` if 9100 is already in use

3. **Start services** (in PowerShell terminal):
   ```powershell
   docker compose up -d
   ```
4. Initialize Mongo replica set (one-time):
   ```powershell
   docker compose exec mongo mongosh --eval "rs.initiate({_id: 'overleaf', members:[{_id:0, host:'mongo:27017'}]})"
   ```
5. Restart app after replica set init (takes 1-2 minutes on first run):
   ```powershell
   docker compose restart overleaf
   ```
   Wait for migrations to complete:
   ```powershell
   docker compose logs -f overleaf
   ```
   Look for: `Finished migrations` and `Runit started`
6. Open:
   - http://localhost:9100

## Daily operations

- Start stack: `docker compose up -d`
- Stop stack: `docker compose down`
- Logs: `docker compose logs -f overleaf`

## Backup

Run:
```powershell
./scripts/backup.ps1
```

This creates two files in `backups/` with a shared timestamp:
- `mongo-<timestamp>.archive.gz`
- `overleaf-data-<timestamp>.tgz`

## Restore

Run:
```powershell
./scripts/restore.ps1 -Timestamp 20260308-120000
```

Use the timestamp from your backup filenames.

## Security notes

- Change `OVERLEAF_ADMIN_PASSWORD` in `.env` before exposing beyond localhost.
- Current config is local-only (`127.0.0.1` bind in `docker-compose.yml`).
- For public access, add a reverse proxy + HTTPS and set `OVERLEAF_SECURE_COOKIE=true`.

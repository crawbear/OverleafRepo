# OverLeafSelf (Self-hosted Overleaf Community)

This repository provides a Docker-based setup to run your own self-hosted Overleaf Community editor on your computer.

By default when setup, it runs locally only (`localhost`) and stores your projects in Docker volumes, so your files and account data persist between restarts. Compilation uses your own machine resources, so there are no compilation time limits. 



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
Projects persist between sessions during normal operations.

- Start stack:(safe, keeps your projects) `docker compose up -d`
- Stop stack:(projects still there) `docker compose down`
- Logs: `docker compose logs -f overleaf`

## Removal

- Delete saved data and containers: `docker compose down -v`
- Remove this stack including images: `docker compose down --rmi all -v`
- Complete removal: delete the OverLeafSelf folder after cleanup

Data persists between sessions in Docker volumes (`overleaf-data`, `mongo-data`, `redis-data`).

## Access model (who can connect)

- Current setup is local-only by default.
- Because the port is bound to `127.0.0.1`, only the computer running the editor can open Overleaf at `http://localhost:9100`.
- Multiple users are not enabled by default from other machines.

If you want LAN access, change the port binding in `docker-compose.yml` from:

`127.0.0.1:${OVERLEAF_PORT:-9100}:8080`

to:

`${OVERLEAF_PORT:-9100}:8080`

Then other devices can use `http://<your-pc-ip>:9100` on the same network.
(Run 'ipconfig' in PowerShell to check your private IP)

For internet/public access, use a reverse proxy with HTTPS, set secure cookie options, and harden account settings first.

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

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

1. Copy `.env.example` to `.env`:
   ```powershell
   Copy-Item .env.example .env
   ```
2. Edit `.env` and change `OVERLEAF_ADMIN_PASSWORD` to a strong password.
3. Start services:
   ```powershell
   docker compose up -d
   ```
4. Initialize Mongo replica set (one-time):
   ```powershell
   docker compose exec mongo mongosh --eval "rs.initiate({_id: 'overleaf', members:[{_id:0, host:'mongo:27017'}]})"
   ```
5. Restart app after replica set init:
   ```powershell
   docker compose restart overleaf
   ```
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

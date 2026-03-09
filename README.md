# OverLeafSelf (Self-hosted Overleaf Community)

This repository provides a Docker-based setup to run your own self-hosted Overleaf Community editor on your computer.

By default when setup, it runs locally only (`localhost`) and stores your projects in Docker volumes, so your files and account data persist between restarts. Compilation uses your own machine resources, so there are no compilation time limits. 

Provides significant reduced compilation times.



## What is included

- `docker-compose.yml` for `overleaf`, `mongo`, and `redis`
- `.env` + `.env.example` for runtime settings
- `scripts/seed-owner.js` auto-creates owner login from `.env` when containers start
- `scripts/backup.ps1` and `scripts/restore.ps1` for backup/restore
- `backups/` folder for backup artifacts

## Prerequisites

- Docker Desktop (Windows)
- At least 8 GB RAM available to Docker

## First start

1. Create `.env` (choose one):

   Option A - PowerShell:
   ```powershell
   Copy-Item .env.example .env
   ```

   Option B - Windows Explorer (manual):
   - Right-click `.env.example`
   - Click `Copy`
   - Right-click in the same folder and click `Paste`
   - Rename the copied file to `.env`
   - Or simply just rename `.env.example to .env`

2. Edit `.env` and set:
   - `OVERLEAF_ADMIN_EMAIL` to your real email
   - `OVERLEAF_ADMIN_PASSWORD` to your preferred password

3. Start services:
   ```powershell
   docker compose up -d
   ```

4. Initialize Mongo replica set (one-time):
   ```powershell
   docker compose exec mongo mongosh --eval "rs.initiate({_id: 'overleaf', members:[{_id:0, host:'mongo:27017'}]})"
   ```

5. Restart app services:
   ```powershell
   docker compose restart overleaf seed-owner
   ```

6. Verify owner seeding (recommended check):
   ```powershell
   docker compose exec mongo mongosh --quiet --eval "db.getSiblingDB('sharelatex').users.find({email:'your-email@example.com'},{email:1,holdingAccount:1,_id:0}).toArray()"
   ```
   If seeding worked, this returns your email with `holdingAccount: false`.

   Optional troubleshooting logs: (Might not run but it is ok)
   ```powershell
   docker compose logs seed-owner --tail 20
   ```
   Note: this can be empty if `seed-owner` exits quickly after success.

7. Open and login:
   - http://localhost:9100/login

Note: In this image, `/register` is intentionally a "contact admin" page.
Owner login is created automatically from `.env` by the `seed-owner` service.

## Daily operations
Projects persist between sessions during normal operations.

- Start stack:(safe, keeps your projects) `docker compose up -d`
- Stop stack:(projects still there) `docker compose down`
- Logs: `docker compose logs -f overleaf`

Data persists between sessions in Docker volumes (`overleaf-data`, `mongo-data`, `redis-data`).

## Removal

- Delete saved data and containers: `docker compose down -v`
- Remove this stack including images: `docker compose down --rmi all -v`
- Complete removal: delete the OverLeafSelf folder after cleanup steps above.


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

By default, backup runs only when the compose stack is already running.
If stack is down, it exits silently (useful for scheduled tasks).

This creates two files in `backups/` with a shared timestamp:
- `mongo-<timestamp>.archive.gz`
- `overleaf-data-<timestamp>.tgz`

## Restore

Ex:
Run:
```powershell
./scripts/restore.ps1 -Timestamp 20220308-120000
```

Use the timestamp from your backup filenames.

## Security notes

- Change `OVERLEAF_ADMIN_PASSWORD` in `.env` before exposing beyond localhost.
- Current config is local-only (`127.0.0.1` bind in `docker-compose.yml`).
- For public access, add a reverse proxy + HTTPS and set `OVERLEAF_SECURE_COOKIE=true`.

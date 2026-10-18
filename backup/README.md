# Backup & Restore

Per-machine backup scripts. Pull this repo to the target host, then run the matching script elevated.

## Linux
- `backup/ignition-backup.sh` (Fedora / OpenWeb UI) and `backup/guidance-backup.sh` (Ubuntu / PlinkCom).
- Run as root: `sudo ./backup/ignition-backup.sh`
- Creates a tar.gz of system dirs and pushes to blackbox `plinktern@172.16.21.5:/home/plinktern/backups/<machine>/`.

## Windows
- `backup/manifest-backup.ps1` (Windows Server 2019 / MariaDB) and `backup/assembly-backup.ps1` (Windows Server 2022 / Jenkins).
- Run from an elevated PowerShell.
- Creates a zip of system dirs (plus DB dump or Jenkins archive) and pushes via scp.exe; keeps local copy if scp.exe missing.

## Restore
- Linux: `restore/ignition-restore.sh` / `restore/guidance-restore.sh`. Default extracts to `/root/restore_<ts>` (safe, no overwrite). Use `--full` to extract over `/`. Pass extra args to extract only specific paths.
- Windows: `restore/manifest-restore.ps1` / `restore/assembly-restore.ps1`. Default extracts to `C:\.spool\restore\extracted` (safe). Use `-Full` to extract over `C:\`.
- Database: `restore/manifest-mariadb.ps1` (Manifest) restores the MariaDB dump.
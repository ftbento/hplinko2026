/scan -> /init -> /monitoring

# Scan
Continue running scan periodically. Each run writes a timestamped `scan-YYYYmmdd_HHMMSS.txt` (path also printed when it finishes), so you can diff runs.

Log location:
- Linux: `/.spool/` (root-only, `chmod 700`)
- Windows: `C:\.spool\` (hidden)

## Linux:
`sudo ./linux.sh`

## PowerShell (run from an *elevated* prompt for complete results)
`.\windows.ps1`

# Init
- 

CHECK FOR RED TEAM "presents" (/scan should help)

# Init (run after scan)
## Linux:
`sudo ./init/ignition-fedora.sh` (Fedora)
`sudo ./init/guidance-ubuntu.sh` (Ubuntu)

Note: passwords are hardcoded in init scripts, so delete `init/` after running them
`rm -rf ~/hplinko2026-main/init`

# Pull Repo

## Linux:
```bash
curl -sL https://github.com/ftbento/hplinko2026/archive/refs/heads/main.tar.gz | tar -xzC ~/
find ~/hplinko2026-main -name "*.sh" -exec chmod +x {} +
```

## PowerShell (do you see this bs)
```powershell
$ProgressPreference = 'SilentlyContinue'
$zip = Join-Path $env:TEMP 'hplinko2026.zip'
curl.exe -sL https://github.com/ftbento/hplinko2026/archive/refs/heads/main.zip -o $zip
Expand-Archive $zip -DestinationPath $env:USERPROFILE -Force
Remove-Item $zip
Get-ChildItem "$env:USERPROFILE\hplinko2026-main" -Recurse -Include *.ps1 | Unblock-File
```
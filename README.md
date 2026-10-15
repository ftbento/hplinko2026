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

CHECK FOR RED TEAM "presents" (/scan should help)

# Pull Repo
curl -sL https://github.com/ftbento/hplinko2026/archive/refs/heads/main.tar.gz | tar -xzC ~/
find ~/hplinko2026-main -name "*.sh" -exec chmod +x {} +
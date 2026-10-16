# hplinko2026

`/scan` -> `/init` -> `/monitoring`

## Pull repo

### Linux
```bash
curl -sL https://github.com/ftbento/hplinko2026/archive/refs/heads/main.tar.gz | tar -xzC ~/
find ~/hplinko2026-main -name "*.sh" -exec chmod +x {} +
```

### PowerShell (elevated)
```powershell
$ProgressPreference = 'SilentlyContinue'
$zip = Join-Path $env:TEMP 'hplinko2026.zip'
curl.exe -sL https://github.com/ftbento/hplinko2026/archive/refs/heads/main.zip -o $zip
Expand-Archive $zip -DestinationPath $env:USERPROFILE -Force
Remove-Item $zip
Get-ChildItem "$env:USERPROFILE\hplinko2026-main" -Recurse -Include *.ps1 | Unblock-File
```

## Scan

Continue running scan periodically. Output `scan-YYYYmmdd_HHMMSS.txt`, use for diff

Log location:
- Linux: `/.spool/` (root-only, `chmod 700`)
- Windows: `C:\.spool\` (hidden)

### Linux
`sudo ./scan/linux.sh`

### PowerShell (elevated for complete results)
`.\scan\windows.ps1`

CHECK FOR RED TEAM "presents" (/scan should help).

## Init

### Linux
- `sudo ./init/ignition-fedora.sh` (Fedora)
- `sudo ./init/guidance-ubuntu.sh` (Ubuntu)

### Windows
- `.\init\assembly-2022.ps1` (NOT FULLY IMPLEMENTED)
- `.\init\manifest-2019.ps1` (NOT FULLY IMPLEMENTED)

Passwords are hardcoded in the init scripts, so delete `init/` after running:

IF NEEDED
- `chattr +i /etc/passwd /etc/shadow /etc/ssh/sshd\_config`

## Monitoring

### Linux
- `./monitors.sh` opens two tabs (fedora + ubuntu).
- `./monitors.sh -k` closes the session.

`ranger`
- click r, then type `bash` or `sh` to run scripts directly.

### Windows
- Open stuff in `/monitoring/win`
- Good luck windows ppl
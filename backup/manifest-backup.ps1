# Manifest (Windows Server 2019 / MariaDB) backup. Run elevated.
param([string]$DbPassword = 'astral-prayer-loving')

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run from an elevated PowerShell."
    exit 1
}

$ts    = Get-Date -Format 'yyyyMMdd_HHmmss'
$local = 'C:\.spool\backups'
if (-not (Test-Path $local)) { New-Item -ItemType Directory -Path $local -Force | Out-Null }

# System archive
$sysArchive = "$local\manifest_sys_${ts}.zip"
Compress-Archive -Path 'C:\Users','C:\ProgramData' -DestinationPath $sysArchive -Force

# MariaDB dump
$mysqldump = 'mysqldump.exe'
if (-not (Get-Command $mysqldump -ErrorAction SilentlyContinue)) {
    $c = Get-ChildItem 'C:\Program Files\MariaDB*\bin\mysqldump.exe' -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c) { $mysqldump = $c.FullName } else { $mysqldump = $null }
}
$dumpFile = "$local\manifest_mariadb_${ts}.sql"
if ($mysqldump) {
    & $mysqldump --single-transaction --routines --events --all-databases --user=root "--password=$DbPassword" | Out-File -FilePath $dumpFile -Encoding utf8
} else {
    Write-Warning "mysqldump.exe not found; skipping DB dump."
}

# Push to blackbox if scp.exe exists
$scp = Get-Command scp.exe -ErrorAction SilentlyContinue
$ssh = Get-Command ssh.exe -ErrorAction SilentlyContinue
if ($scp -and $ssh) {
    & $ssh.Source 'plinktern@172.16.21.5' 'mkdir -p /home/plinktern/backups/manifest' 2>$null
    & $scp.Source $sysArchive 'plinktern@172.16.21.5:/home/plinktern/backups/manifest/' 2>$null
    if (Test-Path $dumpFile) { & $scp.Source $dumpFile 'plinktern@172.16.21.5:/home/plinktern/backups/manifest/' 2>$null }
} else {
    Write-Warning "scp.exe not found. Backup kept locally in $local."
}

Write-Host "Done. Local: $local"
# Restore MariaDB on Manifest from blackbox. Run elevated.
param([string]$DbPassword = 'astral-prayer-loving', [string]$DumpFile = '')

$Blackbox = 'plinktern@172.16.21.5'
$Dir = '/home/plinktern/backups/manifest'
$local = 'C:\.spool\restore'
if (-not (Test-Path $local)) { New-Item -ItemType Directory -Path $local -Force | Out-Null }

$ssh = Get-Command ssh.exe -ErrorAction SilentlyContinue
$scp = Get-Command scp.exe -ErrorAction SilentlyContinue
if (-not $ssh -or -not $scp) { Write-Error "ssh.exe/scp.exe not found."; exit 1 }

if (-not $DumpFile) {
    $list = & $ssh.Source $Blackbox "ls $Dir/mariadb_*.sql" 2>$null
    $names = @($list | ForEach-Object { ($_ -split '/')[-1].Trim() }) | Where-Object { $_ }
    if ($names.Count -eq 0) { Write-Error "No MariaDB dump found on blackbox."; exit 1 }
    $DumpFile = ($names | Sort-Object | Select-Object -Last 1)
}

& $scp.Source "$Blackbox`:$Dir/$DumpFile" "$local\$DumpFile" 2>$null
if (-not (Test-Path "$local\$DumpFile")) { Write-Error "Download failed."; exit 1 }

Write-Host "Downloaded: $local\$DumpFile"
Write-Host "Full restore command:"
Write-Host "  Get-Content '$local\$DumpFile' | mysql --user=root --password=$DbPassword"

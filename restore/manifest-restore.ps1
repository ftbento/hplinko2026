# Restore Manifest (Windows Server 2019) system files from blackbox. Run elevated.
$Blackbox = 'plinktern@172.16.21.5'
$Dir = '/home/plinktern/backups/manifest'
$local = 'C:\.spool\restore'
if (-not (Test-Path $local)) { New-Item -ItemType Directory -Path $local -Force | Out-Null }

$ssh = Get-Command ssh.exe -ErrorAction SilentlyContinue
$scp = Get-Command scp.exe -ErrorAction SilentlyContinue
if (-not $ssh -or -not $scp) { Write-Error "ssh.exe/scp.exe not found."; exit 1 }

$list = & $ssh.Source $Blackbox "ls $Dir/manifest_sys_*.zip" 2>$null
$names = @($list | ForEach-Object { ($_ -split '/')[-1].Trim() }) | Where-Object { $_ }
if ($names.Count -eq 0) { Write-Error "No system backup found on blackbox."; exit 1 }

$chosen = $names | Sort-Object | Select-Object -Last 1
& $scp.Source "$Blackbox`:$Dir/$chosen" "$local\$chosen" 2>$null
if (-not (Test-Path "$local\$chosen")) { Write-Error "Download failed."; exit 1 }

Write-Host "Downloaded: $local\$chosen"
Write-Host "Full restore command: Expand-Archive -Path '$local\$chosen' -DestinationPath 'C:\' -Force"

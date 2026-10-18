# Assembly (Windows Server 2022 / Jenkins) backup. Run elevated.
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Run from an elevated PowerShell."
    exit 1
}

$ts    = Get-Date -Format 'yyyyMMdd_HHmmss'
$local = 'C:\.spool\backups'
if (-not (Test-Path $local)) { New-Item -ItemType Directory -Path $local -Force | Out-Null }

# System archive
$sysArchive = "$local\assembly_sys_${ts}.zip"
Compress-Archive -Path 'C:\Users','C:\ProgramData' -DestinationPath $sysArchive -Force

# Jenkins archive
$jenkinsDirs = @()
if ($env:JENKINS_HOME -and (Test-Path $env:JENKINS_HOME)) { $jenkinsDirs += $env:JENKINS_HOME }
if (Test-Path 'C:\Program Files\Jenkins') { $jenkinsDirs += 'C:\Program Files\Jenkins' }
if (Test-Path 'C:\ProgramData\Jenkins') { $jenkinsDirs += 'C:\ProgramData\Jenkins' }

$jenkinsArchive = $null
if ($jenkinsDirs.Count -gt 0) {
    $jenkinsArchive = "$local\assembly_jenkins_${ts}.zip"
    Compress-Archive -Path $jenkinsDirs -DestinationPath $jenkinsArchive -Force
}

# Push to blackbox if scp.exe exists
$scp = Get-Command scp.exe -ErrorAction SilentlyContinue
$ssh = Get-Command ssh.exe -ErrorAction SilentlyContinue
if ($scp -and $ssh) {
    & $ssh.Source 'plinktern@172.16.21.5' 'mkdir -p /home/plinktern/backups/assembly' 2>$null
    & $scp.Source $sysArchive 'plinktern@172.16.21.5:/home/plinktern/backups/assembly/' 2>$null
    if ($jenkinsArchive) { & $scp.Source $jenkinsArchive 'plinktern@172.16.21.5:/home/plinktern/backups/assembly/' 2>$null }
} else {
    Write-Warning "scp.exe not found. Backup kept locally in $local."
}

Write-Host "Done. Local: $local"
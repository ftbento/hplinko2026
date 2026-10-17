# @bastigas
# Hardening for HPCC

# run Get-LocalUser BEFORE script
# Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass

$KeepUsers = @("jmoney", "plinktern", "Administrator")
$NewPassword = "divine-banged-stores"
$DbPassword = "astral-prayer-loving"

# 1. CHANGE USER PASSWORDS

Write-Host "Updating user passwords..."

$SecurePassword = ConvertTo-SecureString $NewPassword -AsPlainText -Force

foreach ($User in $KeepUsers) {
    if (Get-LocalUser -Name $User -ErrorAction SilentlyContinue) {
        Set-LocalUser -Name $User -Password $SecurePassword
        Write-Host "Password updated: $User"
    }
}

# 2. DELETE UNAUTHORIZED USERS

Write-Host "Removing unauthorized local users..."

$ProtectedSIDs = @(
    "S-1-5-18",
    "S-1-5-19",
    "S-1-5-20"
)

Get-LocalUser | ForEach-Object {
    $User = $_

    if (
        $User.Name -notin $KeepUsers -and
        $User.SID.Value -notin $ProtectedSIDs -and
        $User.SID.Value -notmatch "-(500|501|503|504)$"
    ) {
        Write-Host "Deleting user: $($User.Name)"
        Remove-LocalUser -Name $User.Name
    }
}

Write-Host "User management completed."

# mariadb/mysql
Write-Host "Hardening MariaDB/MySQL..." -ForegroundColor Green

# Locate mysql.exe (check PATH first, fallback to Program Files)
$mysqlCmd = (Get-Command mysql.exe -ErrorAction SilentlyContinue).Path
if (-not $mysqlCmd) {
    $mysqlCmd = (Get-ChildItem -Path "C:\Program Files\MariaDB*\bin\mysql.exe" -ErrorAction SilentlyContinue | Select-Object -First 1).FullName
}

if ($mysqlCmd) {
    & $mysqlCmd -u root -p"H00ves0nTheM00n" -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '$DbPassword';" 2>$null

    & $mysqlCmd --force -u root -p"$DbPassword" -e "
        ALTER USER 'root'@'localhost' IDENTIFIED BY '$DbPassword';
        ALTER USER 'jmoney'@'%' IDENTIFIED BY '$DbPassword';
        ALTER USER 'jmoney'@'localhost' IDENTIFIED BY '$DbPassword';
        ALTER USER 'plinktern'@'%' IDENTIFIED BY '$DbPassword';
        ALTER USER 'plinktern'@'localhost' IDENTIFIED BY '$DbPassword';
        DELETE FROM mysql.user WHERE User='';
        DELETE FROM mysql.user WHERE User='root' AND Host NOT IN ('localhost','127.0.0.1','::1');
        DROP DATABASE IF EXISTS test;
        DELETE FROM mysql.db WHERE Db='test' OR Db='test\_%';
        FLUSH PRIVILEGES;
    " 2>$null

    Write-Host "MariaDB/MySQL successfully hardened." -ForegroundColor Green
    Write-Host "Update scoreboard (MANIFEST-DB) jmoney password to: $DbPassword" -ForegroundColor Yellow
} else {
    Write-Warning "mysql.exe not found in PATH or C:\Program Files\MariaDB*\"
}
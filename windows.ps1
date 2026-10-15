$KeepUsers = @("jmoney", "plinktern")
$NewPassword = "NewSecurePasswordHere"

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
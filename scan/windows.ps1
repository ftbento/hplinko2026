# general information read only quick runs (output to file, diff comparison as competition goes on)
# Run from an ELEVATED PowerShell for complete results: .\windows.ps1
# AI adapted from linux.sh
# NOT VERIFIED (PLEASE VERIFY, AI GENERATED SCRIPT, NO HUMAN THOUGHT)
# - Verified 10-15 6:28PM, seems to work fine.

# Unassuming, hidden location for scan history
$ScanDir = "$env:SystemDrive\.spool"
New-Item -ItemType Directory -Force -Path $ScanDir | Out-Null
$item = Get-Item $ScanDir -Force
$item.Attributes = $item.Attributes -bor [System.IO.FileAttributes]::Hidden
$Log = Join-Path $ScanDir ('scan-' + (Get-Date -Format 'yyyyMMdd_HHmmss') + '.txt')

$elevated = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

# Run the read-only scan inside a scriptblock and capture every stream to a
# stable, diff-friendly file (fixed UTF-8 encoding, no console-width wrapping).
& {
    function Section($t) { Write-Output ""; Write-Output "------------- $t -----------" }

    Write-Output "Scan  $(Get-Date)"
    Write-Output "host: $env:COMPUTERNAME"
    Write-Output "elevated: $elevated"
    $os = Get-CimInstance Win32_OperatingSystem -ErrorAction SilentlyContinue
    Write-Output ("os: {0} {1} (build {2})" -f $os.Caption, $os.Version, $os.BuildNumber)
    Write-Output "last boot: $($os.LastBootUpTime)"

    Section "NETWORK"

    Write-Output "IP addresses"
    Get-NetIPAddress -ErrorAction SilentlyContinue |
        Sort-Object InterfaceAlias, IPAddress |
        Select-Object InterfaceAlias, AddressFamily, IPAddress, PrefixLength |
        Format-Table -AutoSize

    Write-Output "DNS servers"
    Get-DnsClientServerAddress -ErrorAction SilentlyContinue |
        Where-Object { $_.ServerAddresses } |
        Sort-Object InterfaceAlias |
        Select-Object InterfaceAlias, AddressFamily, ServerAddresses |
        Format-Table -AutoSize

    Write-Output "Routes"
    route print

    Write-Output "ARP cache"
    arp -a

    # Reuse process names when mapping ports to processes
    $procMap = @{}
    Get-Process -ErrorAction SilentlyContinue | ForEach-Object { $procMap[[int]$_.Id] = $_.ProcessName }

    Write-Output "Listening TCP"
    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Sort-Object LocalPort |
        Select-Object LocalAddress, LocalPort, @{n='Process';e={$procMap[[int]$_.OwningProcess]}}, OwningProcess |
        Format-Table -AutoSize

    Write-Output "Listening UDP"
    Get-NetUDPEndpoint -ErrorAction SilentlyContinue |
        Sort-Object LocalPort |
        Select-Object LocalAddress, LocalPort, @{n='Process';e={$procMap[[int]$_.OwningProcess]}}, OwningProcess |
        Format-Table -AutoSize

    Write-Output "Established connections"
    Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue |
        Sort-Object RemoteAddress, RemotePort |
        Select-Object LocalAddress, LocalPort, RemoteAddress, RemotePort, @{n='Process';e={$procMap[[int]$_.OwningProcess]}}, OwningProcess |
        Format-Table -AutoSize

    Write-Output "SMB shares"
    Get-SmbShare -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object Name, Path, Description |
        Format-Table -AutoSize

    Write-Output "SMB sessions"
    Get-SmbSession -ErrorAction SilentlyContinue |
        Sort-Object ClientUserName |
        Select-Object ClientComputerName, ClientUserName, NumOpens, Dialect |
        Format-Table -AutoSize

    Section "USERS"

    Write-Output "Local users"
    Get-LocalUser -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object Name, Enabled, LastLogon, PasswordRequired, PasswordLastSet |
        Format-Table -AutoSize

    Write-Output "Privileged group members"
    foreach ($g in 'Administrators', 'Remote Desktop Users', 'Backup Operators', 'Users') {
        Write-Output "== $g"
        Get-LocalGroupMember -Group $g -ErrorAction SilentlyContinue |
            Sort-Object Name |
            Select-Object -ExpandProperty Name
    }

    Write-Output "Logged-in sessions"
    if (Get-Command quser -ErrorAction SilentlyContinue) { quser } else { qwinsta }

    Section "PROCESS"

    Write-Output "Processes (oldest first)"
    Get-Process -ErrorAction SilentlyContinue |
        Sort-Object StartTime |
        Select-Object Id, ProcessName, StartTime, Path |
        Format-Table -AutoSize

    Write-Output "Startup commands"
    Get-CimInstance Win32_StartupCommand -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object Name, Command, Location, User |
        Format-Table -AutoSize

    Write-Output "Run / RunOnce registry keys"
    $runKeys = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run',
        'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
    )
    foreach ($k in $runKeys) {
        if (Test-Path $k) {
            Write-Output "==> $k"
            Get-ItemProperty -Path $k -ErrorAction SilentlyContinue |
                Select-Object * -ExcludeProperty PS* |
                Format-List
        }
    }

    Section "SERVICES"

    Write-Output "Services"
    Get-Service -ErrorAction SilentlyContinue |
        Sort-Object Name |
        Select-Object Status, Name, DisplayName |
        Format-Table -AutoSize

    Write-Output "Running service binaries"
    Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq 'Running' } |
        Sort-Object Name |
        Select-Object Name, StartMode, StartName, PathName |
        Format-Table -AutoSize

    Write-Output "Running services with paths outside C:\Windows"
    Get-CimInstance Win32_Service -ErrorAction SilentlyContinue |
        Where-Object { $_.State -eq 'Running' -and $_.PathName -notmatch '^"?[Cc]:\\Windows' } |
        Sort-Object Name |
        Select-Object Name, PathName |
        Format-Table -AutoSize

    Section "SCHEDULED TASKS"

    Write-Output "Enabled tasks"
    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.State -ne 'Disabled' } |
        Sort-Object TaskPath, TaskName |
        Select-Object TaskPath, TaskName, State |
        Format-Table -AutoSize

    Write-Output "Enabled task actions"
    Get-ScheduledTask -ErrorAction SilentlyContinue |
        Where-Object { $_.State -ne 'Disabled' } |
        Sort-Object TaskPath, TaskName |
        ForEach-Object {
            $t = $_
            foreach ($a in $t.Actions) {
                Write-Output ("{0}{1} -> {2} {3}" -f $t.TaskPath, $t.TaskName, $a.Execute, $a.Arguments)
            }
        }

    Section "FIREWALL"

    Write-Output "Profiles"
    Get-NetFirewallProfile -ErrorAction SilentlyContinue |
        Select-Object Name, Enabled, DefaultInboundAction, DefaultOutboundAction |
        Format-Table -AutoSize

    Write-Output "Enabled rules"
    Get-NetFirewallRule -ErrorAction SilentlyContinue |
        Where-Object { $_.Enabled -eq 'True' } |
        Sort-Object DisplayName |
        Select-Object DisplayName, Direction, Action, Profile |
        Format-Table -AutoSize

    Section "PATCHES / SOFTWARE"

    Write-Output "Installed hotfixes"
    Get-HotFix -ErrorAction SilentlyContinue |
        Sort-Object InstalledOn |
        Select-Object HotFixID, Description, InstalledOn |
        Format-Table -AutoSize

    Write-Output "Installed software"
    $uninstall = @(
        'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
        'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*'
    )
    Get-ItemProperty -Path $uninstall -ErrorAction SilentlyContinue |
        Where-Object { $_.DisplayName } |
        Sort-Object DisplayName |
        Select-Object DisplayName, DisplayVersion, Publisher, InstallDate |
        Format-Table -AutoSize

    Section "LOGS"

    Write-Output "Security logons (4624 success / 4625 failure, last 100)"
    Get-WinEvent -FilterHashtable @{LogName = 'Security'; Id = 4624, 4625 } -MaxEvents 100 -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, Id,
            @{n='User';e={$_.Properties[5].Value}},
            @{n='LogonType';e={$_.Properties[8].Value}},
            @{n='SourceIP';e={$_.Properties[18].Value}} |
        Format-Table -AutoSize

    Write-Output "RDP sessions (last 50)"
    Get-WinEvent -LogName 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational' -MaxEvents 50 -ErrorAction SilentlyContinue |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, Id, @{n='User';e={$_.Properties[1].Value}} |
        Format-Table -AutoSize

    Write-Output "Recent System errors/warnings"
    Get-WinEvent -LogName System -MaxEvents 50 -ErrorAction SilentlyContinue |
        Where-Object { $_.LevelDisplayName -in 'Error', 'Warning' } |
        Sort-Object TimeCreated |
        Select-Object TimeCreated, LevelDisplayName, Id, ProviderName |
        Format-Table -AutoSize

    Write-Output ""
    Write-Output "Scan complete at $(Get-Date). run diff on files"
} *>&1 | Out-File -FilePath $Log -Encoding utf8 -Width 4096

Write-Host "Scan saved to $Log"
if (-not $elevated) { Write-Host "NOTE: not elevated - some sections are incomplete. Run from an elevated PowerShell." }
Write-Host "Diff: Compare-Object (Get-Content <old>) (Get-Content <new>)"

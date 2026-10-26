# Common.ps1
# Shared helpers used by every script: config loading, logging,
# and a safe wrapper around VMware's vmrun.exe command-line tool.

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$script:ProjectRoot = Split-Path -Parent $PSScriptRoot
$script:Config = $null
$script:VmPasswords = @{}

function Get-LabConfig {
    # Reads config.json once and checks that vmrun.exe exists.
    if (-not $script:Config) {
        $path = Join-Path $script:ProjectRoot 'config.json'
        if (-not (Test-Path $path)) { throw "config.json not found at $path" }
        $script:Config = Get-Content $path -Raw | ConvertFrom-Json

        if (-not (Test-Path $script:Config.vmrunPath)) {
            $alternative = 'C:\Program Files\VMware\VMware Workstation\vmrun.exe'
            if (Test-Path $alternative) { $script:Config.vmrunPath = $alternative }
            else { throw "vmrun.exe not found. Set the correct vmrunPath in config.json." }
        }
    }
    return $script:Config
}

function Write-LabLog {
    # Writes a timestamped line to the console and to logs\vmware-lab-YYYYMMDD.log
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR')][string]$Level = 'INFO'
    )
    $cfg = Get-LabConfig
    $folder = Join-Path $script:ProjectRoot $cfg.logFolder
    if (-not (Test-Path $folder)) { New-Item $folder -ItemType Directory | Out-Null }

    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    Add-Content -Path (Join-Path $folder "vmware-lab-$(Get-Date -Format yyyyMMdd).log") -Value $line

    $colors = @{ INFO = 'Gray'; WARN = 'Yellow'; ERROR = 'Red' }
    Write-Host $line -ForegroundColor $colors[$Level]
}

function Get-LabVM {
    # Returns one VM from config.json by name, or all of them with -Name All.
    param([string]$Name = 'All')
    $cfg = Get-LabConfig
    if ($Name -eq 'All') { return $cfg.vms }

    $vm = $cfg.vms | Where-Object { $_.name -eq $Name }
    if (-not $vm) { throw "VM '$Name' is not in config.json. Known VMs: $($cfg.vms.name -join ', ')" }
    return $vm
}

function Invoke-Vmrun {
    # Runs: vmrun -T ws [-vp password] <Command> [vmx path] [arguments]
    # Throws a readable error if vmrun fails, unless -IgnoreError is used.
    param(
        [Parameter(Mandatory)][string]$Command,
        [string[]]$Arguments = @(),
        $VM,
        [switch]$IgnoreError
    )
    $cfg = Get-LabConfig
    $allArgs = @('-T', 'ws')

    $isEncrypted = $VM -and ($VM.PSObject.Properties.Name -contains 'encrypted') -and $VM.encrypted
    if ($isEncrypted) {
        if (-not $script:VmPasswords.ContainsKey($VM.name)) {
            $secure = Read-Host "Encryption password for $($VM.name)" -AsSecureString
            $script:VmPasswords[$VM.name] = [System.Net.NetworkCredential]::new('', $secure).Password
        }
        $allArgs += @('-vp', $script:VmPasswords[$VM.name])
    }

    $allArgs += $Command
    if ($VM) { $allArgs += $VM.vmxPath }
    $allArgs += $Arguments

    # Native tools can write to stderr; don't let that stop the script by itself.
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    $output = & $cfg.vmrunPath @allArgs 2>&1
    $exitCode = $LASTEXITCODE
    $ErrorActionPreference = $previous

    $text = ($output | Out-String).Trim()
    if ($exitCode -ne 0 -and -not $IgnoreError) {
        throw "vmrun $Command failed: $text"
    }
    return $text
}

function Get-RunningVmxPath {
    # vmrun list prints "Total running VMs: N" followed by one .vmx path per line.
    $text = Invoke-Vmrun -Command 'list'
    return @($text -split "`r?`n" | Select-Object -Skip 1 |
             Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
}

function Test-VMRunning {
    param([Parameter(Mandatory)]$VM)
    return (Get-RunningVmxPath) -contains $VM.vmxPath
}

function Get-VMSnapshotName {
    # vmrun listSnapshots prints "Total snapshots: N" followed by one name per line.
    param([Parameter(Mandatory)]$VM)
    $text = Invoke-Vmrun -Command 'listSnapshots' -VM $VM
    return @($text -split "`r?`n" | Select-Object -Skip 1 |
             Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
}

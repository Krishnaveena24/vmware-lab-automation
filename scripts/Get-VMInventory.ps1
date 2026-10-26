<#
.SYNOPSIS
    Reports the power state, IP address and snapshots of every lab VM,
    shows them as a table and exports a CSV to the reports folder.
.EXAMPLE
    .\scripts\Get-VMInventory.ps1
#>

. "$PSScriptRoot\Common.ps1"

$cfg = Get-LabConfig
$running = @(Get-RunningVmxPath)

$report = foreach ($vm in Get-LabVM) {
    $vmxFound = Test-Path $vm.vmxPath
    $isRunning = $running -contains $vm.vmxPath

    $snapshots = @()
    if ($vmxFound) { $snapshots = @(Get-VMSnapshotName -VM $vm) }

    # The guest IP is only available when the VM is on and VMware Tools is installed.
    $ip = 'n/a'
    if ($isRunning) {
        $result = Invoke-Vmrun -Command 'getGuestIPAddress' -VM $vm -IgnoreError
        if ($result -match '^\d{1,3}(\.\d{1,3}){3}$') { $ip = $result }
    }

    [pscustomobject]@{
        Name          = $vm.name
        VmxFound      = $vmxFound
        PowerState    = if ($isRunning) { 'Running' } else { 'Off' }
        IPAddress     = $ip
        SnapshotCount = $snapshots.Count
        Snapshots     = $snapshots -join '; '
    }
}

$report | Format-Table -AutoSize

$folder = Join-Path $ProjectRoot $cfg.reportFolder
if (-not (Test-Path $folder)) { New-Item $folder -ItemType Directory | Out-Null }
$file = Join-Path $folder "vm-inventory-$(Get-Date -Format yyyyMMdd-HHmm).csv"
$report | Export-Csv -Path $file -NoTypeInformation
Write-LabLog "Inventory of $(@($report).Count) VMs exported to $file"

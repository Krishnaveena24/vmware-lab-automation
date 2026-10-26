<#
.SYNOPSIS
    Starts, stops or restarts one lab VM or all of them, in the order listed in config.json.
.PARAMETER Action
    Start, Stop or Restart.
.PARAMETER Name
    A VM name from config.json, or All (default).
.PARAMETER Background
    Start the VM without opening a window (vmrun "nogui").
.PARAMETER Hard
    Power off / reset immediately instead of a clean guest shutdown.
    A clean shutdown needs VMware Tools inside the VM.
.EXAMPLE
    .\scripts\Invoke-VMPower.ps1 -Action Start -Name DC01
.EXAMPLE
    .\scripts\Invoke-VMPower.ps1 -Action Stop
#>
param(
    [Parameter(Mandatory)][ValidateSet('Start', 'Stop', 'Restart')][string]$Action,
    [string]$Name = 'All',
    [switch]$Background,
    [switch]$Hard
)

. "$PSScriptRoot\Common.ps1"

$windowMode = if ($Background) { 'nogui' } else { 'gui' }
$powerMode  = if ($Hard) { 'hard' } else { 'soft' }

foreach ($vm in Get-LabVM -Name $Name) {
    try {
        $isRunning = Test-VMRunning -VM $vm

        if ($Action -eq 'Start') {
            if ($isRunning) {
                Write-LabLog "$($vm.name) is already running" -Level WARN
            }
            else {
                Invoke-Vmrun -Command 'start' -VM $vm -Arguments $windowMode | Out-Null
                Write-LabLog "Started $($vm.name)"
            }
        }
        elseif ($Action -eq 'Stop') {
            if (-not $isRunning) {
                Write-LabLog "$($vm.name) is already off" -Level WARN
            }
            else {
                Invoke-Vmrun -Command 'stop' -VM $vm -Arguments $powerMode | Out-Null
                Write-LabLog "Stopped $($vm.name) ($powerMode)"
            }
        }
        else {
            if (-not $isRunning) {
                Write-LabLog "$($vm.name) is off, so it was not restarted" -Level WARN
            }
            else {
                Invoke-Vmrun -Command 'reset' -VM $vm -Arguments $powerMode | Out-Null
                Write-LabLog "Restarted $($vm.name) ($powerMode)"
            }
        }
    }
    catch {
        Write-LabLog "$($vm.name): $($_.Exception.Message)" -Level ERROR
    }
}

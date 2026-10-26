<#
.SYNOPSIS
    Creates a linked or full clone of a lab VM from one of its snapshots.
.DESCRIPTION
    A linked clone shares the parent's disk and is created in seconds.
    A full clone is an independent copy and takes longer.
    Clone a VM that is not encrypted (DC01, not CLIENT01), with the source powered off.
.EXAMPLE
    .\scripts\New-VMClone.ps1 -SourceName DC01 -SnapshotName "01-Clean-OS" -CloneName SRV01
#>
param(
    [Parameter(Mandatory)][string]$SourceName,
    [Parameter(Mandatory)][string]$SnapshotName,
    [Parameter(Mandatory)][ValidatePattern('^[A-Za-z0-9-]{1,15}$')][string]$CloneName,
    [ValidateSet('linked', 'full')][string]$Type = 'linked'
)

. "$PSScriptRoot\Common.ps1"

try {
    $vm = Get-LabVM -Name $SourceName

    if (@(Get-VMSnapshotName -VM $vm) -notcontains $SnapshotName) {
        throw "Snapshot '$SnapshotName' does not exist on $SourceName. Run Invoke-VMSnapshot.ps1 -Action List to see them."
    }
    if (Test-VMRunning -VM $vm) {
        Write-LabLog "$SourceName is running. Cloning works best with the source powered off." -Level WARN
    }

    # Put the clone next to the source VM's folder: ...\Virtual Machines\<CloneName>\<CloneName>.vmx
    $vmsFolder = Split-Path (Split-Path $vm.vmxPath -Parent) -Parent
    $destination = Join-Path $vmsFolder "$CloneName\$CloneName.vmx"
    if (Test-Path $destination) { throw "$destination already exists." }

    Invoke-Vmrun -Command 'clone' -VM $vm -Arguments @(
        $destination, $Type, "-snapshot=$SnapshotName", "-cloneName=$CloneName"
    ) | Out-Null

    Write-LabLog "Created $Type clone '$CloneName' from $SourceName ($SnapshotName) at $destination"
    Write-Host "Open it in VMware Workstation with File > Open > $destination" -ForegroundColor Green
    Write-Host "Before joining it to the domain, run sysprep inside it so it gets a unique identity." -ForegroundColor Yellow
}
catch {
    Write-LabLog $_.Exception.Message -Level ERROR
}

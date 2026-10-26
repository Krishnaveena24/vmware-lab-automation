<#
.SYNOPSIS
    Creates, lists, reverts, deletes or rotates VM snapshots.
.DESCRIPTION
    Rotate creates a snapshot named auto-YYYYMMDD-HHMMSS and deletes the oldest
    auto-* snapshots so only the newest -Keep remain. Manual snapshots are never touched.
    Revert and Delete ask for confirmation first.
.EXAMPLE
    .\scripts\Invoke-VMSnapshot.ps1 -Action Create -Name DC01 -SnapshotName "Before-GPO-Change"
.EXAMPLE
    .\scripts\Invoke-VMSnapshot.ps1 -Action List
.EXAMPLE
    .\scripts\Invoke-VMSnapshot.ps1 -Action Revert -Name DC01 -SnapshotName "Before-GPO-Change"
.EXAMPLE
    .\scripts\Invoke-VMSnapshot.ps1 -Action Rotate -Name DC01 -Keep 3
#>
[CmdletBinding(SupportsShouldProcess, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory)][ValidateSet('Create', 'List', 'Revert', 'Delete', 'Rotate')][string]$Action,
    [string]$Name = 'All',
    [string]$SnapshotName,
    [ValidateRange(1, 20)][int]$Keep = 3
)

. "$PSScriptRoot\Common.ps1"

if (($Action -in @('Create', 'Revert', 'Delete')) -and -not $SnapshotName) {
    throw "-SnapshotName is required for $Action."
}
if (($Action -in @('Revert', 'Delete')) -and $Name -eq 'All') {
    throw "$Action works on one VM at a time. Use -Name, for example -Name DC01."
}

foreach ($vm in Get-LabVM -Name $Name) {
    try {
        switch ($Action) {
            'List' {
                $snapshots = @(Get-VMSnapshotName -VM $vm)
                Write-Host "`n$($vm.name): $($snapshots.Count) snapshot(s)" -ForegroundColor Cyan
                $snapshots | ForEach-Object { Write-Host "  - $_" }
            }
            'Create' {
                Invoke-Vmrun -Command 'snapshot' -VM $vm -Arguments $SnapshotName | Out-Null
                Write-LabLog "Created snapshot '$SnapshotName' on $($vm.name)"
            }
            'Revert' {
                if (@(Get-VMSnapshotName -VM $vm) -notcontains $SnapshotName) {
                    throw "Snapshot '$SnapshotName' does not exist on $($vm.name)."
                }
                if ($PSCmdlet.ShouldProcess($vm.name, "Revert to snapshot '$SnapshotName' (current state is lost)")) {
                    Invoke-Vmrun -Command 'revertToSnapshot' -VM $vm -Arguments $SnapshotName | Out-Null
                    Write-LabLog "Reverted $($vm.name) to snapshot '$SnapshotName'"
                }
            }
            'Delete' {
                if (@(Get-VMSnapshotName -VM $vm) -notcontains $SnapshotName) {
                    throw "Snapshot '$SnapshotName' does not exist on $($vm.name)."
                }
                if ($PSCmdlet.ShouldProcess($vm.name, "Delete snapshot '$SnapshotName'")) {
                    Invoke-Vmrun -Command 'deleteSnapshot' -VM $vm -Arguments $SnapshotName | Out-Null
                    Write-LabLog "Deleted snapshot '$SnapshotName' from $($vm.name)"
                }
            }
            'Rotate' {
                $newName = "auto-$(Get-Date -Format yyyyMMdd-HHmmss)"
                Invoke-Vmrun -Command 'snapshot' -VM $vm -Arguments $newName | Out-Null
                Write-LabLog "Created snapshot '$newName' on $($vm.name)"

                # Timestamped names sort oldest first, so the extras are at the start.
                $autoSnapshots = @(Get-VMSnapshotName -VM $vm | Where-Object { $_ -like 'auto-*' } | Sort-Object)
                $extra = $autoSnapshots.Count - $Keep
                if ($extra -gt 0) {
                    foreach ($old in ($autoSnapshots | Select-Object -First $extra)) {
                        Invoke-Vmrun -Command 'deleteSnapshot' -VM $vm -Arguments $old | Out-Null
                        Write-LabLog "Rotation removed old snapshot '$old' from $($vm.name)"
                    }
                }
            }
        }
    }
    catch {
        Write-LabLog "$($vm.name): $($_.Exception.Message)" -Level ERROR
    }
}

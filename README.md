# VMware Lab Automation (PowerShell)

PowerShell scripts that automate everyday VMware tasks for a home lab running on
VMware Workstation Pro: inventory reports, power operations, snapshot management
with automatic rotation, and VM cloning. Every action is logged.

The scripts call **vmrun**, the command-line tool that ships with VMware Workstation.

## What it does

| Script | Purpose |
| --- | --- |
| `scripts/Get-VMInventory.ps1` | Shows each VM's power state, IP address and snapshots; exports a CSV report |
| `scripts/Invoke-VMPower.ps1` | Starts, stops or restarts one VM or all VMs in order |
| `scripts/Invoke-VMSnapshot.ps1` | Creates, lists, reverts and deletes snapshots; `Rotate` keeps only the newest N automatic snapshots |
| `scripts/New-VMClone.ps1` | Creates a linked or full clone from a snapshot |
| `scripts/Common.ps1` | Shared helpers: config, logging, safe vmrun wrapper with error handling |

## Requirements

- Windows 10 or 11 with **VMware Workstation Pro 17**
- **Windows PowerShell 5.1** (built into Windows) or PowerShell 7
- **VS Code** with the **PowerShell** extension (VS Code suggests it when you open this folder)
- At least one VM, such as DC01 from the home lab guide

## Setup

1. Unzip this folder, for example to `C:\Projects\vmware-lab-automation`.
2. In VS Code: **File > Open Folder** and pick that folder. Install the PowerShell extension when asked.
3. Open the terminal: **Terminal > New Terminal**. It should show `PS C:\Projects\vmware-lab-automation>`.
4. Allow local scripts and unblock the downloaded files (one time):

   ```powershell
   Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
   Get-ChildItem -Recurse | Unblock-File
   ```

5. Find your VM files: in VMware Workstation, right-click a VM > **Settings > Options > General**
   shows the **Working directory**. The `.vmx` file is in that folder.
6. Edit `config.json`: replace `YOUR-USERNAME`, check each `vmxPath`, and set
   `"encrypted": true` only for VMs you encrypted (the Windows 11 client with a TPM).
   In JSON, every backslash must be doubled: `C:\\Users\\...`.

## Usage

Run these from the VS Code terminal:

```powershell
# Inventory report (table on screen + CSV in reports\)
.\scripts\Get-VMInventory.ps1

# Power
.\scripts\Invoke-VMPower.ps1 -Action Start -Name DC01
.\scripts\Invoke-VMPower.ps1 -Action Start              # all VMs, in config order
.\scripts\Invoke-VMPower.ps1 -Action Stop -Name CLIENT01
.\scripts\Invoke-VMPower.ps1 -Action Stop -Hard         # immediate power off

# Snapshots
.\scripts\Invoke-VMSnapshot.ps1 -Action Create -Name DC01 -SnapshotName "Before-GPO-Change"
.\scripts\Invoke-VMSnapshot.ps1 -Action List
.\scripts\Invoke-VMSnapshot.ps1 -Action Revert -Name DC01 -SnapshotName "Before-GPO-Change"
.\scripts\Invoke-VMSnapshot.ps1 -Action Delete -Name DC01 -SnapshotName "Before-GPO-Change"
.\scripts\Invoke-VMSnapshot.ps1 -Action Rotate -Name DC01 -Keep 3

# Clone (source off, not encrypted)
.\scripts\New-VMClone.ps1 -SourceName DC01 -SnapshotName "01-Clean-OS" -CloneName SRV01
```

Get help for any script: `Get-Help .\scripts\Invoke-VMSnapshot.ps1 -Full`

Logs are written to `logs\vmware-lab-YYYYMMDD.log`.

## Notes

- A clean shutdown (`-Action Stop` without `-Hard`) and the IP address in the inventory need **VMware Tools** inside the VM.
- Encrypted VMs prompt once for their encryption password; it is kept in memory only for that run.
- Snapshots are for quick rollback before a change, not a backup. Keep only a few, and delete old ones.

## How this maps to vSphere / vCenter (PowerCLI)

In a company, the same tasks run against vCenter using VMware PowerCLI:

| This project (vmrun) | vSphere with PowerCLI |
| --- | --- |
| `vmrun list` | `Get-VM \| Where-Object PowerState -eq 'PoweredOn'` |
| `vmrun start` / `stop soft` | `Start-VM` / `Shutdown-VMGuest` |
| `vmrun snapshot` | `New-Snapshot -VM DC01 -Name "Before-Change"` |
| `vmrun listSnapshots` | `Get-Snapshot -VM DC01` |
| `vmrun revertToSnapshot` | `Set-VM -VM DC01 -Snapshot "Before-Change"` |
| `vmrun deleteSnapshot` | `Remove-Snapshot` |
| `vmrun clone ... linked` | `New-VM -VM DC01 -LinkedClone -ReferenceSnapshot ...` |
| `vmrun getGuestIPAddress` | `(Get-VM DC01).Guest.IPAddress` |

## Folder structure

```
vmware-lab-automation/
├── config.json          # VM names, .vmx paths, vmrun location
├── README.md
├── .gitignore           # keeps logs and reports out of Git
├── .vscode/
│   └── extensions.json  # recommends the PowerShell extension
└── scripts/
    ├── Common.ps1
    ├── Get-VMInventory.ps1
    ├── Invoke-VMPower.ps1
    ├── Invoke-VMSnapshot.ps1
    └── New-VMClone.ps1
```

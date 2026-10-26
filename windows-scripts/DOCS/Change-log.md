# Change Log – KVLab (kvlab.local)

Every change followed the same process: record it, assess the risk, plan the rollback
(VM snapshot or reverse command), make the change, verify, and record the result.

| ID | Date | Change | Reason | Risk | Rollback plan | Result |
| --- | --- | --- | --- | --- | --- | --- |
| CHG-001 | 2026-10-26 | Install VMware Workstation Pro; set VMnet8 (NAT) to 192.168.50.0/24 | Isolated lab network with internet access | Low | Restore VMnet8 defaults in Virtual Network Editor | Success |
| CHG-002 | 2026-10-26 | Create DC01 VM; install Windows Server 2022 and VMware Tools | Host for domain services | Low | Delete VM | Success |
| CHG-003 | 2026-10-26 | DC01: static IP 192.168.50.10, DNS 127.0.0.1, rename to DC01 | Domain controllers need a fixed address | Medium | Re-enable DHCP; rename back | Success |
| CHG-004 | 2026-10-26 | Install AD DS and promote DC01 to new forest kvlab.local with DNS | Central identity and name resolution | High | Revert to snapshot 02-Before-ADDS | Success – dcdiag SystemLog/DFSREvent warnings traced to an earlier unclean shutdown; SYSVOL/NETLOGON shared, core tests passed |
| CHG-005 | 2026-10-26 | DNS: reverse zone 192.168.50.0/24, forwarder 8.8.8.8, A record client01, CNAME files | Name and reverse resolution; internet lookups | Low | Remove the zone and records | Success |
| CHG-006 | 2026-10-26 | Create OU structure, IT-Team/HR-Team groups, 10 users from CSV (New-LabUsers.ps1), plus user veena | Organised, repeatable user provisioning | Medium | Revert to snapshot 03-Before-Users, or Remove-ADUser | Success |
| CHG-007 | 2026-10-26 | Domain password policy: min 12 chars, complexity, 90-day expiry; lockout after 5 attempts for 15 min | Security baseline | Medium | Restore previous values with Set-ADDefaultDomainPasswordPolicy | Success – lockout verified |
| CHG-008 | 2026-10-26 | Create share \\dc01\IT with share and NTFS permissions for IT-Team | Team file storage | Low | Remove-SmbShare; delete folder | Success |
| CHG-009 | 2026-10-26 | GPO HR-Restrict-ControlPanel linked to Users OU, security-filtered to HR-Team | Restrict HR desktop settings | Medium | Unlink or delete the GPO | Success – verified with gpresult |
| CHG-010 | 2026-10-26 | GPO IT-Map-Drive-I: I: drive to \\dc01\IT with item-level targeting to IT-Team | Automatic drive mapping for IT | Low | Unlink or delete the GPO | Success – verified as user veena |
| CHG-011 | 2026-10-26 | Build CLIENT01 (Windows Server 2022 member), static IP 192.168.50.20, join kvlab.local, move to KVLab/Computers | Test machine for domain logins and GPOs | Medium | Remove from domain; delete VM | Success – first install used wrong ISO, corrected |
| CHG-012 | 2026-10-26 | Admin scripts (inactive users, disk report, DC health) and scheduled task "Daily Disk Report" | Automate routine checks | Low | Unregister-ScheduledTask; delete scripts | Success |
| CHG-013 | 2026-10-26 | Add 20 GB backup disk (E:), install Windows Server Backup, run system state and file backups | Recoverability of AD and lab data | Medium | Remove the backup disk | Success |
| CHG-014 | 2026-10-26 | Enable AD Recycle Bin | Fast recovery of deleted AD objects | Medium (cannot be disabled) | None – permanent by design | Success – deleted user restored with group membership |

## Issues and lessons learned

- **Host disk full during a snapshot:** running-VM snapshots store memory (about 2 GB each). Fixed by deleting old snapshots and taking new ones with the VM powered off.
- **Wrong ISO attached to CLIENT01:** caught at the setup screen and corrected before install.
- **Unclean shutdown flagged by dcdiag:** confirmed as historical, not an active fault; switched to clean guest shutdowns only.
- **Running AD commands on the wrong machine:** added a habit of checking `hostname` before every change.
# Lists users with no logon in 30 days; add -Apply to actually disable them
param([int]$Days = 30, [switch]$Apply)
$ou = "OU=Users,OU=KVLab,DC=kvlab,DC=local"
$stale = Search-ADAccount -AccountInactive -TimeSpan "$Days.00:00:00" -UsersOnly -SearchBase $ou |
         Where-Object Enabled
$stale | Select-Object Name, SamAccountName, LastLogonDate |
         Export-Csv "C:\Lab\Reports\inactive-$(Get-Date -f yyyyMMdd).csv" -NoTypeInformation
if ($Apply) { $stale | Disable-ADAccount; "Disabled $($stale.Count) accounts" }
else        { "Found $($stale.Count) inactive accounts (dry run)" }
notepad C:\Lab\Scripts\Disable-InactiveUsers.ps1
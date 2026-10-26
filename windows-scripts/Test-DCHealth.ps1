# Checks the core AD services and DNS resolution
$services = "NTDS","DNS","Netlogon","Kdc","W32Time"
Get-Service $services | Select-Object Name, Status
if (Resolve-DnsName dc01.kvlab.local -ErrorAction SilentlyContinue) { "DNS: OK" } else { "DNS: FAILED" }
notepad C:\Lab\Scripts\Test.DCHealth.ps1
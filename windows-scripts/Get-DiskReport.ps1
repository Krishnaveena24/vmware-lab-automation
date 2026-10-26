# Reports free space on each fixed disk and flags anything under 20%
Get-CimInstance Win32_LogicalDisk -Filter "DriveType=3" | ForEach-Object {
  $freePct = [math]::Round($_.FreeSpace / $_.Size * 100, 1)
  [pscustomobject]@{
    Server  = $env:COMPUTERNAME
    Drive   = $_.DeviceID
    SizeGB  = [math]::Round($_.Size / 1GB, 1)
    FreeGB  = [math]::Round($_.FreeSpace / 1GB, 1)
    FreePct = $freePct
    Status  = if ($freePct -lt 20) { "WARNING" } else { "OK" }
  }
} | Export-Csv "C:\Lab\Reports\disk-$(Get-Date -f yyyyMMdd).csv" -NoTypeInformation
notepad C:\Lab\Scripts\Get-DiskReport.ps1

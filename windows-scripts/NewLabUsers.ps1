# Creates AD users from a CSV and adds each to their department group
$ou   = "OU=Users,OU=KVLab,DC=kvlab,DC=local"
$pass = ConvertTo-SecureString "Welcome@2026!" -AsPlainText -Force

Import-Csv "C:\Lab\users.csv" | ForEach-Object {
  $name = "$($_.FirstName) $($_.LastName)"
  if (Get-ADUser -Filter "SamAccountName -eq '$($_.Username)'") {
    Write-Host "Skipped (exists): $($_.Username)" -ForegroundColor Yellow
    return
  }
  New-ADUser -Name $name -GivenName $_.FirstName -Surname $_.LastName `
    -SamAccountName $_.Username -UserPrincipalName "$($_.Username)@kvlab.local" `
    -Department $_.Department -Path $ou -AccountPassword $pass `
    -Enabled $true -ChangePasswordAtLogon $true
  Add-ADGroupMember -Identity "$($_.Department)-Team" -Members $_.Username
  Write-Host "Created: $($_.Username)" -ForegroundColor Green
}
notepad C:\Lab\Scripts\NewLabUsers.ps1
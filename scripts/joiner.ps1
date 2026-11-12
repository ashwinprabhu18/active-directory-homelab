# joiner.ps1 - create new starters from an HR CSV
# Phase 3 of active-directory-homelab

$csv = "C:\LabScripts\new-starters.csv"
$ou  = "OU=LAB-Users,DC=lab,DC=local"

# Ask for a temporary passwd 
$temp = Read-Host "Temporary password for new starters" -AsSecureString

Import-Csv $csv | ForEach-Object {

    # Skip anyone who already exists
    if (Get-ADUser -Filter "SamAccountName -eq '$($_.SamAccountName)'") {
        Write-Warning "$($_.SamAccountName) already exists - skipped"
        return
    }

    # Create the account
    New-ADUser -Name "$($_.FirstName) $($_.LastName)" `
        -GivenName $_.FirstName `
        -Surname $_.LastName `
        -SamAccountName $_.SamAccountName `
        -UserPrincipalName "$($_.SamAccountName)@lab.local" `
        -Department $_.Department `
        -Title $_.Title `
        -Path $ou `
        -AccountPassword $temp `
        -ChangePasswordAtLogon $true `
        -Enabled $true

    # Add them to their department group
    Add-ADGroupMember -Identity $_.Department -Members $_.SamAccountName

    Write-Host "Created $($_.SamAccountName) -> $($_.Department)" -ForegroundColor Green
}
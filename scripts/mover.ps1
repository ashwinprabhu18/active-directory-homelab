# mover.ps1 - move a user to a new department and swap their group access
# Phase 3 of active-directory-homelab

param(
    [Parameter(Mandatory)] [string]$User,
    [Parameter(Mandatory)] [string]$NewDepartment,
    [Parameter(Mandatory)] [string]$NewTitle
)

# Lookup the user and remember their current department
$account = Get-ADUser $User -Properties Department, Title
$oldDepartment = $account.Department

# Stop if the new department has no group
if (-not (Get-ADGroup -Filter "Name -eq '$NewDepartment'")) {
    Write-Warning "No group called $NewDepartment, nothing changed"
    return
}

# Update department and title
Set-ADUser $User -Department $NewDepartment -Title $NewTitle

# Swap access: out of the old department group, into the new one
if ($oldDepartment -and (Get-ADGroup -Filter "Name -eq '$oldDepartment'")) {
    Remove-ADGroupMember -Identity $oldDepartment -Members $User -Confirm:$false
}
Add-ADGroupMember -Identity $NewDepartment -Members $User

Write-Host "Moved $User from $oldDepartment to $NewDepartment ($NewTitle)" -ForegroundColor Green
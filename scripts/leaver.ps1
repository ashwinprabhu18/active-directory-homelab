# leaver.ps1 - offboard a user: disable, remove all groups, record why, move to LAB-Disabled
# Phase 3 of active-directory-homelab

param(
    [Parameter(Mandatory)] [string]$User,
    [Parameter(Mandatory)] [string]$Reason
)

$disabledOU = "OU=LAB-Disabled,DC=lab,DC=local"
$account = Get-ADUser $User -Properties MemberOf

# Disable first: cuts access straight away
Disable-ADAccount $User

# Remove every group they belong to (read from AD, nothing typed by hand)
foreach ($group in $account.MemberOf) {
    Remove-ADGroupMember -Identity $group -Members $User -Confirm:$false
}

# Record when and why
$today = Get-Date -Format "dd/MM/yyyy"
Set-ADUser $User -Description "Leaver $today`: $Reason. Disabled and groups removed by helpdesk."

# Move to the Disabled OU
Get-ADUser $User | Move-ADObject -TargetPath $disabledOU

Write-Host "Offboarded $User ($($account.MemberOf.Count) groups removed)" -ForegroundColor Green
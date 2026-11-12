# Active Directory Homelab

I built an Active Directory domain on VMware to practice everyday IT administration and later use it as an attack surface to practice Active Directory attacks and how to defend against them. 

## Lab setup
- DC01: Windows Server 2022, 4 GB RAM, 2 CPU, VMware NAT
- Domain: lab.local (NetBIOS: LAB), DC01 at 172.16.106.10

## Progress
- [x] Phase 1: Domain controller and DNS
- [x] Phase 2: OUs, users and groups (Spider-Man themed)
- [ ] Phase 3: PowerShell user lifecycle automation (joiner done; mover and leaver next)
- [ ] Phase 4: Join a Windows 11 client
- [ ] Phase 5: Group Policy
- [ ] Phase 6: Attack practice for PNPT


## Phase 1: Domain controller and DNS

I installed Windows Server 2022 in VMware Workstation (4 GB RAM, 2 CPUs, 60 GB disk, NAT network) and promoted it to the first domain controller of a new forest, `lab.local`.

DC01 has a static IP (172.16.106.10) because clients need a fixed address to find the domain controller. Its DNS server is set to 127.0.0.1, so the DC answers its own DNS queries. Active Directory depends on DNS: computers find the domain controller through DNS records, so if DNS is wrong, logons and domain joins fail.

To check it worked, I logged in as `LAB\Administrator`, ran `Get-ADDomain`, and tested name resolution. `lab.local` resolves to the DC, and internet names like `google.com` still resolve.

![VM settings](screenshots/01-vm-settings.png)
![IP configuration](screenshots/02-ipconfig.png)
![Server Manager with AD DS and DNS](screenshots/03-server-manager.png)
![Domain login](screenshots/04-domain-login.png)
![Get-ADDomain](screenshots/05-get-addomain.png)
![Internal DNS](screenshots/06-dns.png)
![External DNS](screenshots/06b-dns-internet.png)

## Phase 2: OUs, users and groups

I created three OUs (LAB-Users, LAB-Computers and LAB-Groups) instead of using the default Users and Computers containers. Default containers can't have Group Policy linked to them, so keeping objects in OUs makes later phases possible.

I added five users (Peter Parker, Miles Morales, Mary Jane Watson, J. Jonah Jameson and Ned Leeds) and a security group, IT-Support, with Ned as a member. Permissions are given to groups, not to individual people.

![Users in Active Directory Users and Computers](screenshots/07-aduc-users.png)
![IT-Support group members](screenshots/08-group.png)

## Phase 3: PowerShell user lifecycle (joiner, mover, leaver)

On a service desk, the most common identity tickets are new starters, people changing roles, and leavers. In this phase I'm doing all three with PowerShell instead of clicking through the GUI.

### Joiner

HR sends a CSV of new starters ([new-starters.csv](scripts/new-starters.csv)). Before writing any script, I created the Sales and Finance groups and made one user, Gwen Stacy, by hand to learn each command.

That first attempt went wrong. I pressed Enter halfway through `New-ADUser`, so Gwen was created in the default Users container, with no department and no password, which means AD left her disabled. I fixed her the way a helpdesk would: `Set-ADUser` for department and title, `Move-ADObject` into LAB-Users, `Set-ADAccountPassword -Reset` with a change at next logon, and `Enable-ADAccount`.

Then I wrote [joiner.ps1](scripts/joiner.ps1). For each row in the CSV it:
- skips the user if the account already exists, so the script is safe to run again
- creates the account in LAB-Users with the department and title from the CSV
- sets a temporary password that is typed in when the script runs (never stored in the script) and must be changed at first logon
- adds the user to their department group

The first run had a bug: a broken line continuation (backtick) on `-Path` split the command in two. The users were created without passwords, but the script still printed "Created" for each one. I reverted DC01 to the snapshot I took before running it, fixed the line, and ran it again cleanly. After that I checked the users and group memberships in AD instead of trusting the script's own output.

![CSV of new starters](screenshots/phase3-03-new-starters-csv.png)
![CSV import check](screenshots/phase3-04b-csv-import-check.png)
![Department groups created](screenshots/phase3-05-department-groups-created.png)
![Gwen created in the wrong container](screenshots/phase3-06a-gstacy-wrong-container.png)
![Gwen fixed](screenshots/phase3-06b-gstacy-fixed.png)
![Gwen added to IT-Support](screenshots/phase3-07-gstacy-added-to-it-support.png)
![Joiner script bug](screenshots/phase3-08x-joiner-backtick-bug.png)
![Joiner script clean run](screenshots/phase3-08-joiner-script-run.png)
![Users verified](screenshots/phase3-09a-verify-users-and-groups.png)
![Group membership verified](screenshots/phase3-09b-verify-group-membership.png)

### Mover and leaver

Next: move Harry Osborn from Sales to Finance (swap his group, not just his department label), and offboard Norman Osborn (disable, remove groups, move to a Disabled OU).


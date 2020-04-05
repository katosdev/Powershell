
<# 
.NOTES 
=========================================================================== 
Created by Philip Marsh for use at JMW Solicitors LLP 
Tool version 0.1.0
=========================================================================== 
.DESCRIPTION 
This script provides an automated off-boarding method for staff leaving 
the company. 

Leavers process:
1) Take a PST Export
2) Disable OWA / Exchange Active Sync
3) Disabled Outlook Online
4) Hide from Address Book
5) Backup AD Groups
6) Remove all groups, add deny all access
7) Move to Disabled users -> {YEAR} 
8) Reset password
9) Remove VPN Credentials
10) Collect laptop / mobile
11) Call Divert
12) Email divert  
#> 
  
# Import-Module ActiveDirectory 
write-host "Importing Active Directory PowerShell Commandlets" 
import-module ActiveDirectory
  
# Retrieve AD Details 
$ADDetails = Get-ADDomain 
$Domain = $ADDetails.DNSRoot 
Clear-Host 
  
# Get Variables 
$DisabledDate = Get-Date 
$LeaveDate = Get-Date -Format "dddd dd MMMM yyyy" 
$DisabledBy = Get-ADUser "$env:username" -properties Mail 
$DisabledByEmail = $DisabledBy.Mail 
  
# Prompt for AD Username 
$Employee = Read-Host "Employee Username" 
$EmployeeDetails = Get-ADUser $Employee -properties * 
If ($EmployeeDetails.Manager -ne $null) 
{ 
$Manager = Get-ADUser $EmployeeDetails.Manager -Properties Mail 
} 


# Export PST To JMW-Backup-Repo  
write-host "Exporting PST file to Backup Repo" 
$ExchangeSession = New-PSSession -ConfigurationName Microsoft.Exchange -ConnectionUri http://JMW-EXCH11/PowerShell
Import-PSSession $ExchangeSession
New-MailboxExportRequest -Mailbox $Employee -FilePath \\jmw-fs01\backup_repo_01$\$Employee\Mailbox.pst


Clear-Host 
  
# Prompt for confirmation 
write-host " ******************************** CONFIRM USER DISABLE REQUEST ******************************** " 
write-host " " 
write-host -ForegroundColor Yellow "Please review the Employee details below to ensure you are disabling the correct user account." 
$EmployeeDetails | fl Name, Title, Company, @{ Expression = { $_.mail }; Label = "Email Address" }, @{Expression = { $_.Created }; Label = "Employment Started"} 
  
$choice = " " 
while ($choice -notmatch "[y|n]") 
{ 
$choice = read-host "Do you want to continue? (Y/N)" 
} 

# Actions 
if ($choice -eq "y") 
{ 
Clear-Host 

write-host " ******************************** DISABLING USER ACCOUNT ******************************** " 
write-host " " 
# Set Disable Date for Audit purposes:
write-host "Step1. Modifying user description for audit purposes" -ForegroundColor Yellow 
Set-ADUser $Employee -Description "Disabled on $DisabledDate" 
# Disable user account
write-host "Step2. Disabling $Employee Active Directory Account." -ForegroundColor Yellow 
Disable-ADAccount $Employee 
# Backup Group Membership, so that this can be re-imported if required
write-host "Step 3, Taking backup of $Employee group membership"
New-Item -Path "\\jmw-fs01\backup_repo_01$" -Name $Employee -ItemType Directory
Get-ADPrincipalGroupMembership $Employee | select -expand name | Out-File "\\jmw-fs01\backup_repo_01$\$Employee\GroupMembershipBackup.csv"
# Remove all AD Groups
Get-AdPrincipalGroupMembership -Identity $Employee | Where-Object -Property Name -Ne -Value 'Domain Users' | Remove-AdGroupMember -Members $Employee
# Add to Deny all Access
Add-ADGroupMember -Identity "Deny All Access" -Members $Employee
# Move to Disabled Users OU
write-host "Step3. Moving $Employee to the Disabled User Accounts OU." -ForegroundColor Yellow 
write-host " " 
Get-ADUser $Employee | Move-ADObject -TargetPath "OU=$((Get-Date).year),OU=Disabled Accounts,DC=JMW,DC=NET"
# Disable OWA, ActiveSync and Disable Outlook Web
Write-Host "Step 5. Disabling OWA and ActiveSync access for $User" -ForegroundColor Yellow 
Set-CasMailbox -Identity $EmployeeDetails.mail -OWAEnabled $false -ActiveSyncEnabled $false -HiddenFromAddressListsEnabled $true
# Move U Drive to Backup
# Prompt for AD Username 
$UDrive = Read-Host "Employee Full name" 
Move-Item -Path "\\vmjmwdatastore\users\$UDrive" -Destination "\\jmw-fs01\backup_repo_01$\$Employee\U Drive\$UDrive" -force
# Move Citrix Profile to Backup
Move-Item -Path "\\jmw-fs01\ctxupm$\$employee" -Destination "\\jmw-fs01\backup_repo_01$\$Employee\CitrixProfile" -force
}


# Else cancel operation

else{ 

write-host " " 

write-host "Employee disable request cancelled" -ForegroundColor Yellow 
}

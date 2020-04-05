<# 
.SYNOPSIS 
Get Server Information 
.DESCRIPTION 
This script will get the CPU specifications, memory usage statistics, and OS configuration of any Server or Computer listed in Serverlist.txt. 
.NOTES   
The script will execute the commands on multiple machines sequentially using non-concurrent sessions. This will process all servers from Serverlist.txt in the listed order. 
The info will be exported to a csv format. 
Requires: Serverlist.txt must be created in the same folder where the script is. 
File Name  : get-server-info.ps1 
Author: Nikolay Petkov 
http://power-shell.com/ 
#> 
#Get the server list 
$servers = Get-Content .\Serverlist.txt 
#Run the commands for each server in the list 
Foreach ($s in $servers) 
{   
$CPUInfo = Get-WmiObject Win32_Processor -ComputerName $s #Get CPU Information 
$OSInfo = Get-WmiObject Win32_OperatingSystem -ComputerName $s #Get OS Information 
#Get Memory Information. The data will be shown in a table as MB, rounded to the nearest second decimal. 
$OSTotalVirtualMemory = [math]::round($OSInfo.TotalVirtualMemorySize / 1MB, 2) 
$OSTotalVisibleMemory = [math]::round(($OSInfo.TotalVisibleMemorySize  / 1MB), 2) 
$PhysicalMemory = Get-WmiObject CIM_PhysicalMemory -ComputerName $s | Measure-Object -Property capacity -sum | % {[math]::round(($_.sum / 1GB),2)} 
$infoObject = New-Object PSObject 
#The following add data to the infoObjects. 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "ServerName" -value $CPUInfo.SystemName 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_Name" -value $CPUInfo.Name 
Add-Member -inputObject $infoObject -memberType NoteProperty -name "CPU_Description" -value $CPUInfo.Description

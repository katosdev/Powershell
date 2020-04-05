# Email into the helpdesk to alert pro-actively of any account lockouts

Start-Transcript -path "c:\lockoutlog.txt" -append

$AccountLockOutEvent = Get-EventLog -LogName "Security" -InstanceID 4740 -Newest 1
$LockedAccount = $($AccountLockOutEvent.ReplacementStrings[0])
$AccountLockOutEventTime = $AccountLockOutEvent.TimeGenerated.ToLongDateString() + " " + $AccountLockOutEvent.TimeGenerated.ToLongTimeString()
$AccountLockOutEventMessage = $AccountLockOutEvent.Message

if ( $LockedAccount -ne "Guest" )
{ send-mailmessage $email
}
Stop-Transcript

param([string]$ConfigPath)
Import-Module ../Modules/ADSync-Functions.psm1
Start-Transcript -Path ../Logs/StarterStaffLog.txt -Append
[xml]$Config=Get-Content $ConfigPath
$School=$Config.SchoolConfig.School
$Email=$School.Email
$CsvPath='../Logs/StarterStaff.csv'
$AccessToken=Get-BromcomToken -BaseURL $School.BromcomAPI.BaseURL -ClientID $School.BromcomAPI.ClientID -ClientSecret $School.BromcomAPI.ClientSecret
$StaffData=Get-BromcomData -BaseURL $School.BromcomAPI.BaseURL -InstanceID $School.BromcomAPI.InstanceID -AccessToken $AccessToken -Endpoint 'staff'
foreach($Staff in $StaffData){Sync-ADUser -UserData $Staff -OUPath $School.OUPaths.StaffTeaching -Domain $School.Domain -Username ($Staff.LastName+$Staff.FirstName.Substring(0,1)).ToLower() -AccessToken $AccessToken -BaseURL $School.BromcomAPI.BaseURL -InstanceID $School.BromcomAPI.InstanceID -CsvPath $CsvPath}
Send-EmailReport -SMTPServer $Email.SMTPServer -From $Email.From -To $Email.To -Subject 'Starter Staff Report' -Body 'Attached is the report of processed staff starters.' -Attachment $CsvPath
Stop-Transcript
param([string]$ConfigPath)
Import-Module ../Modules/ADSync-Functions.psm1
Start-Transcript -Path ../Logs/RolloverStudentLog.txt -Append
[xml]$Config=Get-Content $ConfigPath
$School=$Config.SchoolConfig.School
$CsvPath="../Logs/RolloverStudent.csv"

# Authenticate Bromcom
$AuthBody=@{client_id=$School.BromcomAPI.ClientID;client_secret=$School.BromcomAPI.ClientSecret;grant_type='client_credentials'}
$TokenResponse=Invoke-RestMethod -Uri "$($School.BromcomAPI.BaseURL)/token" -Method Post -Body $AuthBody
$AccessToken=$TokenResponse.access_token
$Headers=@{Authorization="Bearer $AccessToken"}

# Fetch Data
$Data=Invoke-RestMethod -Uri "$($School.BromcomAPI.BaseURL)/$($School.BromcomAPI.InstanceID)/students" -Headers $Headers

foreach($User in $Data){
    try {
        $ExistingUser=Get-ADUser -Filter {EmployeeID -eq $User.EmployeeID};if($ExistingUser){Move-StudentToNextYearOU -User $ExistingUser -CurrentYear $User.IntakeYear -SchoolName $School.Name -Domain $School.Domain;$row=[PSCustomObject]@{Name="$($User.FirstName) $($User.LastName)";EmployeeID=$User.EmployeeID;MovedToYear=[int]$User.IntakeYear+1};$row|Export-Csv -Path $CsvPath -Append -NoTypeInformation}
    } catch {Write-Error "Error processing user: $_"}
}

Send-GraphEmail -TenantID $School.GraphAPI.TenantID -ClientID $School.GraphAPI.ClientID -ClientSecret $School.GraphAPI.ClientSecret -To 'farnworthz@thequillcofetrust.org' -Subject "$($School.Name) - Student Rollover Processed" -Body "Attached is the report of processed Student Rollover Processed." -Attachment $CsvPath
Stop-Transcript

param([string]$ConfigPath)
Import-Module ../Modules/ADSync-Functions.psm1
Start-Transcript -Path ../Logs/StarterStudentLog.txt -Append
[xml]$Config=Get-Content $ConfigPath
$School=$Config.SchoolConfig.School
$CsvPath="../Logs/StarterStudent.csv"

# Authenticate Bromcom
$AuthBody=@{client_id=$School.BromcomAPI.ClientID;client_secret=$School.BromcomAPI.ClientSecret;grant_type='client_credentials'}
$TokenResponse=Invoke-RestMethod -Uri "$($School.BromcomAPI.BaseURL)/token" -Method Post -Body $AuthBody
$AccessToken=$TokenResponse.access_token
$Headers=@{Authorization="Bearer $AccessToken"}

# Fetch Data
$Data=Invoke-RestMethod -Uri "$($School.BromcomAPI.BaseURL)/$($School.BromcomAPI.InstanceID)/students" -Headers $Headers

foreach($User in $Data){
    try {
        $Username=Generate-Username -Format $School.UsernameFormat -LastName $User.LastName -FirstName $User.FirstName -IntakeYear $User.IntakeYear;$Password=Generate-PasswordFromDOB -DOB $User.DateOfBirth;$YearOU="OU=$($User.IntakeYear),OU=Students,OU=$($School.Name),DC=$($School.Domain.Split('.')[0]),DC=org";Ensure-OUExists -OUPath $YearOU;$ExistingUser=Get-ADUser -Filter {Name -eq "$($User.FirstName) $($User.LastName)"};if(-not $ExistingUser){New-ADUser -Name "$($User.FirstName) $($User.LastName)" -SamAccountName $Username -UserPrincipalName "$Username@$($School.Domain)" -GivenName $User.FirstName -Surname $User.LastName -EmployeeID $User.EmployeeID -Department $School.Department -Company $School.Company -EmailAddress $User.Email -Path $YearOU -Enabled $true -AccountPassword (ConvertTo-SecureString $Password -AsPlainText -Force);Set-ADUser -Identity $Username -Add @{proxyAddresses="SMTP:$($User.Email)"}}else{Set-ADUser -Identity $ExistingUser.DistinguishedName -EmployeeID $User.EmployeeID -EmailAddress $User.Email -Department $School.Department -Company $School.Company;Set-ADUser -Identity $ExistingUser.DistinguishedName -Add @{proxyAddresses="SMTP:$($User.Email)"}};$row=[PSCustomObject]@{Name="$($User.FirstName) $($User.LastName)";EmployeeID=$User.EmployeeID;Username=$Username;Email=$User.Email;Password=$Password};$row|Export-Csv -Path $CsvPath -Append -NoTypeInformation
    } catch {Write-Error "Error processing user: $_"}
}

Send-GraphEmail -TenantID $School.GraphAPI.TenantID -ClientID $School.GraphAPI.ClientID -ClientSecret $School.GraphAPI.ClientSecret -To 'farnworthz@thequillcofetrust.org' -Subject "$($School.Name) - Student Starters Processed" -Body "Attached is the report of processed Student Starters Processed." -Attachment $CsvPath
Stop-Transcript

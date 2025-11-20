param([string]$ConfigPath)
Import-Module ../Modules/TeamsAutomation-Functions.psm1
Start-Transcript -Path ../Logs/CreateTeamsClassesLog.txt -Append
[xml]$Config = Get-Content $ConfigPath
$School = $Config.SchoolConfig.School

# Connect to Graph API
$AccessToken = Connect-GraphAPI -TenantID $School.GraphAPI.TenantID -ClientID $School.GraphAPI.ClientID -ClientSecret $School.GraphAPI.ClientSecret

# Fetch classes from Bromcom
$AuthBody = @{client_id=$School.BromcomAPI.ClientID;client_secret=$School.BromcomAPI.ClientSecret;grant_type='client_credentials'}
$TokenResponse = Invoke-RestMethod -Uri "$($School.BromcomAPI.BaseURL)/token" -Method Post -Body $AuthBody
$BromcomToken = $TokenResponse.access_token
$Headers = @{Authorization="Bearer $BromcomToken"}
$Classes = Invoke-RestMethod -Uri "$($School.BromcomAPI.BaseURL)/$($School.BromcomAPI.InstanceID)/classes" -Headers $Headers

foreach ($Class in $Classes) {
    try {
        $DisplayName="$($School.Name) - $($Class.Name) $($Class.Year)";$Description="Class for $($Class.Year)";$Team=Create-TeamClass -AccessToken $AccessToken -DisplayName $DisplayName -Description $Description;foreach($Teacher in $Class.Teachers){Add-TeamMember -AccessToken $AccessToken -GroupId $Team.id -UserId $Teacher.Email -Role 'owner'};foreach($Student in $Class.Students){Add-TeamMember -AccessToken $AccessToken -GroupId $Team.id -UserId $Student.Email -Role 'member'}
    } catch {Write-Error "Error processing class: $_"}
}
Stop-Transcript

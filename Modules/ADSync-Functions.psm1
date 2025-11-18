Function Generate-PasswordFromDOB {
    param ([string]$DOB)
    $CleanDOB=$DOB -replace '/', ''
    return "Changeme$CleanDOB!"
}

Function Ensure-OUExists {
    param ([string]$OUPath)
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$OUPath'" -ErrorAction SilentlyContinue)) {
        $OUName=$OUPath.Split(',')[0].Split('=')[1]
        $ParentOU=($OUPath -split ',',2)[1]
        New-ADOrganizationalUnit -Name $OUName -Path $ParentOU
        Write-Host "Created OU: $OUPath"
    }
}

Function Move-StudentToNextYearOU {
    param ([object]$User,[string]$CurrentYear,[string]$SchoolName,[string]$Domain)
    $NextYear=[int]$CurrentYear+1
    $NextOU="OU=$NextYear,OU=Students,OU=$SchoolName,DC=$($Domain.Split('.')[0]),DC=org"
    Ensure-OUExists -OUPath $NextOU
    Move-ADObject -Identity $User.DistinguishedName -TargetPath $NextOU
    Write-Host "Moved student to next year OU: $NextOU"
}

Function Send-GraphEmail {
    param ([string]$TenantID,[string]$ClientID,[string]$ClientSecret,[string]$To,[string]$Subject,[string]$Body,[string]$Attachment)
    try {
        $TokenResponse=Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token" -Method Post -Body @{client_id=$ClientID;scope="https://graph.microsoft.com/.default";client_secret=$ClientSecret;grant_type="client_credentials"}
        $AccessToken=$TokenResponse.access_token
        $Headers=@{Authorization="Bearer $AccessToken";"Content-Type"="application/json"}
        $AttachmentBytes=[System.Convert]::ToBase64String([System.IO.File]::ReadAllBytes($Attachment))
        $EmailBody=@{
            message=@{
                subject=$Subject;
                body=@{contentType="Text";content=$Body};
                toRecipients=@(@{emailAddress=@{address=$To}});
                attachments=@(@{"@odata.type"="#microsoft.graph.fileAttachment";name=(Split-Path $Attachment -Leaf);contentBytes=$AttachmentBytes})
            };
            saveToSentItems=$true
        }
        Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$To/sendMail" -Headers $Headers -Method Post -Body ($EmailBody | ConvertTo-Json -Depth 5)
    } catch {Write-Error "Failed to send email: $_"}
}

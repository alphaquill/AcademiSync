Function Generate-PasswordFromDOB {
    param ([string]$DOB)
    $CleanDOB=$DOB -replace '/', ''
    return "Changeme$CleanDOB!"
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

Function Connect-GraphAPI {
    param ([string]$TenantID,[string]$ClientID,[string]$ClientSecret)
    $TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantID/oauth2/v2.0/token" -Method Post -Body @{client_id=$ClientID;scope="https://graph.microsoft.com/.default";client_secret=$ClientSecret;grant_type="client_credentials"}
    return $TokenResponse.access_token
}

Function Create-TeamClass {
    param ([string]$AccessToken,[string]$DisplayName,[string]$Description)
    $Headers = @{Authorization = "Bearer $AccessToken";"Content-Type"="application/json"}
    $Body = @{template@odata.bind="https://graph.microsoft.com/v1.0/teamsTemplates('educationClass')";displayName=$DisplayName;description=$Description} | ConvertTo-Json
    $Response = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/teams" -Headers $Headers -Method Post -Body $Body
    return $Response
}

Function Add-TeamMember {
    param ([string]$AccessToken,[string]$GroupId,[string]$UserId,[string]$Role)
    $Headers = @{Authorization = "Bearer $AccessToken";"Content-Type"="application/json"}
    $Body = @{"@odata.id"="https://graph.microsoft.com/v1.0/users/$UserId"}
    $Uri = "https://graph.microsoft.com/v1.0/groups/$GroupId/members/$ref"
    Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Post -Body ($Body | ConvertTo-Json)
    if ($Role -eq "owner") {
        $OwnerUri = "https://graph.microsoft.com/v1.0/groups/$GroupId/owners/$ref"
        Invoke-RestMethod -Uri $OwnerUri -Headers $Headers -Method Post -Body ($Body | ConvertTo-Json)
    }
}

Function Delete-TeamClass {
    param ([string]$AccessToken,[string]$GroupId)
    $Headers = @{Authorization = "Bearer $AccessToken"}
    Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/groups/$GroupId" -Headers $Headers -Method Delete
}

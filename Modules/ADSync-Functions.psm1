Function Get-BromcomToken {
    param ([string]$BaseURL,[string]$ClientID,[string]$ClientSecret)
    try {
        $AuthBody=@{client_id=$ClientID;client_secret=$ClientSecret;grant_type="client_credentials"}
        $TokenResponse=Invoke-RestMethod -Uri "$BaseURL/token" -Method Post -Body $AuthBody
        return $TokenResponse.access_token
    } catch {
        Write-Error "Failed to get Bromcom token: $_"
    }
}

Function Get-BromcomData {
    param ([string]$BaseURL,[string]$InstanceID,[string]$AccessToken,[string]$Endpoint)
    try {
        $Headers=@{Authorization="Bearer $AccessToken"}
        $Uri="$BaseURL/$InstanceID/$Endpoint"
        return Invoke-RestMethod -Uri $Uri -Headers $Headers
    } catch {
        Write-Error "Failed to get Bromcom data from $Endpoint: $_"
    }
}

Function Update-BromcomData {
    param ([string]$BaseURL,[string]$InstanceID,[string]$AccessToken,[string]$Endpoint,[object]$Body)
    try {
        $Headers=@{Authorization="Bearer $AccessToken";"Content-Type"="application/json"}
        $Uri="$BaseURL/$InstanceID/$Endpoint"
        Invoke-RestMethod -Uri $Uri -Headers $Headers -Method Put -Body ($Body | ConvertTo-Json -Depth 5)
        Write-Host "Write-back successful for $Endpoint"
    } catch {
        Write-Error "Failed to update Bromcom data: $_"
    }
}

Function Generate-Username {
    param ([string]$Format,[string]$LastName,[string]$FirstName,[string]$IntakeYear)
    switch -Wildcard ($Format) {
        "intakeyearlastnamefirstinitial" {return "$IntakeYear$LastName$($FirstName.Substring(0,1))".ToLower()}
        "030intakeyearlastnamefirstinitial" {return "030$IntakeYear$LastName$($FirstName.Substring(0,1))".ToLower()}
        "048intakeyearlastnamefirstinitial" {return "048$IntakeYear$LastName$($FirstName.Substring(0,1))".ToLower()}
        default {throw "Unknown username format: $Format"}
    }
}

Function Sync-ADUser {
    param ([object]$UserData,[string]$OUPath,[string]$Domain,[string]$Username,[string]$AccessToken,[string]$BaseURL,[string]$InstanceID,[string]$CsvPath)
    try {
        $SamAccountName=$Username
        $ExistingUser=Get-ADUser -Filter {Name -eq "$($UserData.FirstName) $($UserData.LastName)"} -Properties EmployeeID,DistinguishedName
        if($ExistingUser){
            Set-ADUser -Identity $ExistingUser.DistinguishedName -EmployeeID $UserData.EmployeeID
            Write-Host "Updated EmployeeID for existing user: $SamAccountName"
        } else {
            Write-Host "No match found for $($UserData.FirstName) $($UserData.LastName), skipping."
            return
        }
        # Log to CSV
        $row=[PSCustomObject]@{Name="$($UserData.FirstName) $($UserData.LastName)";EmployeeID=$UserData.EmployeeID;Username=$SamAccountName}
        $row | Export-Csv -Path $CsvPath -Append -NoTypeInformation
    } catch {
        Write-Error "Error syncing AD user: $_"
    }
}

Function Send-EmailReport {
    param ([string]$SMTPServer,[string]$From,[string]$To,[string]$Subject,[string]$Body,[string]$Attachment)
    try {
        Send-MailMessage -SmtpServer $SMTPServer -From $From -To $To -Subject $Subject -Body $Body -Attachments $Attachment
        Write-Host "Email sent successfully to $To"
    } catch {
        Write-Error "Failed to send email: $_"
    }
}

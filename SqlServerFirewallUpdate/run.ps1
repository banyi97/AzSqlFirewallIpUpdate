using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."
$ip = $null
try {
   $ip = $Request.Headers."x-forwarded-for".Split(":")[0]
}
catch {}
Write-Host "SQL server firewall update - caller: $ip"
if($ip){
    $rules = Get-AzSqlServerFirewallRule -ResourceGroupName $env:RESOURCE_GROUP -ServerName $env:SQL_SERVER_NAME
    if(-not ($rules | Where-Object { $_.StartIpAddress -eq $ip})){
        $date = Get-Date -Format "yyyyMMddHHmmss"
        New-AzSqlServerFirewallRule `
            -ResourceGroupName "$env:RESOURCE_GROUP" `
            -ServerName "$env:SQL_SERVER_NAME" `
            -FirewallRuleName "Rule$date" `
            -StartIpAddress "$ip" `
            -EndIpAddress "$ip"
        Write-Host "New Azure SQL server firewall rule added - Rule$date - $ip)"
    }
}

# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = "ok"
})

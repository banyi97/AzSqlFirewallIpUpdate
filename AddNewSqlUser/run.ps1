using namespace System.Net

# Input bindings are passed in via param block.
param($Request, $TriggerMetadata)

# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function processed a request."

$ServerName = (Get-AzSqlServer -ResourceGroupName $env:RESOURCE_GROUP -ServerName $env:SQL_SERVER_NAME).FullyQualifiedDomainName
$DatabaseName = 'master'
$userName = $env:DB_ADMIN
$password = $env:DB_PASS 
$connectionString = 'Data Source={0};database={1};User ID={2};Password={3}' -f $ServerName,$DatabaseName,$userName,$password

if( 
    $Request.Body -and
    (-not [string]::IsNullOrEmpty($Request.Body.username)) -and
    (-not [string]::IsNullOrEmpty($Request.Body.password)) 
){
    $query = "CREATE LOGIN {0} WITH PASSWORD = '{1}';" -f $Request.Body.username,$Request.Body.password
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand($query, $sqlConnection)
    
    $sqlConnection.Open()
    $command.ExecuteNonQuery()
    $sqlConnection.Close()

    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = 'ok'
    })
}
else{
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = 'fail'
    })
}


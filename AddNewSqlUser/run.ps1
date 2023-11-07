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
    (-not [string]::IsNullOrEmpty($Request.Body.password)) -and
    (-not [string]::IsNullOrEmpty($Request.Body.database))
){
    $query = "CREATE LOGIN {0} WITH PASSWORD = '{1}'; CREATE USER {0} FOR LOGIN {0} WITH DEFAULT_SCHEMA=[dbo];" -f $Request.Body.username,$Request.Body.password
    $sqlConnection = New-Object System.Data.SqlClient.SqlConnection $connectionString
    $command = New-Object -TypeName System.Data.SqlClient.SqlCommand($query, $sqlConnection)

    $connectionString2 = 'Data Source={0};database={1};User ID={2};Password={3}' -f $ServerName,$Request.Body.database,$userName,$password
    $query2 = "CREATE USER {0} FOR LOGIN {0} WITH DEFAULT_SCHEMA=[dbo];ALTER ROLE db_owner ADD MEMBER {0};" -f $Request.Body.username
    $sqlConnection2 = New-Object System.Data.SqlClient.SqlConnection $connectionString2
    $command2 = New-Object -TypeName System.Data.SqlClient.SqlCommand($query2, $sqlConnection2)
    $hiba = $false
    Try
    {
    $sqlConnection.Open()
    $command.ExecuteNonQuery()
    $sqlConnection.Close()

    $sqlConnection2.Open()
    $command2.ExecuteNonQuery()
    $sqlConnection2.Close()
    }
    Catch
    {
        $hiba=$true 
        $message = $_
        Write-Warning "Something happened! $message"
    }
    if($hiba -eq $true)
    {
        Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = 'Jelszó nem megfelelő'})
    }
    else
    {
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::OK
        Body = 'ok'})
    }
}
else{
    Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
        StatusCode = [HttpStatusCode]::BadRequest
        Body = 'Hiányos paraméterek'
    })
}


# Clear SharePoint farm timer job table
Add-PSSnapin microsoft.sharepoint.powershell

$conn = New-Object System.Data.SqlClient.SqlConnection
$cmd = New-Object System.Data.SqlClient.SqlCommand
$configDb = Get-SPDatabase |? {$_.TypeName -match "Configuration Database"}
$connectionString = $configDb.DatabaseConnectionString
$conn.ConnectionString = $connectionString
$conn.Open()
$cmd.connection = $conn

Write-Host "Truncating timerjobhistory table on DB:  " $configDb.Name
$cmd.CommandText = "TRUNCATE table TimerJobHistory"
$rows = $cmd.ExecuteReader()
if ($rows.HasRows -eq $true)
{
	while ($rows.Read())
			{
				"Truncating TimerJobHistory table"
			}
}
$rows.Close();
$conn.Close();
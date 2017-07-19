<#
.SYNOPSIS
	Custom reports for Microsoft SMAT (SharePoint Migration Assesment Tool)
#>

# Plugins
Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue | Out-Null
Import-Module SQLPS -ErrorAction SilentlyContinue | Out-Null

# Query SQL database
Function RunQuery($tsql) {
    $global:dt = New-Object System.Data.Datatable "SPQuery"
    foreach ($cdb in $global:cdbs) {
        $i = $cdb.NormalizedDataSource
		$d = $cdb.Name
		Write-Host $d -Fore Yellow
        $res = Invoke-Sqlcmd -Query $tsql -QueryTimeout 360 -ServerInstance $i -Database $d
		if ($res) {
			# Result Columns
			$cols = $res[0] | Get-Member |? {$_.MemberType -eq "Property" -and $_.Name -ne "Length"}
			foreach ($c in $cols) {
				# Cols
				$found = $false
				foreach ($gc in $global:dt.Columns) {
					if ($c.Name -eq $gc.ColumnName) {
						$found = $true
					}
				}
				if (!$found) {
					$global:dt.Columns.Add($c.Name) | Out-Null
				}
			}
			
			# Standard Columns
			if (!$global:dt.Columns["WebAppURL"]) {
				$global:dt.Columns.Add("WebAppURL") | Out-Null
			}
			if (!$global:dt.Columns["SQLInstance"]) {
				$global:dt.Columns.Add("SQLInstance") | Out-Null
			}
			if (!$global:dt.Columns["ContentDB"]) {
				$global:dt.Columns.Add("ContentDB") | Out-Null
			}
		
			# Result Rows
			foreach ($r in $res) {
				# Rows
				$newRow = $global:dt.NewRow()
				foreach ($c in $cols) {
					$prop = $c.Name
					$newRow[$prop] = $r[$prop]
				}
				$newRow["WebAppURL"] = $cdb.WebApplication.URL
				$newRow["SQLInstance"] = $cdb.NormalizedDataSource
				$newRow["ContentDB"] = $cdb.Name
				$global:dt.Rows.Add($newRow) | Out-Null
			}
		}
    }   
}
Function UpdateTable ($tableName) {
	Invoke-Sqlcmd -Query "DELETE FROM $tableName" -QueryTimeout 360 -ServerInstance $i -Database $d
	foreach ($row in $global:dt) {
		$cols = ""
		$val = ""
		foreach ($col in $global:dt.Columns) {
			$cols += $col.ColumnName + ","
			$cell = $row[$col.ColumnName]
			if (!($cell -is [System.DBNull])) {
				$cell = $cell.Replace("'","''")
			}
			$val += "'" + $cell + "',"
		}
		$cols = $cols.TrimEnd(",")
		$val = $val.TrimEnd(",")
		$cmd = "INSERT INTO $tableName ($cols) VALUES ($val)"
		if ($row["FullUrl"].Length -gt 1) {
			$skip = $false
			if ($tableName -eq "_WorflowDPAction" -and $row["DP"] -eq "0") {
				$skip = $true
			}
			if (!$skip) {
				Invoke-Sqlcmd -Query $cmd -QueryTimeout 360 -ServerInstance $i -Database $d
			}
		}
	}
}

Function LoadSQLTable($tableName, $csvData) {
	# Delete old table
	$cmd = "DROP TABLE $tableName"
	Invoke-Sqlcmd -Query $cmd -QueryTimeout 360 -ServerInstance $i -Database $d -ErrorAction SilentlyContinue | Out-Null

	# Create new table
	$insertCols = ""
	$createCols = ""
	$cols = $csvData[0] | Get-Member |? {$_.MemberType -eq "NoteProperty" -and $_.Name -ne "Length"}
	foreach ($col in $cols) {
		$n = $col.Name
		$createCols += "[$n] VARCHAR(1024),"
		$insertCols += "[$n],"
	}
	$insertCols = $insertCols.TrimEnd(",")
	$createCols = $createCols.TrimEnd(",")
	$cmd = "CREATE TABLE $tableName ($createCols)"
	Invoke-Sqlcmd -Query $cmd -QueryTimeout 360 -ServerInstance $i -Database $d

	# Insert rows
	$values = ""
	foreach ($row in $csvData) {
		Write-Host "." -NoNewLine
		# Reset
		$values = ""
		$cell = ""
		foreach ($col in $insertCols.Split(",")) {
			# Append cell values
			$col = $col.TrimStart("[").TrimEnd("]")
			$cell = $row."$col".Replace("'","''")
			$values += "'$cell',"
		}
		# Execute SQL INSERT
		$values = $values.TrimEnd(",")
		$cmd = "INSERT INTO $tableName ($insertCols) VALUES ($values)"
		Invoke-Sqlcmd -Query $cmd -QueryTimeout 360 -ServerInstance $i -Database $d
	}
}
Function LoadSMAT($unc) {
	cd c:\
	$folderDates = Get-ChildItem $unc
	$mostRecentFolder = ($folderDates | Sort-Object LastWriteTime -desc)[0]
	$global:path = $mostRecentFolder.FullName

	# Site
	$sar = "$global:path\SiteAssessmentReport.csv"
	$csv = Import-Csv $sar
	LoadSQLTable "SiteAssessmentReport" $csv

	# Detail
	$files =  Get-ChildItem "$global:path\ScannerReports"
	foreach ($f in $files) {
		# Skip two large reports
		$name = $f.Name
		Write-Host $name -Fore Green
		if (!$name.Contains("BrowserFileHandling") -and !$name.Contains("FileVersions")) {
			$csv =  Import-Csv $f.FullName
			LoadSQLTable $name.Replace(".csv","").Replace("-detail","") $csv
		}
	}
}
Function LastUpdated() {
	$time = (Get-Date).ToString()
	$cmd = "UPDATE [_LastUpdated] SET LastUpdated='$time'"
	Invoke-Sqlcmd -Query $cmd -QueryTimeout 360 -ServerInstance $i -Database $d

	$cmd = "UPDATE [_LastUpdated] SET Folder='$global:path'"
	Invoke-Sqlcmd -Query $cmd -QueryTimeout 360 -ServerInstance $i -Database $d
}
Function Main() {
	# Config
	Start-Transcript
	Get-Date
	$global:cdbs = Get-SPWebApplication "http://sharepoint" | Get-SPContentDatabase
	$i = "SPSQL2"
	$d = "SMAT_Report"

	# Lists - Where throttling is disabled
	$tsqlUnthrottledList = "SELECT AllLists.tp_SiteId AS SiteId, AllWebs.Id AS WebId, AllWebs.FullUrl, AllLists.tp_Title AS ListTitle FROM AllLists INNER JOIN AllWebs ON AllLists.tp_WebId = AllWebs.Id AND AllLists.tp_SiteId = AllWebs.SiteId WHERE (AllLists.tp_NoThrottleListOperations = 1)"
	RunQuery $tsqlUnthrottledList
	UpdateTable "_UnThrottledLists"

	# Worfklow XOML using DP Actions
	$tsqlWorkflow2010 = "SELECT DocStreams.SiteId, AllWebs.Id AS WebId, AllWebs.FullUrl, AllDocs.DirName, AllDocs.LeafName, CHARINDEX('DP.Share', CAST(DocStreams.[Content] AS varchar(MAX))) AS DP FROM AllDocs INNER JOIN DocStreams ON AllDocs.Id = DocStreams.DocId INNER JOIN AllLists ON AllDocs.ListId = AllLists.tp_ID INNER JOIN AllWebs ON AllLists.tp_WebId = AllWebs.Id AND AllLists.tp_SiteId = AllWebs.SiteId AND AllDocs.SiteId = AllWebs.SiteId AND AllDocs.NextBSN = DocStreams.BSN WHERE (AllDocs.Extension = 'XOML') AND (AllLists.tp_Title = 'Workflows')"
	RunQuery $tsqlWorkflow2010
	UpdateTable "_WorflowDPAction"

	# Upload latest SMAT report CSV
	LoadSMAT "\\sharepoint-wfe\report"

	# Last updated date and time stamp
	LastUpdated
	Get-Date
	"DONE"
	Stop-Transcript

	# InfoPath - ASMX Connections??
}
Main
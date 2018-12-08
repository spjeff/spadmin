<#
.DESCRIPTION
	Update SharePoint 2013 Content Database and replace current Site Collection GUID ID numbers with newly generated GUIDs
	
	NOTE - Exclusively TSQL, does not require SharePoint server and can run anywhere.

.NOTES
	File Namespace	: SPContentDatabase-Replace-Site-GUIDs
	Author			: Jeff Jones - @spjeff
	Version			: 0.13
	Last Modified	: 01-09-2017

.LINK
	Source Code
	http://www.github.com/spjeff/spadmin/SPContentDatabase-Replace-Site-GUIDs
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $True, ValueFromPipeline = $false, HelpMessage = 'Target SQL instance hosting SharePoint Content Database.')]
    $sqlInstance,

    [Parameter(Mandatory = $True, ValueFromPipeline = $false, HelpMessage = 'Target content database name.')]
    $sqlDatabaseName,
	
	[Parameter(Mandatory=$false, ValueFromPipeline=$false, HelpMessage='Dry run skips UPDATE statement and runs read-only.')]
	[Alias("d")]
	[switch]$dryRun = $false
)

# Echo params
Write-Host "SPContentDatabase-Replace-Site-GUIDs"
Write-Host "sqlInstance : $sqlInstance"
Write-Host "sqlDatabaseName : $sqlDatabaseName"

# Plugin
Import-Module SQLPS -ErrorAction SilentlyContinue | Out-Null

Function InvokeSQL ($cmd) {
    # Run SQL command
    return Invoke-Sqlcmd $cmd -ServerInstance $sqlInstance -Database $sqlDatabaseName -QueryTimeout 3600
}

Function HasColumn ($tableName, $columnName) {
    # Run SQL command
    $cmd =  "SELECT name FROM sys.columns WHERE object_id=object_id(`'$tableName`') AND name=`'$columnName`'"
    $result = InvokeSQL $cmd
    if ($result) {
        return $true
    } else {
        return $false
    }
}

Function Main {
    # Enum site collections
    $sites = InvokeSQL "SELECT id FROM [AllSites]"

    # Loop per Site Collection"
    $a = 1
    $b = 1
    if ($sites.Count) {
        $b = $sites.Count
    }
    foreach($siteRow in $sites) {
        # Locate current SiteID value in target table
        $oldID = $siteRow["id"]
        if (!$oldID) {
            $oldID = $siteRow["tp_SiteID"]
        }
        $newID = [guid]::NewGuid().ToString()

        # Display
        Write-Host "- Replace Site ($a/$b) GUID $oldID with $newID" -Fore Yellow

        # Enum tables
	$queryTables = "SELECT S.name + '.' + O.name AS 'name' FROM sys.objects AS O JOIN  sys.schemas S ON O.schema_id = S.schema_id WHERE O.type = 'U' ORDER BY name"
        $tables = InvokeSQL $queryTables

        # Loop per table
        $c = 1
        $d = $tables.Count
        foreach ($row in $tables) {
            # Display
            $tableName = $row["name"]
            $tableCount = (InvokeSQL "SELECT COUNT(*) FROM $tableName")[0]
            $date = (Get-Date).ToShortDateString()
            $time = (Get-Date).ToShortTimeString()
            Write-Host ("[$date $time] Update Table ($c/$d) - $tableName - Rows {0:N0}" -f $tableCount) -Fore Yellow

            # SQL UPDATE per target Site Collection table
            if ($oldID) {
                # Two different SQL schema with Site Collection ID
                $hasColumn = HasColumn $tableName "SiteId"
                if ($hasColumn) {
                    if (!$dryRun) {
						InvokeSQL "UPDATE $tableName SET SiteId='$newID' WHERE SiteID='$oldID'"
					}
                }

                $hasColumn = HasColumn $tableName "tp_SiteId"
                if ($hasColumn) {
					if (!$dryRun) {
						InvokeSQL "UPDATE $tableName SET tp_SiteId='$newID' WHERE tp_SiteId='$oldID'"
					}
                }
            }
            $c++
        }

        # Site Table parent
		if (!$dryRun) {
			InvokeSQL "UPDATE [AllSites] SET Id='$newID' WHERE Id='$oldID'"
		}

        $a++
    }
    Write-Host "DONE" -Fore Green
}

Start-Transcript
Main
Stop-Transcript

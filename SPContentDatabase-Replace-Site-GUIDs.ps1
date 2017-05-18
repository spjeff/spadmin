<#
.DESCRIPTION
	Update SharePoint 2013 Content Database and replace current Site Collection GUID ID numbers with newly generated GUIDs
	
	NOTE - Exclusively TSQL, does not require SharePoint server and can run anywhere.

.NOTES
	File Namespace	: SPContentDatabase-Replace-Site-GUIDs
	Author			: Jeff Jones - @spjeff
	Version			: 0.10
	Last Modified	: 05-18-2017

.LINK
	Source Code
	http://www.github.com/spjeff/spadmin/SPContentDatabase-Replace-Site-GUIDs
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $False, ValueFromPipeline = $false, HelpMessage = 'Target SQL instance hosting SharePoint Content Database.')]
    $sqlInstance,

    [Parameter(Mandatory = $False, ValueFromPipeline = $false, HelpMessage = 'Target content database name.')]
    $sqlDatabaseName
)
$sqlInstance = "SPSQL"
$sqlDatabaseName = "SP2013_SPJ_Content_projects82_000"

# Plugin
Import-Module SQLPS

Function InvokeSQL ($cmd) {
    # Run SQL command
    return Invoke-Sqlcmd $cmd -ServerInstance $sqlInstance -Database $sqlDatabaseName -QueryTimeout 3600
}

Function HasColumn ($tableName, $columnName) {
    # Run SQL command
    $result = InvokeSQL "SELECT name FROM sys.columns WHERE object_id=object_id('dbo.$tableName') AND name='$columnName'" $true
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
        $tables = InvokeSQL "SELECT name FROM [sysobjects] WHERE xtype='U' ORDER BY name"

        # Loop per table
        $c = 1
        $d = $tables.Count
        foreach ($row in $tables) {
            # Display
            $tableName = $row["name"]
            $tableCount = (InvokeSQL "SELECT COUNT(*) FROM $tableName")[0]
            $date = (Get-Date).ToShortDateString()
            $time = (Get-Date).ToShortTimeString()
            Write-Host "[$date $time] Update Table ($c/$d) - $tableName - Rows {0:N0}" -f $tableCount -Fore Yellow

            # SQL UPDATE per target Site Collection table
            if ($oldID) {
                $hasColumn = HasColumn $tableName "SiteId"
                if ($hasColumn) {
                    InvokeSQL "XUPDATE [$tableName] SET SiteId='$newID' WHERE SiteID='$oldID'"
                }

                $hasColumn = HasColumn $tableName "tp_SiteId"
                if ($hasColumn) {
                    InvokeSQL "XUPDATE [$tableName] SET tp_SiteId='$newID' WHERE tp_SiteId='$oldID'"
                }
            }
            $c++
        }

        # Site Table parent
        InvokeSQL "UPDATE [AllSites] SET Id='$newID' WHERE Id='$oldID'"

        $a++
    }
    Write-Host "DONE" -Fore Green
}

Start-Transcript
Main
Stop-Transcript
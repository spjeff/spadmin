<#
.DESCRIPTION
	Update SharePoint 2013 Content Database and replace current Site Collection GUID ID numbers with newly generated GUIDs
	
	NOTE - Exclusively TSQL, does not require SharePoint server and can run anywhere.

.NOTES
	File Namespace	: SPContentDatabase-Replace-Site-GUIDs
	Author			: Jeff Jones - @spjeff
	Version			: 0.14
	Last Modified	: 02-22-2019

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
    # Purge tables [AuditData] and [EventCache]
    $tsqlAudit = @"
    DROP TABLE [AuditData]
    CREATE TABLE [dbo].[AuditData](
        [SiteId] [uniqueidentifier] NOT NULL,
        [ItemId] [uniqueidentifier] NOT NULL,
        [ItemType] [smallint] NOT NULL,
        [UserId] [int] NULL,
        [AppPrincipalId] [int] NULL,
        [MachineName] [nvarchar](128) NULL,
        [MachineIp] [nvarchar](20) NULL,
        [DocLocation] [nvarchar](260) NULL,
        [LocationType] [tinyint] NULL,
        [Occurred] [datetime] NOT NULL,
        [Event] [int] NOT NULL,
        [EventName] [nvarchar](128) NULL,
        [EventSource] [tinyint] NOT NULL,
        [SourceName] [nvarchar](256) NULL,
        [EventData] [nvarchar](max) NULL
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
    GO
    ALTER TABLE [dbo].[AuditData] SET (LOCK_ESCALATION = DISABLE)
    GO
"@

    $tsqlEventCache = @"
    CREATE TABLE [dbo].[EventCache](
        [EventTime] [datetime] NOT NULL,
        [Id] [bigint] IDENTITY(1,1) NOT NULL,
        [SiteId] [uniqueidentifier] NOT NULL,
        [WebId] [uniqueidentifier] NULL,
        [ListId] [uniqueidentifier] NULL,
        [ItemId] [int] NULL,
        [DocId] [uniqueidentifier] NULL,
        [Guid0] [uniqueidentifier] NULL,
        [Int0] [int] NULL,
        [Int1] [int] NULL,
        [ContentTypeId] [dbo].[tContentTypeId] NULL,
        [ItemName] [nvarchar](255) NULL,
        [ItemFullUrl] [nvarchar](260) NULL,
        [EventType] [int] NOT NULL,
        [ObjectType] [int] NOT NULL,
        [ModifiedBy] [nvarchar](255) NULL,
        [TimeLastModified] [datetime] NOT NULL,
        [EventData] [varbinary](max) NULL,
        [ACL] [varbinary](max) NULL,
        [DocClientId] [varbinary](16) NULL,
        [CorrelationId] [uniqueidentifier] NULL,
        [Guid1] [uniqueidentifier] NULL,
        [TinyInt0] [tinyint] NULL,
        [Text0] [nvarchar](255) NULL,
        [OriginatorId] [uniqueidentifier] NULL,
     CONSTRAINT [EventCache_Id] PRIMARY KEY CLUSTERED 
    (
        [Id] ASC,
        [SiteId] ASC
    )WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = ON, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, FILLFACTOR = 100) ON [PRIMARY]
    ) ON [PRIMARY] TEXTIMAGE_ON [PRIMARY]
    GO
    
    ALTER TABLE [dbo].[EventCache] SET (LOCK_ESCALATION = DISABLE)
    GO
"@

    # Execute SQL Query
    InvokeSQL $tsqlAudit
    InvokeSQL $tsqlEventCache

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

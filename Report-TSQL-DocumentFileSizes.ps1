Clear-Host
Get-Date
$SQLInstance    = 'SQL-INSTANCE-HERE'
$StartDate      = '1/1/2020'
$EndDate        = '12/31/2020'

##Update the query below to change which databases to target in a SQL Instance
$Databases = Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query "SELECT DISTINCT name FROM sys.databases WHERE database_id>4"

$CreateTblQry = "IF EXISTS(SELECT * FROM tempdb.dbo.sysobjects WHERE [name]='tbl_AllDocsSizeInfo')
DROP TABLE  tempdb.dbo.tbl_AllDocsSizeInfo;

CREATE TABLE tempdb.dbo.tbl_AllDocsSizeInfo
(
SQLInstance nvarchar(1024),
DatabaseName nvarchar(1024),
TotalSizeofDocs  bigint,
TotalNumofDocs bigint,
AverageSizeofDocs  bigint,
LargestFile_DIRName  nvarchar(1024),
LargestFile_LeafName   nvarchar(1024),
LargestFile_ExtensionForFile  nvarchar(10),
LargestFile_TimeCreated datetime, 
LargestFile_TimeLastModified datetime, 
LargestFile_Size bigint
)
"
Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query $CreateTblQry

foreach ($database in $Databases) {
    $DB = ''
    $DB = $database.name
    $DB

    $totalQry = "SELECT sum(size) as Total FROM [$DB].dbo.alldocs 
    WHERE ExtensionForFile in ('PPTX','DOCX','XLSX','PDF')
    AND TimeCreated > '$StartDate' AND TimeCreated < '$EndDate'"

    $totalNumQry = "SELECT count(*) as TotalNumofDocs FROM [$DB].dbo.alldocs 
    WHERE ExtensionForFile in ('PPTX','DOCX','XLSX','PDF')
    AND TimeCreated > '$StartDate' AND TimeCreated < '$EndDate'"

    $LargestQry = "SELECT top 1 dirname,leafname,ExtensionForFile,TimeCreated,TimeLastModified,size FROM [$DB].dbo.alldocs  
    WHERE ExtensionForFile in ('pptx','docx','xlsx','pdf')
    AND TimeCreated > '$StartDate' AND TimeCreated < '$EndDate'
    order by size desc"

    $AvgQry = "SELECT avg(size) as Average FROM [$DB].dbo.alldocs 
    WHERE ExtensionForFile in ('pptx','docx','xlsx','pdf')
    AND TimeCreated > '$StartDate' AND TimeCreated < '$EndDate'"

    $doesallDocsExist = ''
    $doesallDocsExist = (Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query "SELECT count(*) as count1 from [$DB].dbo.sysobjects where name='alldocs' and xtype='U'").count1

    if ($doesallDocsExist -eq 1) {
        $AllDocsRecCount = ''
        $AllDocsRecCount = (Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query "SELECT count(*) as count1 from [$DB].dbo.alldocs where TimeCreated > '$StartDate' and TimeCreated < '$EndDate' and ExtensionForFile in ('PPTX','DOCX','XLSX','PDF')").count1

        if ($AllDocsRecCount -gt 0) {
            $total          = ''
            $average        = ''
            $largest        = ''
            $totalnum       = ''

            $largest_col1 = ''
            $largest_col2 = ''
            $largest_col3 = ''
            $largest_col4 = ''
            $largest_col5 = ''
            $largest_col6 = ''

            $total = (Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query $totalQry).Total
            $totalnum = (Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query $totalNumQry).TotalNumofDocs
            $average = (Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query $AvgQry).Average
            $largest = Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query $LargestQry

            $largest_col1 = $largest.DIRName
            $largest_col2 = $largest.LeafName
            $largest_col3 = $largest.ExtensionForFile
            $largest_col4 = $largest.TimeCreated
            $largest_col5 = $largest.TimeLastModified
            $largest_col6 = $largest.Size

            $InsertQry = ''
            $InsertQry = "INSERT INTO tempdb.dbo.tbl_AllDocsSizeInfo VALUES ('$SQLInstance','$DB','$total','$totalnum','$average','$largest_col1','$largest_col2','$largest_col3','$largest_col4','$largest_col5','$largest_col6')"
            Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query $InsertQry | Out-Null
        }
        else {
            $InsertQry2 = ''
            $InsertQry2 = "INSERT INTO tempdb.dbo.tbl_AllDocsSizeInfo (SQLInstance,DatabaseName,TotalSizeofDocs,TotalNumofDocs,AverageSizeofDocs,LargestFile_DIRName) values ('$SQLInstance','$DB','0','0','0','No Records Exist in AllDocs for the Time Range')"
            Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query $InsertQry2 | Out-Null
        }
    }
}

write-host -ForegroundColor Green "The table tempdb.dbo.tbl_AllDocsSizeInfo has the data displayed below:" 
Invoke-SQLcmd -ServerInstance $SQLInstance -QueryTimeout 60000 -Database 'master' -Query "SELECT * FROM tempdb.dbo.tbl_AllDocsSizeInfo" | Format-Table
Get-Date
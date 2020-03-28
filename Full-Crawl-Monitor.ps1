# from https://social.technet.microsoft.com/Forums/lync/en-US/784aba20-ba89-4b31-9061-e116e86cb5b6/create-report-on-full-crawl-status?forum=sharepointsearch
Add-PSSnapin Microsoft.SharePoint.Powershell -ErrorAction SilentlyContinue

$numberOfResults = 10
$contentSourceName = "Local SharePoint Sites"
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.Server.Search.Administration")
$searchServiceApplication = Get-SPEnterpriseSearchServiceApplication
$contentSources = Get-SPEnterpriseSearchCrawlContentSource -SearchApplication $searchServiceApplication
$contentSource = $contentSources | ? { $_.Name -eq $contentSourceName }
$crawlLog = new-object Microsoft.Office.Server.Search.Administration.CrawlLog($searchServiceApplication)
$crawlHistory = $crawlLog.GetCrawlHistory($numberOfResults, $contentSource.Id)
$crawlHistory.Columns.Add("CrawlTypeName", [String]::Empty.GetType()) | Out-Null

# Label the crawl type
$labeledCrawlHistory = $crawlHistory | % {
    $_.CrawlTypeName = [Microsoft.Office.Server.Search.Administration.CrawlType]::Parse([Microsoft.Office.Server.Search.Administration.CrawlType], $_.CrawlType).ToString()
    return $_
}

# Get full crawl
$labeledCrawlHistory = $labeledCrawlHistory | Where-Object { $_.CrawlTypeName -eq 'Full' }
$ReportDate = Get-Date -format "dd-MM-yyyy"

#CSS Styles for the Table
$style = "Crawl History Report: "
$style = $style + "<style>BODY{font-family: Arial; font-size: 10pt;}"
$style = $style + "TABLE{border: 1px solid black; }"
$style = $style + "TH{border: 1px solid black; background: #dddddd; padding: 5px; }"
$style = $style + "TD{border: 1px solid black; padding: 2px; }"
$style = $style + "</style>"

#Frame Email body
$EmailBody = $labeledCrawlHistory | ConvertTo-Html -Head $style

#Set Email configurations
#Get outgoing Email Server
$EmailServer = (Get-SPWebApplication -IncludeCentralAdministration | Where { $_.IsAdministrationWebApplication } ) | % { $_.outboundmailserviceinstance.server } | Select Address
$From = "<user>@<domain>.com"
$To = "<user>@<domain>.com"
$Subject = "Crawl History Report as on: " + $ReportDate
$Body = "Hi SharePoint Team,<br /><br />Here is a Crawl History report as on $ReportDate <br /><br />" + $EmailBody

#Send Email
Send-MailMessage -smtpserver $EmailServer.Address -from $from -to $to -subject $subject -body $body -BodyAsHtml
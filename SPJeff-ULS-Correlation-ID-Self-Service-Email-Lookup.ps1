# Enable power users to request ULS Correlation ID and receive email with CSV LOG detail

# Modules
Add-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction "SilentlyContinue" | Out-Null

# Configuration
$spWebUrl = "http://sp2019dev/sites/demo"
$spListRequest = "ULS Correlation ID Request"

# Open SPList
$web = Get-SPWeb $spWebUrl
$list = $web.Lists[$spListRequest]

# Loop all SPList items
foreach ($item in $list.Items) {
    # Get item values
    $id = $item["ID"]
    $requesterEmail = $item["RequesterEmail"]
    $correlationID = $item["CorrelationID"]
    $status = $item["Status"]

    # Display
    Write-Host $id -ForegroundColor "Yellow"

    # Check if status is "Requested"
    if ($status -eq "New") {
        # Update status to "Processing"
        $item["Status"] = "Processing"
        $item.Update()

        # Prepare CSV filename with today's date and time
        $stamp = Get-Date -UFormat "%Y-%m-%d-%H-%M-%S"
        $csvFileName = "ULS-Correlation-ID-$id-$stamp.csv"

        # Get ULS log entries with Merge-SPLogFileand save to CSV
        Merge-SPLogFile -Path "$($env:TEMP)\$csvFileName" -Correlation $correlationID

        # Send email using SharePoint server SMTP and from address
        # from https://sharepoint.stackexchange.com/questions/26889/how-to-access-my-outgoing-e-mail-settings-from-code
        $centralAdmin = (Get-SPWebApplication -IncludeCentralAdministration | Where-Object { $_.IsAdministrationWebApplication } ) 
        $from = $centralAdmin.OutboundMailSenderAddress
        $smtp = $centralAdmin.OutboundMailServiceInstance.Server.Address

        # Send email with CSV attachment
        $subj = "SharePoint ULS Correlation ID $correlationID"
        Send-MailMessage -To $requesterEmail -From $from -Subject $subj -Body $subj -Attachments "$($env:TEMP)\$csvFileName" -SmtpServer $smtp

        # Update status to "Completed"
        $item["Status"] = "Completed"
        $item.Update()
    }
}
# Config
$appid		= "ff5db855-5db2-4537-b057-e13f8623aaa7" 
$appsecret	= "CLIENT-SECRET-HERE"

# One year threshold for active workflow
$threshold		= -365
$thresholdDate	= (Get-Date).AddDays($threshold)


# Main
function Main {
    # Prepare CSV data collection
    $global:coll = @()

    $csv = Import-CSV "WF2010-Site-Collections.csv"
    foreach ($row in $csv) {
        InspectSite $row.URL
    }
    
    # Write CSV
    $global:coll | Export-CSV "WF2010-Report.csv" -NoTypeInformation -Force
}
# Walk site collection and all child webs
function InspectSite ($webUrl) {


    # Connect Tenant
    Write-Host $webUrl -Fore "Green"
    Connect-PNPOnline -Url $webUrl -ClientId $appid -ClientSecret $appsecret
    $ctx = Get-PNPContext

    # Loop Lists
    $lists = Get-PNPList
    foreach ($l in $lists) {

        # Collect WF Associations
        $WorkflowAssociations = $l.WorkflowAssociations
        $ctx.load($WorkflowAssociations)
        $ctx.ExecuteQuery()

        # Loop WF 2010 Associations
        foreach ($wa in $l.WorkflowAssociations) {
            # Display
            $waid = $wa.Id

            # Search WF History (dynamic)
            $listHistory = Get-PNPList $wa.HistoryListTitle

            # Enable index columns
            @("Occurred", "WorkflowAssociation") | % {
                $fieldName = $_
                $field = Get-PnPField -List $listHistory -Identity $fieldName
                if ($field.Indexed -ne 1) {
                    $field.Indexed = 1
                    $field.Update()
                    $ctx.ExecuteQuery()
                }
            }
        
            # Check WF History 
            # from https://www.sharepointdiary.com/2019/03/fix-get-pnplistitem-attempted-operation-prohibited-because-it-exceeds-list-view-threshold-enforced-by-administrator.html
            $caml = '<View><Query><OrderBy><FieldRef Name="Occurred" Ascending="FALSE" /></OrderBy><Where><Eq><FieldRef Name="WorkflowAssociation" /><Value Type="Text">{' + $waid + '}</Value></Eq></Where></Query><RowLimit>1</RowLimit></View>'

            # https://github.com/pnp/PnP-PowerShell/issues/879
            $camlQuery = New-Object "Microsoft.SharePoint.Client.CamlQuery"
            $camlQuery.ViewXml = $caml
            $result = $listHistory.GetItems($camlQuery)
            $ctx.Load($result)
            try {
                $ctx.ExecuteQuery()
            }
            catch {}

            # Format Occurred Date
            $lastRunTime = $null
            if ($result.Count) {
                $lastRunTime = $result[0].FieldValues["Occurred"]
            }

            # Display result
            if ($result) {
                if ($lastRunTime -gt $thresholdDate) {
                    # ACTIVE
                    $global:coll += [PSCustomObject]@{
                        Status      = 'ACTIVE';
                        WebURL      = $webUrl;
                        List        = $l.Title;
                        Workflow    = $wa.Name;
                        Enabled     = $wa.Enabled;
                        WFAID       = $waid;
                        LastRunTime = $lastRunTime
                    };
                }
                else {
                    # INACTIVE
                    $global:coll += [PSCustomObject]@{
                        Status      = 'INACTIVE';
                        WebURL      = $webUrl;
                        List        = $l.Title;
                        Workflow    = $wa.Name;
                        Enabled     = $wa.Enabled;
                        WFAID       = $waid;
                        LastRunTime = $lastRunTime
                    };
                }
            }
            else {
 
                # UNDETERMINED-QUERY-FAILED
                $global:coll += [PSCustomObject]@{
                    Status      = 'UNDETERMINED-QUERY-FAILED';
                    WebURL      = $webUrl;
                    List        = $l.Title;
                    Workflow    = $wa.Name;
                    Enabled     = $wa.Enabled;
                    WFAID       = $waid;
                    LastRunTime = $lastRunTime
                };


            }
            
            # ---
        }
    }
}


# Main
Start-Transcript
Main
Stop-Transcript
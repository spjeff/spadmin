# Log
Start-Transcript "WFM-Republish.log"

# Load Modules
Add-PSSnapin Microsoft.SharePoint.PowerShell
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.WorkflowServicesBase")

# Load input
$sites = Get-SPSite - Limit All
 
# Initialize Tracking
$start = Get-Date
$i = 0
$total = $sites.Count

# Main loop
foreach ($site in $sites) {

   # Display
   Write-Host $i
   Write-Host $site.Url

   # Progress Tracking
   $i++
   $prct = [Math]::Round((($i / $total) * 100.0), 2)
   $elapsed = (Get-Date) - $start
   $totalTime = ($elapsed.TotalSeconds) / ($prct / 100.0)
   $remain = $totalTime - $elapsed.TotalSeconds
   $eta = (Get-Date).AddSeconds($remain)
	
   # Display
   $file = $site.Url
   Write-Progress -Activity "RePublishing a site the ETA $eta url: $file " -Status "$prct" -PercentComplete $prct

   # Loop webs
   foreach ($web in $site.allwebs) {
      $wfm = new-object Microsoft.SharePoint.WorkflowServices.WorkflowServicesManager($web)
      $ds = $wfm.GetWorkflowDeploymentService()
      $col = $ds.EnumerateDefinitions($false)
      $wss = $wfm.GetWorkflowSubscriptionService()

      # Loop workflow definitions
      foreach ($spworkflow in $col) {
         $ds.SaveDefinition($spworkflow)
         $ds.PublishDefinition($spworkflow.Id)
         $ws = $wss.EnumerateSubscriptionsByDefinition($spworkflow.Id)
         # Publish if missing workflow subscription (WS)
         if ($ws -ne $null) {
            $wss.PublishSubscription($ws[0])
         }
      }
   }

}

# Log
Stop-Transcript
try{#add sharepoint powershell if not loaded
$ver = $host | select version
if ($ver.Version.Major -gt 1) {$host.Runspace.ThreadOptions = "ReuseThread"} 
if ((Get-PSSnapin "Microsoft.SharePoint.PowerShell" -ErrorAction SilentlyContinue) -eq $null) 
{
Write-Progress -Activity "Loading Modules" -Status "Loading Microsoft.SharePoint.PowerShell"
Add-PSSnapin "Microsoft.SharePoint.PowerShell"
Write-Progress -Activity "Loading Modules" -Status "Loading Microsoft.SharePoint.PowerShell" -Completed
}
$prodURL =	"http://your site collection url for prod";
$devURL = "http://dyour site collection url for dev";
$createNewSubSiteURL = $devURL; #swap this with $prodURL for Production or $devURL for Development
$div = "sub site"
$divFullName = "Subsite Full Name"
$webURL = $createNewSubSiteURL + "/" + $div;
#Adding content types to the Term Store
Write-Progress -Activity "Adding content types to the Term Store" -Status "Please wait..."
Write-Host "Adding content types to the Term Store" -ForegroundColor Green
$wa = Get-SPWebApplication $createNewSubSiteURL -ErrorVariable err -ErrorAction SilentlyContinue -AssignmentCollection $assignmentCollection;
$cthURL = $createNewSubSiteURL + "/" +"sites/ContentTypeHub" #content type hub
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Taxonomy") | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.Office.DocumentManagement") | Out-Null 
$web = Get-SPWeb $webURL -ErrorVariable err -ErrorAction SilentlyContinue -AssignmentCollection $assignmentCollection;
$site = Get-SPSite $cthURL -ErrorVariable err -ErrorAction SilentlyContinue -AssignmentCollection $assignmentCollection;
$AllowUnsafeUpdatesStatusSite = $site.AllowUnsafeUpdates;
$AllowUnsafeUpdatesStatusWeb = $web.AllowUnsafeUpdates;
$site.AllowUnsafeUpdates = $true;
$web.AllowUnsafeUpdates = $true;
$session = New-Object Microsoft.SharePoint.Taxonomy.TaxonomySession($site)
$termStore = $session.TermStores["Managed Metadata - Intranet"] #name of term store
$group = $termStore.Groups["Content Type Hub"]; #name of group
$checkDiv = $true;
$tsContent = $group.TermSets["Content"]; #name of term set
$contentTerms = $tsContent.GetALLTerms();
$divTerm = $contentTerms | ?{$_.Name -eq "Division"}; #name of a deeper termset
$termToAdd = $divTerm.Terms[$div]; #name of term
#check if $termToAdd already exists
if($termToAdd -eq $null){   
    $termToAdd = $divTerm.CreateTerm($div, 1033);
    $termToAdd.IsAvailableForTagging = $true;
    $termStore.CommitAll();    
    Write-Host "Adding content type" $termToAdd.Name "to the Term Store Succeeded" -ForegroundColor Green    
}
else{
    $checkDiv = $false;
    Write-Host "Adding content type" $termToAdd.Name "to the Term Store Failed. Term already exists" -ForegroundColor Red
}
function UpdateDefaultColumn($id){
    $listToSet = $web.Lists[$listItem.Title];
    $field = $listToSet.Fields["Division"];  
    $termSLCD = New-Object Microsoft.SharePoint.Taxonomy.TaxonomyFieldValue($field);
    $fieldName = $field.InternalName; 
    $wssID = $id.ToString();
    $value = $termToAdd.Name;   
    $termID = $termToAdd.ID.ToString();    
    $field.DefaultValue = $wssID + ";#" + $value + "|" + $termID;
    $field.Update();        
    If($field.DefaultValue -ne $null){          
        Write-Host "Setting Default Value to Column in" $listToSet "List Successfully" -ForegroundColor Green              
    }
    else{
        Write-Host "Failed to Set Default Value to Column in" $listToSet "List: `$columnDefaults.SetFieldDefault is FALSE" -ForegroundColor Red 
    }
}#end of function UpdateDefaultColumn 
function AddTaxonomyHiddenListItem($w)
{
      $wssid = $null; #return value
      $count = 0;     
      $l = $w.Lists["TaxonomyHiddenList"]; 
      #check if Hidden List Item already exists
      foreach($item in $l.Items){
        $xml = [xml]$item.xml;#cast the xml TaxonomyHiddenList item values
        $temID = $xml.row.ows_IdForTerm #get the IdForTerm, this is the key that unlocks all the doors
        if($temID -eq $termToAdd.ID){ #compare the IdForTerm in the TaxonomyHiddenList item to the term in the termstore
            Write-Host $item.Name "Taxonomy Hidden List Item already exists" -ForegroundColor Red
            $wssid =  $item.ID; #get and return the WSSID needed to set the default clumn value
            return $wssid;
        } 
      }
      $newListItem = $l.Items.ADD();
      $newListItem["Title"] = $termToAdd.Name;
      $newListItem["IdForTermStore"] = $termToAdd.TermStore.ID;
      $newListItem["IdForTerm"] = $termToAdd.ID;
      $newListItem["IdForTermSet"] = $termToAdd.TermSet.ID;
      $newListItem["Term"] = $termToAdd.Name;
      $newListItem["Path"] = $divTerm.Name + ":" + $termToAdd.Name;
      $newListItem["CatchAllDataLabel"] = $termToAdd.Name + "#Љ|";  #"Љ" special char
      $newListItem["Term1033"] = $termToAdd.Name;
      $newListItem["Path1033"] = $divTerm.Name + ":" + $termToAdd.Name;
      $newListItem.Update();
      foreach($item in $l.Items){
        $xml = [xml]$item.xml;
        $temID = $xml.row.ows_IdForTerm
        if($temID -eq $termToAdd.ID){
            $wssid =  $item.ID; #get and return the WSSID needed to set the default clumn value
        } 
      }     
	  return $wssid;      
}#end of function AddTaxonomyHiddenListItem
function SetListColumnDefaults(){#set the default column of lists
    #save the new Taxonomy hidden list item and get the next list item number for the field default value
    foreach ($s in $wa.Sites){
        if($s.URL -eq $createNewSubSiteURL){#Division Term, do this before Division Full name        
            $wssIDToSet = (AddTaxonomyHiddenListItem -w $s.RootWeb);
            if($wssIDToSet -ne $null){
                UpdateDefaultColumn -id $wssIDToSet;                    
            }
            else{
               #I cannot update the list Default column value
               Write-Host "Update to Default Column for List" $listToSet.Title "Failed: `$wssIDToSet returned NULL" -ForegroundColor Red 
           }
        }
    }    
}#end of SetListColumnDefaults
function SetLibraryColumnDefaults(){#to set the default column of Librarys
    $columnDefaults = New-Object Microsoft.Office.DocumentManagement.MetadataDefaults($listItem)
    #check if exists
    if($term -ne $null){
        #set Default column value       
        $field = $listItem.Fields["Division"];
        $folderPath = $listItem.RootFolder.ServerRelativeURL;    
        $fieldName = $field.InternalName;   
        $value = $term.Name;   
        $termID = $term.ID;       
        If($columnDefaults.SetFieldDefault($folderPath, $fieldName, "1033;#" + $value + "|" + $termID) -eq $true){
            $columnDefaults.Update();
            Write-Host "Setting Default Value to Column in" $listItem.Title "List Successfully" -ForegroundColor Green               
        }
        else{
            Write-Host "Failed to Set Default Value to Column in" $listItem.Title "List: `$columnDefaults.SetFieldDefault is FALSE" -ForegroundColor Red 
        }
    }
    else{
        Write-Host "Failed to Set Default Value to Column in" $listItem.Title "List:" $value "Term Does Not Exist in Term Store" -ForegroundColor Red  
    }
     
}#end of SetLibraryColumnDefaults
#get the term from the tern store again incase it has changed
$tsContent = $group.TermSets["Content"];
$contentTerms = $tsContent.GetALLTerms();
$divTerm = $contentTerms | ?{$_.Name -eq "Division"};
$term = $divTerm.Terms[$div]; 
$spListCollection = $web.Lists;
for($i = 0; $i -lt $spListCollection.Count; $i++){
    $listItem = $web.Lists[$i];    
    switch($listItem.Title){
        #calls to set the default column values for lists and librarys
        "Pages" {SetLibraryColumnDefaults;} 
        "Documents" {SetLibraryColumnDefaults;} 
        "Announcements" {SetListColumnDefaults;} 
        "Updates" {SetListColumnDefaults;}  
        "Who To Contact" {SetListColumnDefaults;}      
    };
}
#setting Full Name term in term store, specific to my need not yours but here it is
$checkDFN = $true;
$tsDFN = $group.TermSets["Division Full Name"];     
$dfnToAdd = $tsDFN.Terms[$divFullName];
If($dfnToAdd -eq $null){
    $dfnToAdd = $tsDFN.CreateTerm($divFullName, 1033); 
    $dfnToAdd.IsAvailableForTagging = $true;
    $termStore.CommitAll();
    Write-Host "Adding Full Name content type to the Term Store Succeeded" -ForegroundColor Green
}
else{
    $checkDFN = $false;
    Write-Host "Adding Full Name content type to the Term Store Failed. Term already exists" -ForegroundColor Red
}
if($checkDFN -ne $checkDiv){
    Write-Host "Division and Division Full Name content types conflict and need to be verified in the -Content Type Hub -Site Settings -Term Store Management Tool" -ForegroundColor Red
}
 
#>
}#end try
catch [system.exception]{
    Write-Host "Adding Division and Division Full Name content types. A system.exception error has occurred and the script has failed to run successfully. Error msg:"$ErrorMessage = $_.Exception.Message 
    Write-Host "Full Error Message:" $errMessageInFull = $_.Exception.ToString();
}#end of catch
finally{
#CLEAN UP
#wrap in if's for $null
if(!($AllowUnsafeUpdatesStatusSite -eq $null)){
$site.AllowUnsafeUpdates = $AllowUnsafeUpdatesStatus;
}
if(!($AllowUnsafeUpdatesStatusWeb -eq $null)){
$web.AllowUnsafeUpdates = $AllowUnsafeUpdatesStatus;
}
if(!($site -eq $null)){
$site.Dispose();
}
if(!($web -eq $null)){
$web.Dispose();
}
Write-Progress -Activity "Adding Division and Division Full Name content types to the Term Store" -Status "Please wait..." -Complete
}#end of finally for Adding Division and Division Full Name content types to the Term Store
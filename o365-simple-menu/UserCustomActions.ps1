[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client")
[System.Reflection.Assembly]::LoadWithPartialName("Microsoft.SharePoint.Client.Runtime")
 


Function Get-SPOCredentials([string]$UserName,[string]$Password)
{
   if([string]::IsNullOrEmpty($Password)) {
      $SecurePassword = Read-Host -Prompt "Enter the password" -AsSecureString 
   }
   else {
      $SecurePassword = $Password | ConvertTo-SecureString -AsPlainText -Force
   }
   return New-Object Microsoft.SharePoint.Client.SharePointOnlineCredentials($UserName, $SecurePassword)
}

 
Function Get-ActionBySequence([Microsoft.SharePoint.Client.ClientContext]$Context,[int]$Sequence)
{
     $customActions = $Context.Site.UserCustomActions
     $Context.Load($customActions)
     $Context.ExecuteQuery()
     $customActions | where { $_.Sequence -eq $Sequence }
}




Function Delete-Action([Microsoft.SharePoint.Client.UserCustomAction]$UserCustomAction)
{
     $Context = $UserCustomAction.Context
     $UserCustomAction.DeleteObject()
     $Context.ExecuteQuery()
}




Function Add-ScriptLinkAction([Microsoft.SharePoint.Client.ClientContext]$Context,[string]$ScriptSrc,[string]$ScriptBlock, [int]$Sequence)
{
    $actions = Get-ActionBySequence -Context $Context -Sequence $sequenceNo
    $actions | ForEach-Object { Delete-Action -UserCustomAction $_  } 

    $action = $Context.Site.UserCustomActions.Add();
    $action.Location = "ScriptLink"
    if($ScriptSrc) {
        $action.ScriptSrc = $ScriptSrc
    }
    if($ScriptBlock) {
        $action.ScriptBlock = $ScriptBlock
    }
    $action.Sequence = $Sequence
    $action.Update()
    $Context.ExecuteQuery()
}
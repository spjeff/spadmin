[CmdletBinding()]
param (
    [bool]$required,
    [string]$restoreFilename
)

# Module
Import-Module "SharePointPnPPowerShellOnline" -ErrorAction "SilentlyContinue" | Out-Null

# Config
$appid = "APP ID HERE"
$appsecret = "APP SECRET HERE"

function Main() {
    # Connect
    Connect-PnPOnline -Url "https://tenant.sharepoint.com/" -AppId $appid -AppSecret $appsecret 
    $ctx = Get-PnPContext
    $list = Get-PnPList "Test"
    $list

    if ($restoreFilename) {
        # ENABLE Required Fields
        $csv = Import-Csv $restoreFilename
        $fields = Get-PnPField -List $list
        foreach ($row in $csv) {
            $row.Guid
            $f = $fields | ? { $_.Id -eq $row.Guid }
            $f.Required = $true
            $f.Update()
        }
        $ctx.ExecuteQuery()
    }
    else {
        # DISABLE Required Fields
        $coll = @()
        $guid = (New-Guid).ToString()
        $fields = Get-PnPField -List $list
        foreach ($f in $fields) {
            if ($f.Required) {
                Write-Host "CHANGED FIELD $($f.Title) NOT REQUIRED"
                $f.Required = $false
                $f.Update()
                $coll += $f.Id
            }
        }
        $ctx.ExecuteQuery()
        $coll | Export-Csv "PNPToggleRequiredField-$guid.csv"
    }
}

# Main
Main
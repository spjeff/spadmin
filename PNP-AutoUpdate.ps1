# Available Modules
$module = "SharePointPnPPowerShellOnline"
$available = Find-Module $module

if ($available) {
    # Current Module
    $current = (Get-Module -ListAvailable |? {$_.Name -eq $module})
    # Compare Module Version
    if ($available.Version -gt $current.Version) {
        # Execute Module Update
        Write-Host " - UPDATE AVAILABLE" -ForegroundColor Yellow
        Remove-Item (Split-Path $current.Path) -Confirm:$false -Force
        Install-Module $module -AllowClobber -Force
    }
}
# Available Module
$module = "SharePointPnPPowerShellOnline"
$available = Find-Module $module

if ($available) {
    # Current Module
    $current = (Get-Module -ListAvailable |? {$_.Name -eq $module})
    # Compare
    if ($available.Version -gt $current.Version) {
        # Execute Update
        Write-Host " - UPDATE AVAILABLE" -ForegroundColor Yellow
        Remove-Item (Split-Path $current.Path) -Confirm:$false -Force
        Install-Module $module -AllowClobber -Force
    }
}
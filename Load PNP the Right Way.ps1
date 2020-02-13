# Load PNP the Right Way
$pnp = Get-Command Connect-PnPOnline -ErrorAction SilentlyContinue
if (!$pnp) {Install-Module SharePointPnPPowerShellOnline -Force}
Import-Module SharePointPnPPowerShellOnline
# from https://www.spjeff.com/2020/03/04/practical-powershell-logs/
<#
.NOTES  
	File Name:  Practical-PowerShell-LOG.ps1
	Author   :  Jeff Jones  - @spjeff
	Author   :  Todd Klindt  - @ToddKlindt
	Version  :  1.0
	Modified :  2020-03-04

.LINK
	http://localhost
#>

[CmdletBinding()]
param ()

function Main() {
    ### YOUR CODE HERE
}

# Open Log
$prefix = $MyInvocation.MyCommand.Name
$stamp = Get-Date -UFormat "%Y-%m-%d-%H-%M-%S"
Start-Transcript "$PSScriptRoot\log\$prefix-$stamp.log"
$start = Get-Date

Main

# Close Log
$end = Get-Date
$totaltime = $end - $start
Write-Host "`nTime Elapsed: $($totaltime.tostring("hh\:mm\:ss"))"
Stop-Transcript
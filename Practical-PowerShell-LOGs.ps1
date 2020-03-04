# from https://www.spjeff.com/2020/03/04/practical-powershell-logs/
<#
.NOTES  
	File Name:  Practical-PowerShell-LOG.ps1
	Author   :  Jeff Jones  - @spjeff
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
$stamp = (Get-Date).tostring().replace("/", "-").replace(":", "-")
Start-Transcript "$PSScriptRoot\log\$prefix-$stamp.log"
$start = Get-Date

Main

# Close Log
$elapsed = (Get-Date) – $start
$elapsed
Stop-Transcript
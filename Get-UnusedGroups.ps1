<# 

from https://devblogs.microsoft.com/scripting/hey-scripting-guy-how-can-i-use-windows-powershell-2-0-to-find-active-directory-domain-services-groups-not-being-used/

.Synopsis 
Queries Active Directory for groups that are unused. It will remove 
unused groups, or simply report. In addition, it can create empty 
groups for test purposes  
.Example 
Get-UnusedGroups.ps1 -CreateGroups -path "ou=testou,dc=nwtraders,dc=com" `
-numberGroups 5 
Creates 5 empty global groups in the TestOU of nwtraders.com. Groups will  
be named test1, test2 … test5  
.Example 
Get-UnusedGroups.ps1 -CreateGroups -path "ou=testou,dc=nwtraders,dc=com" `
-numberGroups 5 -SearchBase "ou=testou,dc=nwtraders,dc=com" 
Creates 5 em
pty global groups in the TestOU of nwtraders.com. Groups will  
be named test1, test2 … test5. It then searches the testou in nwtraders.com 
for empty groups and produces a report. 
.Example 
Get-UnusedGroups.ps1 -searchBase "ou=testou,dc=nwtraders,dc=com" -remove 
Searches the testou in nwtraders.com for groups with no members. If these 
are found they will be removed. A report is produced of groups found, but  
no bogus groups are created.  
.Parameter numberGroups 
The number of groups to be created if the -createGroups switch is used 
.Parameter CreateGroups 
Causes script to create groups. Must be used with numberGroups and path. 
.Parameter path 
Location of bogus groups to be created. Must be used with numberGroups 
and CreateGroups. 
.Parameter SearchBase 
Location to search for empty groups. 
.Parameter remove 
Causes script to remove empty groups. Uses SearchBase parameter. 
.Inputs 
[psobject] 
.Outputs 
[psobject] 
.Notes 
NAME: Get-UnusedGroups.ps1 
AUTHOR: Ed Wilson 
AUTHOR BOOK: Windows PowerShell 2.0 Best Practices, Microsoft Press 2010 
LASTEDIT: 7/19/2010 
HSG: hsg-07-22-10 
KEYWORDS: Active Directory, Groups 
.Link 
Http://www.ScriptingGuys.com 
Http://www.bit.ly/HSGBlog 
#> 
#Requires -Version 2.0 
Param( 
    [int16]$numberGroups, 
    [switch]$CreateGroups, 
    [string]$path,  
    [string]$searchBase, 
    [switch]$remove 
) #end param 
Function Get-MyModule { 
    Param([string]$name) 
    if (-not(Get-Module -name $name)) {  
        if (Get-Module -ListAvailable |  
            Where-Object { $_.name -eq $name }) {  
            Import-Module -Name $name  
            $true 
        } #end if module available then import 
        else { $false } #module not available 
    } # end if not module 
    else { $true } #module already loaded 
} #end function get-MyModule  
Function New-BogusTestGroups { 
    [CmdletBinding()] 
    Param( 
        [Parameter(Mandatory = $True)] 
        [int16]$numberGroups, 
        [Parameter(Mandatory = $True)] 
        [string]$path 
    ) 
    1..$numberGroups |  
    ForEach-Object { New-ADGroup -name "test$_" -groupScope global -path $path } 
    $numberGroups = $path = $null 
} #end function New-BogusTestGroups 
Function Get-UnusedGroups { 
    [CmdletBinding()] 
    Param( 
        [Parameter(Mandatory = $True)] 
        [string]$searchBase 
    ) 
    Get-ADGroup -Filter * -Properties members, isCriticalSystemObject `
        -SearchBase $searchBase |  
    Where-Object { ($_.members.count -eq 0 -AND !($_.IsCriticalSystemObject) `
                -AND $_.DistinguishedName -notMatch ‘Exchange Security’ -AND `
                $_.DistinguishedName -notMatch ‘Dns’) 
    } 
    $searchBase = $null 
} #end function Get-UnusedGroups 
Function Remove-UnusedGroups { 
    $input | 
    Remove-ADGroup  
} #end function remove-unusedGroups 
Function Format-Output {
    $input | 
    Sort-Object -Property groupscope |  
    Format-Table -Property groupscope, name, distinguishedName -AutoSize -Wrap 
} # end function format-output 
# *** Entry point to script *** 
If (-not (Get-MyModule -name "ActiveDirectory")) { exit } 
if ($CreateGroups) { New-BogusTestGroups -numberGroups $numberGroups -path $path } 
If ($searchBase) { Get-UnusedGroups -SearchBase $searchBase | Format-Output } 
if ($remove) { Get-UnusedGroups -SearchBase $searchBase | Remove-UnusedGroups }


Function New-BogusTestGroups {

    [CmdletBinding()]

    Param(

        [Parameter(Mandatory = $True)]

        [int16]$numberGroups,

        [Parameter(Mandatory = $True)]

        [string]$path

    )

    1..$numberGroups | 

    ForEach-Object { New-ADGroup -name "test$_" -groupScope global -path $path }

    $numberGroups = $path = $null

} #end function New-BogusTestGroups


Function Get-UnusedGroups { 
    [CmdletBinding()] 
    Param( 
        [Parameter(Mandatory = $True)] 
        [string]$searchBase 
    ) 
    Get-ADGroup -Filter * -Properties members, isCriticalSystemObject `
        -SearchBase $searchBase |  
    Where-Object { ($_.members.count -eq 0 -AND !($_.IsCriticalSystemObject) `
                -AND $_.DistinguishedName -notMatch ‘Exchange Security’ -AND `
                $_.DistinguishedName -notMatch ‘Dns’) 
    } 
    $searchBase = $null 
} #end function Get-UnusedGroups

If ($searchBase) { Get-UnusedGroups -SearchBase $searchBase | Format-Output }

 
Function Format-Output {
    $input | 
    Sort-Object -Property groupscope |  
    Format-Table -Property groupscope, name, distinguishedName -AutoSize -Wrap 
} # end function format-output

 
Function Remove-UnusedGroups { 
    $input | 
    Remove-ADGroup  
} #end function remove-unusedGroups

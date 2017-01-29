<#
.SYNOPSIS
	Lookup user details from Active Directory with memory DataTable cache
	
.DESCRIPTION
	Given a filter value, the function will query Active Directory to find a matching user object. 
	By default "samAccountName" is used for query.  Optional field name can be provided to filter
	by any field such as Manager, Mail, or DN.
	
.NOTES
	File Name		: LookupADUser.ps1
	Author			: Jeff Jones - @spjeff
	Version			: 0.10
	Last Modified	: 01-29-2017
	
.LINK
	http://www.github.com/spjeff/spadmin/LookupADUser.ps1
#>

# DataTable cache
$cacheUsers = New-Object System.Data.DataTable("users")
$cols = @("DistinguishedName","Enabled","extensionAttribute4","Manager","Name","Mail","SamAccountName")
foreach ($col in $cols) {
    $cacheUsers.Columns.Add($col) | Out-Null
}


# Find user by any field
Function lookupADUser ($login, $optFieldName) {
    # Filter 
    $dv = New-Object System.Data.DataView($cacheUsers)
    $filter = "SamAccountName = '$login'"
    if ($optFieldName) {
        $filter = $filter.Replace("SamAccountName", $optFieldName)
    }
    $dv.RowFilter = $filter

    # Return from cache
    if ($dv.Count -gt 0) {
        # Found
        return $dv
    } else {
        # Insert
        $cmd = "SamAccountName -eq '$login'"
        if ($optFieldName) {
            $cmd = $cmd.Replace("SamAccountName", $optFieldName)
        }
        $sb = [Scriptblock]::Create($cmd)
        $user = Get-ADUser -Filter $sb -Properties extensionAttribute4,manager,enabled,Mail
        if ($user) {
            $row = $cacheUsers.NewRow()
            foreach ($col in $cols) {
                $row[$col] = $user.$col
            }
            $cacheUsers.Rows.Add($row) | Out-Null
            return $dv
        } else {
            return $null
        }
    }
}


# Search by userID
$sb = {lookupADUser "userID"}
Measure-Command $sb | Format-Table

# Search by Email
$sb = {lookupADUser "first_last@company.com" "Mail"}
Measure-Command $sb | Format-Table

# Search by DN
$sb = {lookupADUser "CN=First Last,OU=Regular,OU=Accounts,DC=company,DC=com" "DistinguishedName"}
Measure-Command $sb | Format-Table
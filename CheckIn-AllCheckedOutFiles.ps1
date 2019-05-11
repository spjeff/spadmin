Add-PSSnapin Microsoft.SharePoint.PowerShell -ErrorAction SilentlyContinue

Function CheckIn-AllCheckedOutFiles()
{  
    #Define 'Web Application URL' as Mandatory Parameter
    Param( 
    [Parameter(Mandatory=$true)] [string]$WebAppURL,
    [Parameter(Mandatory=$true)] [string]$ReportOutput
    )

    #Get the Web Application
    $WebApp = Get-SPWebApplication $WebAppURL

    #Write the CSV Header - Tab Separated
    "Site Collection Name `t Site Name`t Library `t File Name `t File URL `t  Last Modified `t Checked-Out By" | Out-file $ReportOutput

    #Arry to Skip System Lists and Libraries
    $SystemLists =@("Converted Forms", "Master Page Gallery", "Customized Reports", "Form Templates", "List Template Gallery", "Theme Gallery", 
           "Reporting Templates", "Solution Gallery", "Style Library", "Web Part Gallery","Site Assets", "wfpub")

    #Loop through each site collection
    ForEach($Site in $WebApp.Sites)
    {
        #Loop through each site in the site collection
        ForEach($Web in $Site.AllWebs)
        {
            Write-host "Processing Site:" $web.Url
            #Loop through each document library
            Foreach ($List in $Web.GetListsOfType([Microsoft.SharePoint.SPBaseType]::DocumentLibrary))
            {
                #Get only Document Libraries & Exclude Hidden System libraries
                if ( ($List.Hidden -eq $false) -and ($SystemLists -notcontains $List.Title) )
                {
                    #Loop through each Item
                    foreach ($ListItem in $List.Items) 
                    {
                        If( ($ListItem.File.CheckOutStatus -ne "None") -and ($ListItem.File.CheckedOutByUser -ne $null))
                        {
                            #Log the data to a CSV file
                            "$($Site.RootWeb.Title) `t $($Web.Title) `t $($List.Title) `t $($ListItem.Name) `t $($Web.Url)/$($ListItem.Url) `t  $($ListItem['Modified'].ToString()) `t  $($ListItem.File.CheckedOutByUser)" | Out-File $ReportOutput -Append
                            Write-host -f Yellow "Found a Checked out file at: $($Web.Url)/$($ListItem.Url)"

                            #Check in the file
                            $ListItem.File.Checkin("Checked in by Administrator")
                        }
                    }
                }
            }
        }
    }

    #Send message to output console
    write-host -f Green "Checked out Files Report Generated Successfully!"
}

#Call the Function to Get Checked-Out Files and check them in
CheckIn-AllCheckedOutFiles -WebAppURL "http://mbnet.mbfinancial.com" -ReportOutput "C:\Temp\CheckedOutFiles.txt"
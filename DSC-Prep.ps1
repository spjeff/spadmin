$cd = @{
    AllNodes = @(    
        @{ 
            NodeName = "localhost"
            PsDscAllowPlainTextPassword=$true
			PsDscAllowDomainUser=$true
			RebootNodeIfNeeded = $true
        }
    ) 
}
 
Example -ConfigurationData $cd

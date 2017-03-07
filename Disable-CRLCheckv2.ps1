# from http://joelblogs.co.uk/2011/09/20/certificate-revocation-list-check-and-sharepoint-2010-without-an-internet-connection/

#the following statement goes on one line
Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing" -Name State -Value 146944

#the following statement goes on one line also
Set-ItemProperty -Path "REGISTRY::\HKEY_USERS\.Default\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing" -Name State -Value 146944

Get-ChildItem REGISTRY::HKEY_USERS |% {
    Set-ItemProperty -ErrorAction SilentlyContinue -Path ($_.Name + "\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing")  -Name State -Value 146944
}

Write-Host -ForegroundColor White " - Disabling Certificate Revocation List (CRL) check..."
ForEach ($bitsize in ("","64")) {			
    $xml = [xml](Get-Content "$env:windir\Microsoft.NET\Framework$bitsize\v2.0.50727\CONFIG\Machine.config")
    If (!$xml.DocumentElement.SelectSingleNode("runtime")) { 
        $runtime = $xml.CreateElement("runtime")
        $xml.DocumentElement.AppendChild($runtime) | Out-Null
    }
    If (!$xml.DocumentElement.SelectSingleNode("runtime/generatePublisherEvidence")) {
        $gpe = $xml.CreateElement("generatePublisherEvidence")
        $xml.DocumentElement.SelectSingleNode("runtime").AppendChild($gpe)  | Out-Null
    }
    $xml.DocumentElement.SelectSingleNode("runtime/generatePublisherEvidence").SetAttribute("enabled", "false")  | Out-Null
    $xml.Save("$env:windir\Microsoft.NET\Framework$bitsize\v2.0.50727\CONFIG\Machine.config")
}

# from https://social.technet.microsoft.com/Forums/lync/en-US/119e92b5-a5a1-4769-bb93-f2f01e91fcde/event-id-8321-crl-checking-on-sharepoint-2013?forum=sharepointadmin
$rootCert = (Get-SPCertificateAuthority).RootCertificate 
New-SPTrustedRootAuthority -Name "localNew" -Certificate $rootCert

# MANUAL - Disable the automatic update of root certificates on the SharePoint Servers via Local Group Policy Editor.
# Option 5 at https://blogs.msdn.microsoft.com/chaun/2014/05/01/best-practices-for-crl-checking-on-sharepoint-servers/
# --------------------
# SECTION 1
# --------------------
# Interactive login
Import-Module AzureAD
Connect-AzureAD
$users = Get-AzureADUser 
$users | Ft -a


# --------------------
# SECTION 2
# --------------------
# Registration
# Login to Azure AD PowerShell With Admin Account
Connect-AzureAD 
    
# Create the self signed cert
$currentDate = Get-Date
$endDate = $currentDate.AddYears(1)
$notAfter = $endDate.AddYears(1)
$pwd = "pass@word1"
$domain = "SPOProfileSync.spjeff.com"
$thumb = (New-SelfSignedCertificate -CertStoreLocation cert:\localmachine\my -DnsName $domain -KeyExportPolicy Exportable -Provider "Microsoft Enhanced RSA and AES Cryptographic Provider" -NotAfter $notAfter).Thumbprint


$pwd = ConvertTo-SecureString -String $pwd -Force -AsPlainText
Export-PfxCertificate -cert "cert:\localmachine\my\$thumb" -FilePath c:\code\SPJeffDev\SPOProfileSync.pfx -Password $pwd
    
# Load the certificate
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate("C:\code\SPJeffDev\SPOProfileSync.pfx", $pwd)
$keyValue = [System.Convert]::ToBase64String($cert.GetRawCertData())
    
    
# Create the Azure Active Directory Application
$application = New-AzureADApplication -DisplayName "SPOProfileSync" -IdentifierUris $domain
New-AzureADApplicationKeyCredential -ObjectId $application.ObjectId -CustomKeyIdentifier "SPOProfileSync" -StartDate $currentDate -EndDate $endDate -Type AsymmetricX509Cert -Usage Verify -Value $keyValue
    
# Create the Service Principal and connect it to the Application
$sp=New-AzureADServicePrincipal -AppId $application.AppId
    
# Give the Service Principal Reader access to the current tenant (Get-AzureADDirectoryRole)
$roleId = (Get-AzureADDirectoryRole |? {$_.DisplayName -eq "Directory Readers"}).ObjectId
Add-AzureADDirectoryRoleMember -ObjectId $roleId -RefObjectId $sp.ObjectId
    
# Get Tenant Detail
$tenant=Get-AzureADTenantDetail
# Now you can login to Azure PowerShell with your Service Principal and Certificate
Connect-AzureAD -TenantId $tenant.ObjectId -ApplicationId  $sp.AppId -CertificateThumbprint $thumb


# --------------------
# SECTION 3
# --------------------
# Unattend automation
$tenantId = "1766f4f7-6afc-45b7-926e-3525d63edab3"
$appId = "466a9807-91a1-4bf5-a5b2-6993a774fae7"
$thumb = "cd04e6c84d0fd978f6d5b6a2fcef715689e1ec04"
Connect-AzureAD -TenantId $tenantId -ApplicationId  $appId -CertificateThumbprint $thumb
$users = Get-AzureADUser 
$users | Ft -a
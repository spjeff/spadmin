# from https://spinsiders.com/brianlala/2014/04/30/autospinstaller-for-specific-config-changes/
[xml]$xmlinput = (Get-Content "D:\AutoSPInstaller\Automation\AutoSPInstaller.xml") -replace "localhost", $env:COMPUTERNAME
Import-Module -Name ".\AutoSPInstallerModule.psm1" -Verbose
CreateEnterpriseSearchServiceApp $xmlinput

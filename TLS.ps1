# https://4sysops.com/archives/disable-ssl-and-tls-1-01-1-on-iis-with-powershell/
<#

.\TLS.ps1 -Proto TLS10 -Target Client -Action Enable
.\TLS.ps1 -Proto TLS11 -Target Client -Action Enable
.\TLS.ps1 -Proto TLS12 -Target Client -Action Enable
.\TLS.ps1 -Proto SSL30 -Target Client -Action Enable
.\TLS.ps1 -Proto TLS10 -Target Server -Action Enable
.\TLS.ps1 -Proto TLS11 -Target Server -Action Enable
.\TLS.ps1 -Proto TLS12 -Target Server -Action Enable
.\TLS.ps1 -Proto SSL30 -Target Server -Action Enable
#>
[CmdletBinding()]
Param(
   [Parameter(Mandatory = $False)]
   [ValidateSet("SSL30", "TLS10", "TLS11", "TLS12")]
   [string]$Proto,
   [ValidateSet("Client", "Server")]
   [string]$Target,
   [Parameter(Mandatory = $False)]
   [ValidateSet("Enable", "Disable")]
   $Action)

Function CheckKey {
   param(
      [string]$Proto
   )
   $RegKey = $null

   switch ($Proto) {
      SSL30 { $RegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0" }
      TLS10 { $RegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0" }
      TLS11 { $RegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1" }
      TLS12 { $RegKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2" }
      default {
         "Not supported protocol. Possible values: SSL30, TLS10, TLS11, TLS12"
         exit
      }
   }
   return $Regkey
}
if ($Proto) {
   $RegKey = CheckKey -Proto $Proto
}
[string[]]$TargetKey = $null
if (!($Target)) {
   Write-Host "Setting up both Client and Server protocols"
   $TargetKey = $(Join-Path $RegKey "Client").ToString()
   $TargetKey += $(Join-Path $RegKey "Server").ToString()
   if (!(Test-path -Path $TargetKey[0])) {
      New-Item $TargetKey[0] -Force
   }
   if (!(Test-path -Path $TargetKey[1])) {
      New-Item $TargetKey[1] -Force
   }
} 
else {
   Write-Host "Setting up $Target protocols"
   $TargetKey = $(Join-Path $RegKey $Target).ToString()
   if (!(Test-path -Path $(Join-Path $RegKey $Target))) {
      New-Item $TargetKey -Force   
   }
}

Function SetProto {
   param(

      [string[]]$TargetKey,
      [string]$Action
   )

   foreach ($key in  $TargetKey) {
      try {
         Get-ItemProperty -Path $key -Name "Enabled" -ErrorAction Stop | Out-Null
         if ($Action -eq "Disable") {
            Write-Host "`t`Updating $key"                     
            Set-ItemProperty -Path $key -Name "Enabled" -Value 0 -Type "DWord"
         }
         else {
            Write-Host "`t`Updating $key"
            Set-ItemProperty -Path $key -Name "Enabled" -Value 1 -Type "DWord"
         }
      }
      Catch [System.Management.Automation.PSArgumentException] {
         if ($Action -eq "Disable") {
            Write-Host "`t`Creating $key"
            New-ItemProperty -Path $key -Name "Enabled" -Value 0 -PropertyType "DWord"
         }
         else {
            Write-Host "`t`Creating $key"
            New-ItemProperty -Path $key -Name "Enabled" -Value 1 -PropertyType "DWord"
         }
      }

      try {
         Get-ItemProperty -Path $key -Name "DisabledByDefault" -ErrorAction Stop | Out-Null
         if ($Action -eq "Disable") {
            Write-Host "`t`Updating $key"
            Set-ItemProperty -Path $key -Name "DisabledByDefault" -Value 1 -Type "DWord"
         }
         else {
            Write-Host "`t`Updating $key"
            Set-ItemProperty -Path $key -Name "DisabledByDefault" -Value 0 -Type "DWord"
         }
      }
      Catch [System.Management.Automation.PSArgumentException] {
         if ($Action -eq "Disable") {
            Write-Host "`t`Creating $key"
            New-ItemProperty -Path $key -Name "DisabledByDefault" -Value 1 -PropertyType "DWord"
         }
         else {
            Write-Host "`t`Creating $key"
            New-ItemProperty -Path $key -Name "DisabledByDefault" -Value 0 -PropertyType "DWord"
         }
      }
   }
}

if ($TargetKey -and $Action) {
   SetProto -TargetKey $TargetKey -Action $Action
   Write-Host "The operation completed successfully, reboot is required" -ForegroundColor Green
} else {
   # Keys
   $keys = @("HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0",
   "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0",
   "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.1",
   "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.2")

   # Read Only Display
   foreach ($key in $keys) {
      $key
      Get-ItemProperty -Path $key -Name "DisabledByDefault"
      Get-ItemProperty -Path $key -Name "Enabled"
   }
}
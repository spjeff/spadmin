# Run PowerShell window as Admin and Different User
Start-Process powershell.exe -Credential "domain\user" -NoNewWindow -ArgumentList "Start-Process powershell.exe -Verb runAs"
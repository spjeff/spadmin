$myshell = New-Object -ComObject wscript.shell;
$minutes = 120
for ($i = 0; $i -lt $minutes; $i++) {
  Start-Sleep -Seconds 60
  $myshell.sendkeys(&quot;.&quot;)
}
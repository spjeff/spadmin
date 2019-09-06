# Simulate keyboard input to bypass screen saver lock

$shell = New-Object -ComObject wscript.shell;
while (1) {
    Start-Sleep 60
    $shell.SendKeys(".")
}
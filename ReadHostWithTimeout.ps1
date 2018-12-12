function Read-HostWithTimeout {
    <#
    .SYNOPSIS
    A half-baked Read-Host that takes a -Timeout parameter

    .DESCRIPTION
    An unholy union of $ost.UI.RawUI.ReadKey() and Read-Host.  It is usable, but that's good enough for my current needs.

    Here are the limitations I've hit so far:

    - Keyboard buffer doesn't.  If you type too fast, the second (or more) character(s) will be lost.
    
    - Keyboard buffer is not contiguious.  The first character is captured by ReadKey(), and the rest by Read-Host.  This means up-arrow will only show the characters captured by Read-Host.

    - This also means you can't back up over the first character.

    Still, all I need is a Y/N with a timeout, and that works.

    .PARAMETER Prompt
    Prompt for input.  Will have a ': ' appended, but no linefeed.

    .PARAMETER Timeout
    Seconds to wait for input.  If no input received, will return $null.  If the -NoNewLine parameter is not specified, once the user starts typing, the timeout is suspended until the user presses [Enter].

    .PARAMETER NoNewLine
    Return first key pressed, do not wait for user to press [Enter].

    .NOTES
    Who         What        When        Why
    timdunn     V0.1        2014-01-27  I'm not ready to even call this beta-quality.

    #>

    param (
        [string]$Prompt = $null,
        [int]$Timeout = 10,
        [switch]$NoNewLine
    );

    if ($Timeout -le 0)
    {
        Write-Warning "$($MyInvocation.MyCommand.Name) -Timeout '$Timeout' less than or equal to 0.  Stopping.";
        return;

    } # if ($Timeout -le 0)

    $key = $null;
    
    if ($Prompt)
    {
        Write-Host "${Prompt}: " -NoNewline;

    } # if ($Prompt)

    $end = (Get-Date) + (New-TimeSpan -Seconds $Timeout);

    while (((Get-Date) -lt $end) -and !$key)
    {
        if ($host.ui.RawUI.KeyAvailable)
        {
            $key = $host.UI.RawUI.ReadKey("NoEcho, IncludeKeyUp").Character;
            break;

        } # if ($host.ui.RawUI.KeyAvailable)

        Start-Sleep -Milliseconds 50;

    } # while ((Get-Date) -lt $end)

    if ($key -eq $null)
    {
        return;

    } # if (!$key)

    if (!$NoNewLine)
    {
        Write-Host -NoNewline $key;
        $key += Read-Host;

    } # if (!$NoNewLine)

    $key;

} # function Read-HostWithTimeout 
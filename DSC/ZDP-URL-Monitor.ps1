# ZDP, Zero Downtime Patching - URL Monitor
"Time,HTTP,SPRequestDuration" | Out-File "ZDP-URL-Results.csv"

# Invoke HTTP and parse response
Function CheckURL($url) {
    # Test HTTP and return
    $response = 0
    try {
        $iwr = Invoke-WebRequest $url -UseDefaultCredentials -TimeoutSec 5
        $response = $iwr.StatusCode
        if ($url -eq "http://portal") {
            $global:header = $iwr.Headers["SPRequestDuration"]
        }
    }
    catch {
        $response = $_.Exception.Message
    }
    return $response
}

# Main loop
while ($true) {
    # Display
    Write-Host "." -NoNewline
    Start-Sleep 1

    # Responses
    $respa = CheckURL "http://portal"
    $respb = CheckURL "http://10.0.0.9"
    $respc = CheckURL "http://10.0.0.10"

    # Append CSV
    "{0},{1},{2},{3},{4}" -f (Get-Date), $resa, $global:header, $resb, $resc | Out-File "ZDP-URL-Results.csv" -Append
}
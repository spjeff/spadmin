# From GitHub repo at https://github.com/spjeff/spadmin

# From YouTube video at 

# List process and format as table
$proc = Get-Process
$proc | Format-Table @{
    # Add column "Name" to table
    Label = "Name"
    Expression = {
        if ($_.Name -eq "chrome") {
            # Format row color Green when Name is "chrome"
            $color = "32" # Green
        } else {
            # Format row color Red when Name is not "chrome"
            $color = "31" # Red
        }

        # Character 27 is ESC
        $e = [char]27

        # Format row with name and color
        "$e[${color}m$($_.Name)$e[0m"
    }
}, PID, CPU, PM, WS, VM, NPM, Path -AutoSize

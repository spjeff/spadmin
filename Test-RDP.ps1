# Test RDP connectivity from https://www.angryadmin.co.uk/?p=415
param(
     [parameter(Mandatory=$true,ValueFromPipeline=$true)][string[]]$computername
     )
$results = @()
foreach($name in $computername){

        $result = "" | select Name,RDP
        $result.name = $name

        try{
           $socket = New-Object Net.Sockets.TcpClient($name, 3389)
           if($socket -eq $null){
                 $result.RDP = $false
           }else{
                 $result.RDP = $true
                 $socket.close()
           }
        }
        catch{
                 $result.RDP = $false
        }
        $results += $result
}
return $results
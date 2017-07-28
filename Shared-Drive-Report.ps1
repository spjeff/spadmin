# Generate detailed CSV Excel report of individual files on a shared network folder

Start-Transcript

$folder = "\\SERVER\SHARED_FOLDER_HERE"
$files = gci $folder -Recurse
Summary $files "ALL"

$files = $files |? {$_.Length -gt 2*1024*1024}
Summary $files "LARGE"

Function Summary($files, $name) {
	$storage = ($files | Measure Length -Sum).Sum/1MB
	Write-Host "Total Files = " $files.Count
	Write-Host ("Total Storage (MB) = {0:N2}" -f $storage)
	Write-Host "By Extension"
	$ext = $files | group Extension | sort Count -Desc
	$ext | ft -a
	$ext | Export-Csv "Shared-Drive-Report-$name.csv"
}

Stop-Transcript
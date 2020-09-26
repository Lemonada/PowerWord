$file_hash_table = @{}


function Get-Closed-Handels{
    param (
        $paths
    )
    $paths_to_send = New-Object System.Collections.Generic.List[System.Object]
    $keys_to_remove = New-Object System.Collections.Generic.List[System.Object]
    if ($null -eq $paths) {
        $keys_to_remove += $file_hash_table.Keys
        Send-Log -LogString "paths are empty so no more handels"
        $paths_to_send += $file_hash_table.Keys
    }
    else {
        Foreach ($skey in $file_hash_table.Keys){
            if ($paths.Contains($skey)){
                Send-Log -LogString "$skey in the Hashtable"
            }
            else {
                if ((Get-Item $skey).LastWriteTime -ne $file_hash_table[$skey]){
                    Send-Log -LogString "$skey not the Hashtable, that means handle closed !"
                    Send-Log -LogString "File Changed, adding to paths to sync: $path"
                    $paths_to_send += $skey
                }
                else {
                    Send-Log -LogString "File not in hash but didnt change so im not sending back"
                }
                $keys_to_remove.Add($skey)
            }
        }
    }
    if ($keys_to_remove.Count -ne 0){
        Foreach ($rkey in $keys_to_remove){
            $file_hash_table.Remove($rkey)
        }
    }
    return $paths_to_send
}
function Compare-HashTable{
    param (
        $paths
    )
    $paths_to_send = New-Object System.Collections.Generic.List[System.Object]
    $paths_to_send += Get-Closed-Handels -paths $paths
    Foreach ($path in $paths)
    {

        if ($file_hash_table.ContainsKey($path)){
            if (($LiveMode) -And ((Get-Item $path).LastWriteTime -ne $file_hash_table[$path])){
                Send-Log -LogString "File Changed, adding to paths to sync: $path"
                $file_hash_table[$path] = (Get-Item $path).LastWriteTime
                $paths_to_send += $path
            }
            else {
                Send-Log -LogString "File Didnt Change: $path"
            }
        }
        else {
            Send-Log -LogString "File Doesnt exists in hashtable, so its new: $path"
            $file_hash_table.Add($path, (Get-Item $path).LastWriteTime)
            $paths_to_send += $path
        }
    }
    return $paths_to_send

}





function Start-Mon {
    param (
        [string]$ProcID = 9999999,
        [string[]]$FILE_EXTENTIONS = $WordFileExtentions,
        [int]$TIMER_CONST = $LiveModeInterval
    ) 
    Send-Log -LogString "New process created with PID: $ProcID"
    $word_alive = $True
    While  ($word_alive){
        $ProcessActive = Get-Process -Id $ProcID -ErrorAction SilentlyContinue
        if($null -eq $ProcessActive){
            Send-Log -LogString "Winword proc died, This is my last time."
            $word_alive = $false
        }
        $paths = Get-FileHandles
        if (($null -ne $paths) -Or ($file_hash_table.Count -ne 0)){
            $paths_to_send = Compare-HashTable -paths $paths
            Send-Log -LogString "These are the files to send back: $paths_to_send"
        }
        else {
            Send-Log -LogString "Hmm seems like no handles found"
        }
        Send-Data -Paths $paths_to_send
    Start-Sleep -Seconds $TIMER_CONST
    } 

    
}

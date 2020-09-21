param (
    [string]$ProcID = 9999999,
    [string[]]$FILE_EXTENTIONS =@('docx','txt'),
    [string]$HANDLES_LOCATION = "D:\SysinternalsSuite\handle.exe",
    [int]$TIMER_CONST = 5
)   

$REGEX = "File          (.*\.{0})"
$file_hash_table = @{}


function Send-Files{
    param (
        $file_path
    )
    Write-host "sending file bla bla $file_path"
}

function Get-Closed-Handels{
    param (
        $paths
    )
    $paths_to_send = New-Object System.Collections.Generic.List[System.Object]
    $keys_to_remove = New-Object System.Collections.Generic.List[System.Object]
    if ($null -eq $paths) {
        $keys_to_remove += $file_hash_table.Keys
        Write-Host "paths are empty so no more handels"
        $paths_to_send += $file_hash_table.Keys
    }
    else {
        Foreach ($skey in $file_hash_table.Keys){
            if ($paths.Contains($skey)){
                Write-Host "$skey in the Hashtable"
            }
            else {
                if ((Get-Item $skey).LastWriteTime -ne $file_hash_table[$skey]){
                    Write-Host "$skey not the Hashtable, that means handle closed !"
                    Write-host "File Changed, adding to paths to sync: $path"
                    $paths_to_send += $skey
                }
                else {
                    Write-Host "File not in hash but didnt change so im not sending back"
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
        #if (Test-Path -Path $path){
        #    Write-host "Cant find path: $path, continue"
        #    continue
        #}

        if ($file_hash_table.ContainsKey($path)){
            if ((Get-Item $path).LastWriteTime -ne $file_hash_table[$path]){
                Write-host "File Changed, adding to paths to sync: $path"
                $file_hash_table[$path] = (Get-Item $path).LastWriteTime
                $paths_to_send += $path
            }
            else {
                Write-host "File Didnt Change: $path"
            }
        }
        else {
            Write-host "File Doesnt exists in hashtable, so its new: $path"
            $file_hash_table.Add($path, (Get-Item $path).LastWriteTime)
            $paths_to_send += $path
        }
    }
    return $paths_to_send

}

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
    $handels = New-Object System.Collections.Generic.List[System.Object]
    $handels_raw = Invoke-Expression -Command "$HANDLES_LOCATION -nobanner -p $ProcID"
        Foreach ($extention in $FILE_EXTENTIONS)
        {
            #Write-host "Searching for extention: $extention"
            $full_regex = $REGEX -f $extention
            $handels += $handels_raw | Select-String -Pattern $full_regex
        }
    return $handels
}



function Start-Mon {
    Write-host "Proc id is : $ProcID"
    $word_alive = $True
    While  ($word_alive){
        $ProcessActive = Get-Process -Id $ProcID -ErrorAction SilentlyContinue
        if($null -eq $ProcessActive){
            Write-host "DEad"
            $word_alive = $false
        }
        $handles_list_raw = Get-FileHandles
        if (($null -ne $handles_list_raw) -Or ($file_hash_table.Count -ne 0)){
            $paths = Get-Paths -handle_list $handles_list_raw
            $paths_to_send = Compare-HashTable -paths $paths
            Write-Host "These are the files to send back: $paths_to_send"
            .\Sender.ps1 -Paths $paths_to_send
        }
        else {
            Write-Host "Hmm seems like no handles found"
        }
    Start-Sleep -Seconds $TIMER_CONST          
    } 
}


Start-Mon
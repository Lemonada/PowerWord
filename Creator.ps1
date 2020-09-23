function Create-Listener{
    Send-Log -LogString "Started listener"
    #exit
    $Query = "Select * From __InstanceCreationEvent within 5 Where TargetInstance ISA 'Win32_Process'"
    $Identifier = "StartProcess"
    $ActionBlock = {
        $e = $event.SourceEventArgs.NewEvent.TargetInstance
        if ($e.Name -eq "winword.exe"){
            Start-Mon -ProcID $e.ProcessID
        }
    }

    Register-WMIEvent -Query $Query -SourceIdentifier $Identifier -Action $ActionBlock
}

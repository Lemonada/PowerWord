




$Query = "Select * From __InstanceCreationEvent within 5 Where TargetInstance ISA 'Win32_Process'"
$Identifier = "StartProcess"
$ActionBlock = {
    $e = $event.SourceEventArgs.NewEvent.TargetInstance
    if ($e.Name -eq "winword.exe"){
        write-host ("Process {0} with PID {1} has started" -f $e.Name, $e.ProcessID)
        write-host ($e | Get-Member)
        write-host ("handle", $e.Handle)
        write-host ("HandleCount", $e.HandleCount)
        write-host ("CommandLine", $e.CommandLine)
        .\Monitor.ps1 -ProcID $e.ProcessID

    }
}

Register-WMIEvent -Query $Query -SourceIdentifier $Identifier -Action $ActionBlock


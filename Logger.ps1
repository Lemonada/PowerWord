function Send-Log{
    param (
        $LogString
    )
    switch ($LogLocation) {
        stdout {
             Write-Host $LogString
             }
        local {
            try {
                Out-File -FilePath $LogPath -InputObject $LogString -Append
            }
            catch {
                Write-Host "Error Writing to local file"
                Exit
            }
        }
        remote{
            $Body = @{
                date = get-date
                cname = hostname
                log = $LogString
            }
            try {
                $output = Invoke-RestMethod -Method "Post" -Uri $LogPath -Body $body   
            }
            catch {
                Write-Host "Unable to contact remote log path"
                Exit
            }
        }
        Default {
            Write-Host "Error displaying log, make sure flag exists"
            Exit
        }
    }
}
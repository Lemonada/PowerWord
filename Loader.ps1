param (
    [string]$LogLocation = "stdout", # Remote/Local/stdout
    [string]$LogPath, # Only if Remote or Local is enabled
    [string]$Mode = "Live", # Live / Handle Close
    [string]$LiveModeInterval = 5, # Every x seconds to sync data, only in live mode
    [string]$CommunicationMethod = "smb", # smb / remote transfer
    [string]$Remote = '127.0.0.1:1337', # Only when using remote transfer
    [string]$HandelsMethod = "handels", # handels / openfiles / code
    [string]$HandlesExeMethod = "local", # To download on scripts load or to use base64 local
    [string]$HandlesExePath = "D:\SysinternalsSuite\handle.exe", # Path to save and use handles exe from.
    [string]$WordFileExtentions =@('docx','txt'),
    [string]$LoadFromRemote = "No", # To download and run from memory, or use builtin payload
    [string]$RemoteLoadPath = "", # From where to download the Payload

    [string]$HandlePaylod = "abcd",
    [string]$CreatorPayload = "abcd"

) 
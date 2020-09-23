Add-Type "
using System;
using System.Runtime.InteropServices;

    public static class NtDll
    {
        [DllImport(`"ntdll.dll`")]
        public static extern NT_STATUS NtQueryObject(
            [In] IntPtr Handle,
            [In] OBJECT_INFORMATION_CLASS ObjectInformationClass,
            [In] IntPtr ObjectInformation,
            [In] int ObjectInformationLength,
            [Out] out int ReturnLength);

        [DllImport(`"ntdll.dll`")]
        public static extern NT_STATUS NtQuerySystemInformation(
            [In] SYSTEM_INFORMATION_CLASS SystemInformationClass,
            [In] IntPtr SystemInformation,
            [In] int SystemInformationLength,
            [Out] out int ReturnLength);
    }

	public static class Kernel32
	{
	        [DllImport(`"kernel32.dll`", SetLastError = true)]
			public static extern IntPtr OpenProcess(
            [In] int dwDesiredAccess,
            [In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            [In] int dwProcessId);

        [DllImport(`"kernel32.dll`", SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        public static extern bool DuplicateHandle(
            [In] IntPtr hSourceProcessHandle,
            [In] IntPtr hSourceHandle,
            [In] IntPtr hTargetProcessHandle,
            [Out] out IntPtr lpTargetHandle,
            [In] int dwDesiredAccess,
            [In, MarshalAs(UnmanagedType.Bool)] bool bInheritHandle,
            [In] int dwOptions);

		[DllImport(`"kernel32.dll`", SetLastError = true)]
			public static extern uint QueryDosDevice(string lpDeviceName, System.Text.StringBuilder lpTargetPath, int ucchMax);
	}

	[StructLayout(LayoutKind.Sequential)]
    public struct SystemHandleEntry
    {
        public int OwnerProcessId;
        public byte ObjectTypeNumber;
        public byte Flags;
        public ushort Handle;
        public IntPtr Object;
        public int GrantedAccess;
    }

	public enum SYSTEM_INFORMATION_CLASS
    {
        SystemBasicInformation = 0,
        SystemPerformanceInformation = 2,
        SystemTimeOfDayInformation = 3,
        SystemProcessInformation = 5,
        SystemProcessorPerformanceInformation = 8,
        SystemHandleInformation = 16,
        SystemInterruptInformation = 23,
        SystemExceptionInformation = 33,
        SystemRegistryQuotaInformation = 37,
        SystemLookasideInformation = 45
    }

	public enum OBJECT_INFORMATION_CLASS
    {
        ObjectBasicInformation = 0,
        ObjectNameInformation = 1,
        ObjectTypeInformation = 2,
        ObjectAllTypesInformation = 3,
        ObjectHandleInformation = 4
    }

	public enum NT_STATUS
    {
        STATUS_SUCCESS = 0x00000000,
        STATUS_BUFFER_OVERFLOW = unchecked((int)0x80000005L),
        STATUS_INFO_LENGTH_MISMATCH = unchecked((int)0xC0000004L)
    }
"
function ConvertTo-RegularFileName
{
	param(
        $RawFileName
    )

    foreach ($logicalDrive in [Environment]::GetLogicalDrives())
    {
        $targetPath = New-Object System.Text.StringBuilder 256
        if ([Kernel32]::QueryDosDevice($logicalDrive.Substring(0, 2), $targetPath, 256) -eq 0)
        {
            $targetPath
            return $targetPath
        }
        $targetPathString = $targetPath.ToString()
        if ($RawFileName.StartsWith($targetPathString))
        {
            $RawFileName = $RawFileName.Replace($targetPathString, $logicalDrive.Substring(0, 2))
            break
        }
    }
    return $RawFileName
}


function ConvertTo-HandleHashTable
{
	param(
		[Parameter(Mandatory, ValueFromPipeline=$true)]
		[SystemHandleEntry]$HandleEntry
    )
    
    #if ($HandleEntry.GrantedAccess -eq 0x0012019f -or $HandleEntry.GrantedAccess -eq 0x00120189 -or $HandleEntry.GrantedAccess -eq 0x120089)
    #{
    #	return
    #}

    $sourceProcessHandle = [IntPtr]::Zero
    $handleDuplicate = [IntPtr]::Zero
    $sourceProcessHandle = [Kernel32]::OpenProcess(0x40, $true, $HandleEntry.OwnerProcessId)

    if (-not [Kernel32]::DuplicateHandle($sourceProcessHandle, [IntPtr]$HandleEntry.Handle, (Get-Process -Id $Pid).Handle, [ref]$handleDuplicate, 0, $false, 2))
    {
        return
    }

    $length = 0
    [NtDll]::NtQueryObject($handleDuplicate, [OBJECT_INFORMATION_CLASS]::ObjectNameInformation, [IntPtr]::Zero, 0, [ref]$length) | Out-Null
    $ptr = [IntPtr]::Zero

    $ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($length)
    if ([NtDll]::NtQueryObject($handleDuplicate, [OBJECT_INFORMATION_CLASS]::ObjectNameInformation, $ptr, $length, [ref]$length) -ne [NT_STATUS]::STATUS_SUCCESS)
    {
        return;
    }
    $Path = [System.Runtime.InteropServices.Marshal]::PtrToStringUni([IntPtr]([long]$ptr+ 2 * [IntPtr]::Size))

    [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
    [PSCustomObject]@{
        Path=(ConvertTo-RegularFileName $Path);
    }

}


function Get-FileHandle-Monit-Script
{
    param(
        $ProcId
    )
    $length = 0x10000
    $ptr = [IntPtr]::Zero
    try
    {
        while ($true)
        {
            $ptr = [System.Runtime.InteropServices.Marshal]::AllocHGlobal($length)
            $wantedLength = 0
			$SystemHandleInformation = 16
            $result = [NtDll]::NtQuerySystemInformation($SystemHandleInformation, $ptr, $length, [ref] $wantedLength)
            if ($result -eq [NT_STATUS]::STATUS_INFO_LENGTH_MISMATCH)
            {
                $length = [Math]::Max($length, $wantedLength)
                [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
                $ptr = [IntPtr]::Zero
            }
            elseif ($result -eq [NT_STATUS]::STATUS_SUCCESS)
			{
                break
			}
            else
			{
                throw (New-Object System.ComponentModel.Win32Exception)
			}
        }

		if ([IntPtr]::Size -eq 4)
		{
			$handleCount = [System.Runtime.InteropServices.Marshal]::ReadInt32($ptr)
		}
		else
		{
			$handleCount = [System.Runtime.InteropServices.Marshal]::ReadInt64($ptr)
		}

		$offset = [IntPtr]::Size
		$She = New-Object -TypeName SystemHandleEntry
        $size = [System.Runtime.InteropServices.Marshal]::SizeOf($She)
        $handles = New-Object System.Collections.Generic.List[System.Object]
        for ($i = 0; $i -lt $handleCount; $i++)
        {
            $FileHandle = [SystemHandleEntry][System.Runtime.InteropServices.Marshal]::PtrToStructure([IntPtr]([long]$ptr + $offset),[Type]$She.GetType())
            if ($FileHandle.OwnerProcessId -eq $ProcId)
            {
                if ($FileHandle.ObjectTypeNumber -eq 37){
                    
                    $handles += $FileHandle | ConvertTo-HandleHashTable
                }
            }
			
            $offset += $size
        }
        return $handles
    }
    finally
    {
        if ($ptr -ne [IntPtr]::Zero)
		{
            [System.Runtime.InteropServices.Marshal]::FreeHGlobal($ptr)
		}
    }
    
}

Get-FileHandle-Monit-Script -ProcId 5244
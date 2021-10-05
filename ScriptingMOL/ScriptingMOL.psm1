function Get-MachineInfo {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [Alias('CN', 'MachineName', 'Name')]
        [string[]]$ComputerName,
        
        [string]$LogFailuresToPath,
        
        [ValidateSet('Wsman', 'Dcom')]
        [string]$Protocol = "Wsman",
        
        [switch]$ProtocolFallback
    )
    
BEGIN {}

PROCESS {
    foreach ($computer in $ComputerName) {

        if ($Protocol -eq 'Dcom') {
            $cimSessionOption = New-CimSessionOption -Protocol Dcom
        }
        else {
            $cimSessionOption = New-CimSessionOption -Protocol Wsman
        }

        Write-Verbose "Connecting to $computer over $Protocol"
        $cimSession = New-CimSession -SessionOption $cimSessionOption -ComputerName $computer

        Write-Verbose "Querying data from $computer"
        $os_params = @{
            ClassName = 'Win32_OperatingSystem'
            CimSession = $cimSession
        }
        $os = Get-CimInstance @os_params

        $cs_params = @{
            ClassName  = 'Win32_ComputerSystem'
            CimSession = $cimSession
        }
        $cs = Get-CimInstance @cs_params
        $systemDrive = $os.SystemDrive

        $drive_params = @{
            ClassName = 'Win32_LogicalDisk'
            CimSession = $cimSession
            Filter = "DeviceId='$systemDrive'"
        }
        $drive = Get-CimInstance @drive_params

        $proc_params = @{
            ClassName = 'Win32_Processor'
            CimSession = $cimSession
        }
        $proc = Get-CimInstance @proc_params | Select-Object -First 1

        Write-Verbose "Closing session to $computer"
        $cimSession | Remove-CimSession

        Write-Verbose "Output data for $computer"
        $props = @{
            ComputerName = $computer
            OSVersion = $os.Version
            SPVersion = $os.ServicePackMajorVersion
            OSBuild = $os.BuildNumber
            Manufacturer = $cs.Manufacturer
            Model = $cs.Model
            Procs = $cs.NumberOfProcessors
            Cores = $cs.NumberOfLogicalProcessors
            RAM = ($cs.TotalPhysicalMemory / 1GB)
            Architecture = $proc.AddressWidth
            SystemDriveFreeSpace = ($drive.FreeSpace / 1GB)
        }
        $obj = New-Object -TypeName PSObject -Property $props
        Write-Output $obj
    }
}

END {}

}
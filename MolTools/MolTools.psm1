function Set-TMServiceLogon {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [string[]]$ComputerName,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$ServiceName,
        
        [Parameter(ValueFromPipelineByPropertyName = $true)]
        [string]$NewUser,
        
        [Parameter(Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [string]$NewPassword,
        
        [string]$ErrorLogFilePath
    )
    
BEGIN {}

PROCESS {
    foreach ($computer in $ComputerName) {
        # Establish CIM session protocol
        $cimSessionOptions = New-CimSessionOption -Protocol Wsman
        
        # Connect CIM session
        $cimSession = New-CimSession -SessionOption $cimSessionOptions -ComputerName $computer

        # Define arguments for Invoke-CimMethod
        if ($PSBoundParameters.ContainsKey('NewUser')) {
            $arguments = @{'StartName'=$NewUser;'StartPassword'=$NewPassword}
        }
        else {
            $arguments = @{'StartPassword'=$NewPassword}
        }

        # Change service login
        $result_params = @{
            Query = "SELECT * FROM Win32_Service WHERE Name='$ServiceName'"
            MethodName = 'Change'
            Arguments = $arguments
            CimSession = $cimSession
        }
        $result = Invoke-CimMethod @result_params

        switch ($result.ReturnValue) {
            0 { $returnStatus = 'Success' }
            22 { $returnStatus = 'Invalid Account' }
            Default { $returnStatus = "Failed: $($result.ReturnValue)"}
        }

        # Close session
        $cimSession | Remove-CimSession

        # Output data
        $props = @{
            ComputerName = $computer
            Status = $returnStatus
        }

        $obj = New-Object -TypeName PSObject -Property $props
        Write-Output $obj
    }
}

END {}

}
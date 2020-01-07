function Install-DbsAudit {
    <#
    .SYNOPSIS
        Installs the supplemental SQL Server Audit provided by DISA

    .DESCRIPTION


    .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Name
        The name of the audit and audit specification. Defaults to DISA's default of DISA_STIG.

    .PARAMETER Path
        The path where the audit files will be created. Defaults to default data directory + STIG. Creates the directory if it does not exist.

    .PARAMETER MaxSize
        The max size of each audit file. Defaults to 10MB.

    .PARAMETER MaxFiles
        The max number of files to keep. Defaults to 50.

    .PARAMETER Reserve
        Sets the reserve of disk space. Defaults to OFF.

    .PARAMETER QueueDelay
        Sets the queue delay of the audit. Defaults to 1000.

    .PARAMETER OnFailure
        Instructs SQL Server of what to do on failure. Defaults to SHUTDOWN. Options include 'FAIL_OPERATION', 'SHUTDOWN', 'CONTINUE'.

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER Force
        If this switch is enabled, the sp_WhoisActive will be downloaded from the internet even if previously cached.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: DISA, STIG
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2010 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MITl


    .EXAMPLE
        PS C:\> Install-DbsAudit -SqlInstance sql2017, sql2016, sql2012

        Detect version and create appropriate audit from DISA, output to DATA\Stig\, shutdown on failure

    .EXAMPLE
        PS C:\> Install-DbsAudit -SqlInstance sql2017 -SqlCredential sqladmin -Path C:\temp -OnFaiure Continue

        Login as sqladmin, detect version and create appropriate audit from DISA, output to C:\temp, continue on failure

    .EXAMPLE
        PS C:\> Get-DbaRegServer -SqlInstance sqlcentral | Install-DbaDisaStigAudit

        Installs disa stig on all servers on the CMS
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [string]$Name = "DISA_STIG",
        [string]$Path,
        [string]$MaxSize = "10 MB",
        [string]$MaxFiles = "50",
        [string]$Reserve = "OFF",
        [string]$QueueDelay = "1000",
        [ValidateSet('FAIL_OPERATION', 'SHUTDOWN', 'CONTINUE')]
        [string]$OnFailure = "SHUTDOWN",
        [switch]$EnableException
    )

    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $sqlcredential -MinimumVersion 11
            } catch {
                Stop-Function -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }
            try {
                switch ($server.VersionMajor) {
                    11 {
                        $sqlfile = "$script:ModuleRoot\bin\sql\Audit2012.sql"
                    }
                    12 {
                        $sqlfile = "$script:ModuleRoot\bin\sql\Audit2014.sql"
                    }
                    default {
                        $MaxSize = $MaxSize.Replace(" MB", "")
                        $MaxSize = $MaxSize.Replace("MB", "")
                        $sqlfile = "$script:ModuleRoot\bin\sql\Audit2016.sql"
                    }
                }

                if (-not $PSBoundParameters.Path) {
                    $Path = (Get-DbaDefaultPath -SqlInstance $server).Data
                    $Path = "$Path\STIG"
                    if (-not (Test-DbaPath -SqlInstance $server -Path $Path)) {
                        $null = New-DbaDirectory -SqlInstance $server -Path $Path -EnableException
                    }
                }

                $sql = [IO.File]::ReadAllText($sqlfile)
                $sql = $sql -replace 'USE master', ''
                $sql = $sql -replace '--AUDITNAME--', $Name
                $sql = $sql -replace '--AUDITLOCATION--', $Path
                $sql = $sql -replace '--AUDITMAXSIZE--', $MaxSize
                $sql = $sql -replace '--AUDITMAXFILES--', $MaxFiles
                $sql = $sql -replace '--AUDITRESERVE--', $Reserve
                $sql = $sql -replace '--AUDITQUEUEDELAY--', $QueueDelay
                $sql = $sql -replace '--AUDITONFAILURE--', $OnFailure
                $sql = $sql -replace '<server audit spec name>', "$Name"

                #return $sql
                $batches = $sql -split "\bGO\b"


                if ($PSCmdlet.ShouldProcess($instance, "Installing $sqlfile on $instance to $Path")) {
                    foreach ($batch in $batches) {
                        $server.Query($batch)
                    }

                    [PSCustomObject]@{
                        ComputerName = $server.ComputerName
                        InstanceName = $server.ServiceName
                        SqlInstance  = $server.DomainInstanceName
                        Name         = "DISA STIG"
                        Status       = "Success"
                        Path         = $Path
                    }
                }
            } catch {
                Stop-Function -Message "Failed to install stored procedure." -ErrorRecord $_ -Continue -Target $instance
            }
        }
    }
}
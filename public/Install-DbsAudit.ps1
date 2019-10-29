function Install-DbsAudit {
    <#
    .SYNOPSIS
        Automatically installs or updates sp_WhoisActive by Adam Machanic.

    .DESCRIPTION
        This command downloads, extracts and installs sp_WhoisActive with Adam's permission. To read more about sp_WhoisActive, please visit http://whoisactive.com and http://sqlblog.com/blogs/adam_machanic/archive/tags/who+is+active/default.aspx

        Please consider donating to Adam if you find this stored procedure helpful: http://tinyurl.com/WhoIsActiveDonate

        Note that you will be prompted a bunch of times to confirm an action.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2005 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

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

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Install-DbaDisaStigAudit

    .EXAMPLE
        PS C:\> Install-DbaDisaStigAudit -SqlInstance sqlserver2014a -Database master

        Downloads sp_WhoisActive from the internet and installs to sqlserver2014a's master database. Connects to SQL Server using Windows Authentication.

    .EXAMPLE
        PS C:\> Install-DbaDisaStigAudit -SqlInstance sqlserver2014a -SqlCredential $cred

        Pops up a dialog box asking which database on sqlserver2014a you want to install the procedure into. Connects to SQL Server using SQL Authentication.

    .EXAMPLE
        PS C:\> Install-DbaDisaStigAudit -SqlInstance sqlserver2014a -Database master -LocalFile c:\SQLAdmin\whoisactive_install.sql

        Installs sp_WhoisActive to sqlserver2014a's master database from the local file whoisactive_install.sql

    .EXAMPLE
        PS C:\> $instances = Get-DbaRegServer sqlserver
        PS C:\> Install-DbaDisaStigAudit -SqlInstance $instances -Database master

        Installs sp_WhoisActive to all servers within CMS
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
                $server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $sqlcredential
            } catch {
                Stop-Function -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }
            if ($PSCmdlet.ShouldProcess($instance, "Installing Audit")) {
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

                    Write-Message -Level Verbose -Message "Using $sqlfile on $instance."

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
                    $batches = $sql -split "GO\r\n"

                    foreach ($batch in $batches) {
                        $server.Query($batch)
                    }

                    [PSCustomObject]@{
                        ComputerName = $server.ComputerName
                        InstanceName = $server.ServiceName
                        SqlInstance  = $server.DomainInstanceName
                        Name         = "DISA STIG"
                        Status       = "Success"
                    }
                } catch {
                    Stop-Function -Message "Failed to install stored procedure." -ErrorRecord $_ -Continue -Target $instance
                }
            }
        }
    }
}
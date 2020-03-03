function Get-DbsTraceFlag {
    <#
    .SYNOPSIS
        Checks both startup params and trace flags to see if trace flag 3625 is set. Returns non-compliant computers.

    .DESCRIPTION
        Checks to see if trace flag 3625 to hide system information form non-sysadmins in error messages.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target _SQL Server_ instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

    .PARAMETER Credential
         Login to the target _Windows Server_ using alternative credentials. Accepts PowerShell credentials (Get-Credential).

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79097, V-79217
        Author: Tracy Boggiano (@TracyBoggiano), databasesuperhero.com

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsTraceFlag -SqlInstance sql2017, sql2016, sql2012

        Gets trace flag on servers.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [PsCredential]$Credential,
        [switch]$EnableException
    )
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $startupflags = (Get-DbaStartupParameter -SqlInstance $instance -EnableException).TraceFlags.Split(",")
                $startupflag = $startupflags -contains 3625
                $traceflags = Get-DbaTraceFlag -TraceFlag 3625 -SqlInstance $instance -EnableException *>$null

                if ($startupflag -and -not $traceflags) {
                    Write-PSFMessage -Level Warning -Message "Startup parameter for trace flag 3625 has already been set in $instance, but the SQL service needs to be restarted for it to take effect"
                }

                if (-not $traceflags -and -not $startupflag) {
                    [PSCustomObject]@{
                        SqlInstance = $instance
                        Compliant   = $false
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $instance" -ErrorRecord $_ -Continue
            }
        }
    }
}
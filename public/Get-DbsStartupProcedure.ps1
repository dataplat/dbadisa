function Get-DbsStartupProcedure {
    <#
    .SYNOPSIS
        Gets a list of startup procedures

    .DESCRIPTION
        Gets a list of startup procedures

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79321
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsStartupProcedure -SqlInstance sql2017, sql2016, sql2012

        Gets a list of startup procedures for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsStartupProcedure -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\startupproc.csv -NoTypeInformation

        Exports a list of startup procedures for all databases on sql2017, sql2016 and sql2012 to D:\disa\startupproc.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance
                $server.Query("SELECT @@SERVERNAME as SqlInstance, Name
                            From sys.procedures
                            Where OBJECTPROPERTY(OBJECT_ID, 'ExecIsStartup') = 1")
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
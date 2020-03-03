function Get-DbsCustomXp {
    <#
    .SYNOPSIS
        Returns a list non-standard extended procedures

    .DESCRIPTION
        Returns a list non-standard extended procedures

    .PARAMETER SqlInstance
        The target SQL Server instance or instances Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79181
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsCustomXp -SqlInstance sql2017, sql2016, sql2012

        Returns a list non-standard extended procedures for sql2017, sql2016 and sql2012
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                # $server.Databases.ExtendedStoredProcedures.DllLocation
                $server = Connect-DbaInstance -SqlInstance $instance
                $server.Query("DECLARE @xplist AS TABLE
                            (
                            xp_name sysname,
                            source_dll nvarchar(255)
                            )
                            INSERT INTO @xplist
                            EXEC sp_helpextendedproc

                            SELECT @@SERVERNAME as SqlInstance, X.xp_name as Name,
                            X.source_dll as SourceDll, O.is_ms_shipped as IsSystem
                            FROM @xplist X JOIN sys.all_objects O
                            ON X.xp_name = O.name
                            WHERE O.is_ms_shipped = 0
                            ORDER BY X.xp_name")
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
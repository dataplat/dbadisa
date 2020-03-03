function Get-DbsXpPermission {
    <#
    .SYNOPSIS
        Gets a list of registry extended stored procedure permissions.

    .DESCRIPTION
        Gets a list of registry extended stored procedure permissions.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79327
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsXpPermission -SqlInstance sql2017, sql2016, sql2012

        Gets a list of registry extended stored procedure permissions for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsXpPermission -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\instanceperms.csv -NoTypeInformation

        Exports a list of registry extended stored procedure permissions for all databases on sql2017, sql2016 and sql2012 to D:\disa\instanceperms.csv
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
                $server = Connect-DbaInstance -SqlInstance $instance
                $server.Query("SELECT @@SERVERNAME as SqlInstance, OBJECT_NAME(major_id) AS [StoredProcedure]
                            ,dpr.NAME AS [Principal]
                            FROM sys.database_permissions AS dp
                            INNER JOIN sys.database_principals AS dpr ON dp.grantee_principal_id = dpr.principal_id
                            WHERE major_id IN (
                            OBJECT_ID('xp_regaddmultistring')
                            ,OBJECT_ID('xp_regdeletekey')
                            ,OBJECT_ID('xp_regdeletevalue')
                            ,OBJECT_ID('xp_regenumvalues')
                            ,OBJECT_ID('xp_regenumkeys')
                            ,OBJECT_ID('xp_regremovemultistring')
                            ,OBJECT_ID('xp_regwrite')
                            ,OBJECT_ID('xp_instance_regaddmultistring')
                            ,OBJECT_ID('xp_instance_regdeletekey')
                            ,OBJECT_ID('xp_instance_regdeletevalue')
                            ,OBJECT_ID('xp_instance_regenumkeys')
                            ,OBJECT_ID('xp_instance_regenumvalues')
                            ,OBJECT_ID('xp_instance_regremovemultistring')
                            ,OBJECT_ID('xp_instance_regwrite')
                            )
                            AND dp.[type] = 'EX'
                            ORDER BY dpr.NAME")
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
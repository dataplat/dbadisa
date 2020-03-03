function Get-DbsDbObjectOwner {
    <#
    .SYNOPSIS
        Returns SQL Server accounts that own database objects. These users are presumed to be authorized.

    .DESCRIPTION
        Returns SQL Server accounts that own database objects. These users are presumed to be authorized.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbaDatabase

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79079
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbObjectOwner -SqlInstance sql2017, sql2016, sql2012

        Gets SQL Server accounts that own database objects for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbObjectOwner -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\dbobjowners.csv -NoTypeInformation

        Gets SQL Server accounts that own database objects for sql2017, sql2016 and sql2012 to D:\disa\dbobjowners.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
        $sql = ";with objects_cte as
                (SELECT
                o.Name, o.type_desc as Type,
                CASE
                WHEN o.principal_id is null then s.principal_id
                ELSE o.principal_id
                END as principal_id
                FROM sys.objects o
                INNER JOIN sys.schemas s
                ON o.schema_id = s.schema_id
                WHERE o.is_ms_shipped = 0
                )
                SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database],
                cte.Name, dp.name as Owner, cte.Type
                FROM objects_cte cte
                INNER JOIN sys.database_principals dp
                ON cte.principal_id = dp.principal_id
                ORDER BY dp.Name, cte.Type"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Connect-DbaInstance -SqlInstance $SqlInstance | Where-Object VersionMajor -gt 11 | Get-DbaDatabase
        }

        foreach ($db in $InputObject) {
            try {
                $db.Query($sql)
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
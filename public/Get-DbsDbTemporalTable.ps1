function Get-DbsDbTemporalTable {
    <#
    .SYNOPSIS
        Gets all of the temporal tables in the database

    .DESCRIPTION
        Gets all of the temporal tables in the database

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbaDatabase

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79069
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbTemporalTable -SqlInstance sql2017, sql2016, sql2012

        Gets all of the temporal tables in all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbTemporalTable -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\temporal.csv -NoTypeInformation

        Gets all of the temporal tables in all databases on sql2017, sql2016 and sql2012 to D:\disa\temporal.csv
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
        $sql = "SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database],
        SCHEMA_NAME(T.schema_id) AS [Schema], T.name AS [Table],
        T.temporal_type_desc as TemporalTypeDescription, SCHEMA_NAME(H.schema_id) as HistorySchema,
        H.name AS HistoryTable FROM sys.tables T
        JOIN sys.tables H ON T.history_table_id = H.object_id
        WHERE T.temporal_type != 0
        ORDER BY [Schema], [Table]"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential | Where-Object VersionMajor -gt 11 | Get-DbaDatabase -EnableException:$EnableException
        }

        foreach ($db in $InputObject) {
            try {
                $db.Query($sql) | Select-Object -Property SqlInstance, Database, Schema, Table, TemporalTypeDescription, HistorySchema, HistoryTable, @{ Name = 'db'; Expression = { $db } } |
                Select-DefaultView -Property SqlInstance, Database, Schema, Table, TemporalTypeDescription, HistorySchema, HistoryTable
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
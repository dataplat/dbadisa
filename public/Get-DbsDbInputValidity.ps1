function Get-DbsDbInputValidity {
    <#
    .SYNOPSIS
        Returns a list of all input validations

    .DESCRIPTION
        Returns a list of all input validations

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
        Tags: V-79095
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbInputValidity -SqlInstance sql2017, sql2016, sql2012

        Returns a list of all input validations

    .EXAMPLE
        PS C:\> Get-DbsDbInputValidity -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\checks.csv -NoTypeInformation

        Exports input validation for all databases on sql2017, sql2016 and sql2012 to D:\disa\checks.csv
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
        $constraintsql = "select @@SERVERNAME as SqlInstance, DB_NAME() as [Database], SchemaName, TableView,
                            [Type],
                            ConstraintType,
                            ConstraintName
                        from (
                            select schema_name(t.schema_id) as SchemaName, t.[name] as TableView,
                                case when t.[type] = 'U' then 'Table'
                                    when t.[type] = 'V' then 'View'
                                    end as [Type],
                                case when c.[type] = 'PK' then 'Primary key'
                                    when c.[type] = 'UQ' then 'Unique constraint'
                                    when i.[type] = 1 then 'Unique clustered index'
                                    when i.type = 2 then 'Unique index'
                                    end as ConstraintType,
                                isnull(c.[name], i.[name]) as ConstraintName,
                                substring(column_names, 1, len(column_names)-1) as [details]
                            from sys.objects t
                                left outer join sys.indexes i
                                    on t.object_id = i.object_id
                                left outer join sys.key_constraints c
                                    on i.object_id = c.parent_object_id
                                    and i.index_id = c.unique_index_id
                            cross apply (select col.[name] + ', '
                                                from sys.index_columns ic
                                                    inner join sys.columns col
                                                        on ic.object_id = col.object_id
                                                        and ic.column_id = col.column_id
                                                where ic.object_id = t.object_id
                                                    and ic.index_id = i.index_id
                                                        order by col.column_id
                                                        for xml path ('') ) D (column_names)
                            where is_unique = 1
                            and t.is_ms_shipped <> 1
                            union all
                            select schema_name(fk_tab.schema_id), fk_tab.name as foreign_table,
                                'Table',
                                'Foreign key',
                                fk.name as fk_ConstraintName,
                                schema_name(pk_tab.schema_id) + '.' + pk_tab.name
                            from sys.foreign_keys fk
                                inner join sys.tables fk_tab
                                    on fk_tab.object_id = fk.parent_object_id
                                inner join sys.tables pk_tab
                                    on pk_tab.object_id = fk.referenced_object_id
                                inner join sys.foreign_key_columns fk_cols
                                    on fk_cols.constraint_object_id = fk.object_id
                            union all
                            select schema_name(t.schema_id), t.[name],
                                'Table',
                                'Check constraint',
                                con.[name] as ConstraintName,
                                con.[definition]
                            from sys.check_constraints con
                                left outer join sys.objects t
                                    on con.parent_object_id = t.object_id
                                left outer join sys.all_columns col
                                    on con.parent_column_id = col.column_id
                                    and con.parent_object_id = col.object_id
                            union all
                            select schema_name(t.schema_id), t.[name],
                                'Table',
                                'Default constraint',
                                con.[name],
                                col.[name] + ' = ' + con.[definition]
                            from sys.default_constraints con
                                left outer join sys.objects t
                                    on con.parent_object_id = t.object_id
                                left outer join sys.all_columns col
                                    on con.parent_column_id = col.column_id
                                    and con.parent_object_id = col.object_id) a
                        order by TableView, ConstraintType, ConstraintName"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -EnableException:$EnableException -ExcludeSystem
        }

        foreach ($db in $InputObject) {
            Write-PSFMessage -Level Verbose -Message "Processing $($db.Name) on $($db.Parent.Name)"
            $db.Query($constraintsql)
        }
    }
}
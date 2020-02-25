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
        $tablesql = "select tab.[name] from sys.tables tab"

        $pksql = "select
                    pk.[name] as pk_name,
                    tab.[name] as table_name
                    from sys.tables tab
                    inner join sys.indexes pk
                    on tab.object_id = pk.object_id
                    and pk.is_primary_key = 1"

        $fksql = "SELECT  obj.name AS Name,
                    tab1.name AS TableName,
                    col1.name AS ColumnName
                    FROM sys.foreign_key_columns fkc
                    INNER JOIN sys.objects obj
                        ON obj.object_id = fkc.constraint_object_id
                    INNER JOIN sys.tables tab1
                        ON tab1.object_id = fkc.parent_object_id
                    INNER JOIN sys.columns col1
                        ON col1.column_id = parent_column_id AND col1.object_id = tab1.object_id"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -EnableException:$EnableException -ExcludeSystem
        }

        foreach ($db in $InputObject) {
            Write-PSFMessage -Level Verbose -Message "Processing $($db.Name) on $($db.Parent.Name)"
            $tables = $db.Query($tablesql)
            $tablecount = @($tables).Count

            foreach ($table in $tables) {
                Write-PSFMessage -Level Verbose -Message "Processing checks in $($table.Name) on $($db.Name) on $($db.Parent.Name)"
                foreach ($check in $table.Checks) {
                    [pscustomobject]@{
                        SqlInstance = $db.SqlInstance
                        Database    = $db.Name
                        TableCount  = $tablecount
                        Table       = $table.Name
                        Check       = $check.Name
                        Type        = "Constraint"
                    } | Select-DefaultView -Property SqlInstance, Database, Table, Check, Type
                }
                Write-PSFMessage -Level Verbose -Message "Processing primary keys in $($table.Name) on $($db.Name) on $($db.Parent.Name)"
                foreach ($index in ($table.Indexes | Where-Object IndexKeyType -eq DriPrimaryKey)) {
                    [pscustomobject]@{
                        SqlInstance = $db.SqlInstance
                        Database    = $db.Name
                        TableCount  = $tablecount
                        Table       = $table.Name
                        Check       = $index.Name
                        Type        = "PrimaryKey"
                    } | Select-DefaultView -Property SqlInstance, Database, Table, Check, Type
                }
                Write-PSFMessage -Level Verbose -Message "Processing foreign keys in $($table.Name) on $($db.Name) on $($db.Parent.Name)"
                foreach ($fk in $table.ForeignKeys) {
                    [pscustomobject]@{
                        SqlInstance = $db.SqlInstance
                        Database    = $db.Name
                        TableCount  = $tablecount
                        Table       = $table.Name
                        Check       = $fk.Name
                        Type        = "ForeignKey"
                    } | Select-DefaultView -Property SqlInstance, Database, Table, Check, Type
                }
            }
        }
    }
}
function Get-DbsDbAccessControl {
    <#
    .SYNOPSIS
       Gathers information for for object ownership and authorization delegation to be documented

    .DESCRIPTION
        Gathers information for for object ownership and authorization delegation to be documented

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
        Tags: V-79105
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbAccessControl -SqlInstance sql2017, sql2016, sql2012

        Gathers information for for object ownership and authorization delegation for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbAccessControl -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\access.csv -NoTypeInformation

        Exports information for for object ownership and authorization delegation for all databases on sql2017, sql2016 and sql2012 to D:\disa\access.csv
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
        $sql = "-- Schemas not owned by the schema or dbo:
                SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database], 'Schema' as Type,
                [Name], USER_NAME(principal_id) AS Owner, NULL as Description,
                NULL as PermissionName, NULL as StateDescription
                FROM sys.schemas
                WHERE schema_id != principal_id
                AND principal_id != 1
                UNION
                --Objects owned by an individual principal:
                SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database], 'Object' as Type,
                [Name],
                USER_NAME(principal_id) AS [Owner],
                type_desc as [Description], NULL as PermissionName, NULL as StateDescription
                FROM sys.objects
                WHERE is_ms_shipped = 0 AND principal_id IS NOT NULL
                UNION
                -- Use the following query to discover database users who have
                -- been delegated the right to assign additional permissions:
                SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database],
                U.type_desc as Description, U.name AS Owner,
                DP.class_desc AS Type,
                CASE DP.class
                WHEN 0 THEN DB_NAME()
                WHEN 1 THEN OBJECT_NAME(DP.major_id)
                WHEN 3 THEN SCHEMA_NAME(DP.major_id)
                ELSE CAST(DP.major_id AS nvarchar)
                END AS Name,
                permission_name as PermissionName, state_desc as StateDescription
                FROM sys.database_permissions DP
                JOIN sys.database_principals U ON DP.grantee_principal_id = U.principal_id
                WHERE DP.state = 'W'"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -EnableException:$EnableException -ExcludeSystem
        }

        foreach ($db in $InputObject) {
            try {
                $db.Query($sql) | Select-Object -Property SqlInstance, Database, Type, Name, Owner, Description, StateDescription, PermissionName, @ { Name = 'db'; Expression = { $db } } |
                Select-DefaultView -Property SqlInstance, Database, Type, Name, Owner, Description, StateDescription, PermissionName
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
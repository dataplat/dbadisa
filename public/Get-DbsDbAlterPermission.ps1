function Get-DbsDbAlterPermission {
    <#
    .SYNOPSIS
        Gets non-compliant alter permissions

    .DESCRIPTION
        Gets non-compliant alter permissions

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
        Tags: V-79109, V-79075, V-79081
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbAlterPermission -SqlInstance sql2017, sql2016, sql2012

        Gets non-compliant alter permissions on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbAlterPermission -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\alter.csv -NoTypeInformation

        Exports all non-compliant alter permissions for all databases on sql2017, sql2016 and sql2012 to D:\disa\alter.csv
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
        $sql = "SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database], O.Name AS ObjectName, P.name AS PrincipalName, P.type_desc AS PrincipalType,
                O.type_desc AS TypeDescription,
                CASE class
                WHEN 0 THEN DB_NAME()
                WHEN 1 THEN OBJECT_SCHEMA_NAME(major_id) + '.' + OBJECT_NAME(major_id)
                WHEN 3 THEN SCHEMA_NAME(major_id)
                ELSE class_desc + '(' + CAST(major_id AS nvarchar) + ')'
                END AS SecurableName, DP.state_desc AS StateDescription, DP.permission_name AS PermissionName
                FROM sys.database_permissions DP
                JOIN sys.database_principals P ON DP.grantee_principal_id = P.principal_id
                LEFT OUTER JOIN sys.all_objects O ON O.object_id = DP.major_id AND O.type IN ('TR','TA','P','X','RF','PC','IF','FN','TF','U')
                WHERE DP.type IN ('AL','ALTG') AND DP.class IN (0, 1, 53)
                UNION
                SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database], R.name AS ObjectName, M.name AS PrincipalName, M.type_desc AS PrincipalType,
                'Role' AS TypeDescription, NULL AS SecurableName, NULL as StateDescription, NULL as PermissionName
                FROM sys.database_principals R
                JOIN sys.database_role_members DRM ON R.principal_id = DRM.role_principal_id
                JOIN sys.database_principals M ON DRM.member_principal_id = M.principal_id
                WHERE R.name IN ('db_ddladmin','db_owner')
                AND M.name != 'dbo'"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeSystem |
            Where-Object ContainmentType -eq $null
        }

        foreach ($db in $InputObject) {
            try {
                $db.Query($sql) | Select-Object -Property SqlInstance, Database, ObjectName, PrincipalName, PrincipalType, TypeDescription, SecurableName, StateDescription, PermissionName, @{ Name = 'db'; Expression = { $db } } |
                Select-DefaultView -Property SqlInstance, Database, ObjectName, PrincipalName, PrincipalType, TypeDescription, SecurableName, StateDescription, PermissionName
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
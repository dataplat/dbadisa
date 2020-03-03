function Get-DbsDbModuleAccess {
    <#
    .SYNOPSIS
        Obtains a listing of users and roles who are currently capable of changing stored procedures, functions, and triggers

    .DESCRIPTION
        Obtains a listing of users and roles who are currently capable of changing stored procedures, functions, and triggers

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

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
        Tags: V-79075
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbModuleAccess -SqlInstance sql2017, sql2016, sql2012

        Gets a listing of users and roles who are currently capable of changing stored procedures, functions, and triggers for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbModuleAccess -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\modulechanger.csv -NoTypeInformation

        Exports a listing of users and roles who are currently capable of changing stored procedures, functions, and triggers for all databases on sql2017, sql2016 and sql2012 to D:\disa\modulechanger.csv
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
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase @PSBoundParameters
        }
        foreach ($db in $InputObject) {
            try {
                $sql = "SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database], NULL as RoleName, P.type_desc AS PrincipalType, P.name AS PrincipalName, O.type_desc AS TypeDescription,
                        CASE class
                        WHEN 0 THEN DB_NAME()
                        WHEN 1 THEN OBJECT_SCHEMA_NAME(major_id) + '.' + OBJECT_NAME(major_id)
                        WHEN 3 THEN SCHEMA_NAME(major_id)
                        ELSE class_desc + '(' + CAST(major_id AS nvarchar) + ')'
                        END AS SecurableName, DP.state_desc as StateDescription, DP.permission_name as PermissionName
                        FROM sys.database_permissions DP
                        JOIN sys.database_principals P ON DP.grantee_principal_id = P.principal_id
                        LEFT OUTER JOIN sys.all_objects O ON O.object_id = DP.major_id AND O.type IN ('TR','TA','P','','RF','PC','IF','FN','TF','U')
                        WHERE DP.type IN ('AL','ALTG') AND DP.class IN (0, 1, 53)
                        UNION ALL
                        SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database], R.name AS RoleName, M.type_desc AS PrincipalType, M.name AS PrincipalName,
                        NULL as [TypeDescription], NULL as [SecurableName], NULL as [StateDescription], NULL as [PermissionName]
                        FROM sys.database_principals R
                        JOIN sys.database_role_members DRM ON R.principal_id = DRM.role_principal_id
                        JOIN sys.database_principals M ON DRM.member_principal_id = M.principal_id
                        WHERE R.name IN ('db ddladmin','db_owner')
                        AND M.name != 'dbo'"
                $db.Query($sql)
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Name) on $($db.Parent.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
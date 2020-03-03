function Get-DbsDbAuditMaintainer {
    <#
    .SYNOPSIS
        Returns a list of the database roles and individual users that have permissions which enable the ability to create and maintain audit definitions.

    .DESCRIPTION
        Returns a list of the database roles and individual users that have permissions which enable the ability to create and maintain audit definitions.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79073
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbAuditMaintainer -SqlInstance sql2017, sql2016, sql2012

        Returns a list of audit maintainers for sql2017, sql2016 and sql2012
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance -DisableException:$(-not $EnableException)

                foreach ($db in $server.Databases) {
                    $db.Query("SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database],
                        DP.Name AS 'Principal', DbPerm.permission_name AS 'GrantedPermission', R.name AS 'Role'
                        FROM sys.database_principals DP
                        LEFT OUTER JOIN sys.database_permissions DbPerm ON DP.principal_id = DbPerm.grantee_principal_id
                        LEFT OUTER JOIN sys.database_role_members DRM ON DP.principal_id = DRM.member_principal_id
                        INNER JOIN sys.database_principals R ON DRM.role_principal_id = R.principal_id
                        WHERE DbPerm.permission_name IN ('CONTROL','ALTER ANY DATABASE AUDIT')
                        OR R.name IN ('db_owner')")
                }
            } catch {
                Stop-PSFFunction -Message "Failure for database $($db.Name) on $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
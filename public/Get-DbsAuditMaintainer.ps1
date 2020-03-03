function Get-DbsAuditMaintainer {
    <#
    .SYNOPSIS
        Returns a list of the server roles and individual logins that have permissions which enable the ability to create and maintain audit definitions.

    .DESCRIPTION
        Returns a list of the server roles and individual logins that have permissions which enable the ability to create and maintain audit definitions.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79135, V-79143, V-79159, V-79161
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAuditMaintainer -SqlInstance sql2017, sql2016, sql2012

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
                $server.Query("SELECT @@SERVERNAME as SqlInstance,
                    CASE
                    WHEN SP.class_desc IS NOT NULL THEN
                    CASE
                    WHEN SP.class_desc = 'SERVER' AND S.is_linked = 0 THEN 'SERVER'
                    WHEN SP.class_desc = 'SERVER' AND S.is_linked = 1 THEN 'SERVER (linked)'
                    ELSE SP.class_desc
                    END
                    WHEN E.name IS NOT NULL THEN 'ENDPOINT'
                    WHEN S.name IS NOT NULL AND S.is_linked = 0 THEN 'SERVER'
                    WHEN S.name IS NOT NULL AND S.is_linked = 1 THEN 'SERVER (linked)'
                    WHEN P.name IS NOT NULL THEN 'SERVER_PRINCIPAL'
                    ELSE '???'
                    END AS [SecurableClass],
                    CASE
                    WHEN E.name IS NOT NULL THEN E.name
                    WHEN S.name IS NOT NULL THEN S.name
                    WHEN P.name IS NOT NULL THEN P.name
                    ELSE '???'
                    END AS [Securable],
                    P1.name AS [Grantee],
                    P1.type_desc AS [GranteeType],
                    sp.permission_name AS [Permission],
                    sp.state_desc AS [State],
                    P2.name AS [Grantor],
                    P2.type_desc AS [GrantorType],
                    R.name AS [RoleName]
                    FROM
                    sys.server_permissions SP
                    INNER JOIN sys.server_principals P1
                    ON P1.principal_id = SP.grantee_principal_id
                    INNER JOIN sys.server_principals P2
                    ON P2.principal_id = SP.grantor_principal_id

                    FULL OUTER JOIN sys.servers S
                    ON SP.class_desc = 'SERVER'
                    AND S.server_id = SP.major_id

                    FULL OUTER JOIN sys.endpoints E
                    ON SP.class_desc = 'ENDPOINT'
                    AND E.endpoint_id = SP.major_id

                    FULL OUTER JOIN sys.server_principals P
                    ON SP.class_desc = 'SERVER_PRINCIPAL'
                    AND P.principal_id = SP.major_id

                    FULL OUTER JOIN sys.server_role_members SRM
                    ON P.principal_id = SRM.member_principal_id

                    LEFT OUTER JOIN sys.server_principals R
                    ON SRM.role_principal_id = R.principal_id
                    WHERE sp.permission_name IN ('ALTER ANY SERVER AUDIT','CONTROL SERVER','ALTER ANY DATABASE','CREATE ANY DATABASE')
                    OR R.name IN ('sysadmin','dbcreator')") | Where-Object Securable -notlike '##MS_*'
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
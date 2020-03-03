function Get-DbsPrivilegedLogin {
    <#
    .SYNOPSIS
        Review server-level securables and built-in role membership to ensure only authorized users have privileged access and the ability to create server-level objects and grant permissions to themselves or others

    .DESCRIPTION
        Review server-level securables and built-in role membership to ensure only authorized users have privileged access and the ability to create server-level objects and grant permissions to themselves or others

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
        Tags: V-79219
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsPrivilegedLogin -SqlInstance sql2017, sql2016, sql2012

        Review server-level securables and built-in role membership to ensure only authorized users have privileged access and the ability to create server-level objects and grant permissions to themselves or others for sql2017, sql2016 and sql2012
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
                $server.Query("SELECT DISTINCT @@SERVERNAME as SqlInstance,
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
                        END AS [Securable Class],
                        CASE
                        WHEN E.name IS NOT NULL THEN E.name
                        WHEN S.name IS NOT NULL THEN S.name
                        WHEN P.name IS NOT NULL THEN P.name
                        ELSE '???'
                        END AS [Securable],
                        P1.name AS [Grantee],
                        P1.type_desc AS [Grantee Type],
                        sp.permission_name AS [Permission],
                        sp.state_desc AS [State],
                        P2.name AS [Grantor],
                        P2.type_desc AS [Grantor Type]
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
                        AND P.principal_id = SP.major_id ")
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
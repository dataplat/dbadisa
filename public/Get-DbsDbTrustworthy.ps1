function Get-DbsDbTrustworthy {
    <#
    .SYNOPSIS
        Returns a list trustworthy databases.

    .DESCRIPTION
        Returns a list trustworthy databases.

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
        Tags: V-79071
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbTrustworthy -SqlInstance sql2017, sql2016, sql2012

        Returns a list of all trustworthy databases.

    .EXAMPLE
        PS C:\> Get-DbsDbTrustworthy -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\trustworthy.csv -NoTypeInformation

        Exports all trustworthy databases for all databases on sql2017, sql2016 and sql2012 to D:\disa\trustworthy.csv
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
        $sql = "SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database], SUSER_SNAME(d.owner_sid) AS Owner,
                CASE
                WHEN d.is_trustworthy_on = 0 THEN 'False'
                WHEN d.is_trustworthy_on = 1 THEN 'True'
                END AS Trustworthy,
                CASE
                WHEN role.name IN ('sysadmin','securityadmin')
                OR permission.permission_name = 'CONTROL SERVER'
                THEN 'True'
                ELSE 'False'
                END AS 'PrivilegedOwner'
                FROM sys.databases d
                LEFT JOIN sys.server_principals login ON d.owner_sid = login.sid
                LEFT JOIN sys.server_role_members rm ON login.principal_id = rm.member_principal_id
                LEFT JOIN sys.server_principals role ON rm.role_principal_id = role.principal_id
                LEFT JOIN sys.server_permissions permission ON login.principal_id = permission.grantee_principal_id
                WHERE d.name = DB_NAME()"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase @PSBoundParameters -ExcludeDatabase msdb
        }
        $InputObject | Invoke-DbaQuery -Query $sql
    }
}
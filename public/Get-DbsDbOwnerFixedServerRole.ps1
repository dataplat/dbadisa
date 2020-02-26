function Get-DbsDbOwnerFixedServerRole {
    <#
    .SYNOPSIS
        Gets a listing of user databases whose owner is a member of a fixed server role

    .DESCRIPTION
        Gets a listing of user databases whose owner is a member of a fixed server role

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
        Tags: V-79111
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbOwnerFixedServerRole -SqlInstance sql2017, sql2016, sql2012

        Gets a listing of user databases whose owner is a member of a fixed server role for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbOwnerFixedServerRole -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\fixedserverrole.csv -NoTypeInformation

        Exports a list of user databases whose owner is a member of a fixed server role for all databases on sql2017, sql2016 and sql2012 to D:\disa\fixedserverrole.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        $sql = "SELECT
            @@SERVERNAME as SqlInstance, D.name as [Database], SUSER_SNAME(D.owner_sid) AS [Owner],
            CASE FRM.is_fixed_role_member
            WHEN 0 THEN 'False'
            WHEN 1 THEN 'True'
            END AS FixedRoleMember
            FROM sys.databases D
            OUTER APPLY (
            SELECT MAX(fixed_role_member) AS is_fixed_role_member
            FROM (
            SELECT IS_SRVROLEMEMBER(R.name, SUSER_SNAME(D.owner_sid)) AS fixed_role_member
            FROM sys.server_principals R
            WHERE is_fixed_role = 1
            ) A
            ) FRM
            WHERE (D.database_id > 4
            AND (FRM.is_fixed_role_member = 1
            OR FRM.is_fixed_role_member IS NULL))
            and FRM.is_fixed_role_member = 1
            ORDER BY [Database]"
    }
    process {
        try {
            $servers = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential -MinimumVersion 11
        } catch {
            Stop-PSFFunction -Message "Failure on $($server.Name)" -ErrorRecord $_ -Continue
        }

        foreach ($server in $servers) {
            try {
                $dbs = Get-DbaDatabase -SqlInstance $server
                $results = $server.Query($sql)

                foreach ($result in $results) {
                    [PSCustomObject]@{
                        SqlInstance     = $result.SqlInstance
                        Database        = $result.Database
                        Owner           = $result.Owner
                        FixedRoleMember = $result.FixedRoleMember
                        db              = ($dbs | Where-Object Name -eq $result.Database)
                    } | Select-DefaultView -Property SqlInstance, Database, Owner, FixedRoleMember
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
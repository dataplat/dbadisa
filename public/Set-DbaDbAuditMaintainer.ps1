function Set-DbaDbAuditMaintainer {
    <#
    .SYNOPSIS
        Sets the audit maintainer role.

    .DESCRIPTION
        Create the audit maintainer role, sets the permissions for the role, and adds logins.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER AuditRoleName
        Name to be given the audit maintainer role.

    .PARAMETER User
        The login or logins that are to be granted permissions.

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: DISA, STIG
        Author: Tracy Boggiano (@TracyBoggiano), databasesuperhero.com

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbaDbAuditMaintainer -SqlInstance sql2017, sql2016, sql2012 -Database "Prod" -AuditRoleName "DATABASE_AUDIT_MAINTAINERS" -User "AD\SQL Admins"

        Set permissions for the DATABASE_AUDIT_MAINTAINERS role on sql2017, sql2016, sql2012 for user AD\SQL Admins on Prod database.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(Mandatory)]
        [string]$AuditRoleName,
        [parameter(Mandatory)]
        [string[]]$User,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )

    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -ExcludeDatabase tempdb -EnableException:$EnableException | Where-Object IsAccessible
        }

        foreach ($db in $InputObject) {
            try {
                $sql = "IF DATABASE_PRINCIPAL_ID('$($AuditRoleName)') IS NULL CREATE ROLE $($AuditRoleName)"
                Write-Message -Level Verbose -Message $sql
                $db.Query($sql)

                $sql = "GRANT ALTER ANY DATABASE AUDIT TO $($AuditRoleName)"
                Write-Message -Level Verbose -Message $sql
                $db.Query($sql)

                $dbusers = Get-DbaDbUser -SqlInstance $SqlInstance -SqlCredential $SqlCredential -Database $db
                foreach ($dbuser in $dbusers) {
                    $sql = "REVOKE DATABASE AUDIT FROM $($dbuser)"
                    Write-Message -Level Verbose -Message $sql
                    $db.Query($sql)

                    $sql = "REVOKE CONTROL DATABASE FROM $($dbuser)"
                    Write-Message -Level Verbose -Message $sql
                    $db.Query($sql)
                }

                foreach ($dbuser in $user) {
                    $sql = "IF DATABASE_PRINCIPAL_ID('$($dbuser)') IS NOT NULL ALTER ROLE $($AuditRoleName) ADD MEMBER [$($dbuser)]"
                    Write-Message -Level Verbose -Message $sql
                    $db.Query($sql)
                }
            }
            catch {
                Stop-Function -EnableException:$EnableException -Message "Could not modify $db on $($db.Parent.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
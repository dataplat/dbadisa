function Get-DbsAuditSpecification {
    <#
    .SYNOPSIS
        Returns a list of missing audit specifications

    .DESCRIPTION
        Returns a list of missing audit specifications

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
        Tags: V-79239, V-79259, V-79261, V-79263, V-79265, V-79275, V-79277, V-79291, V-79293, V-79295
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAuditSpecification -SqlInstance sql2017, sql2016, sql2012

        Returns a list of missing audit specifications for sql2017, sql2016 and sql2012
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        $list = 'APPLICATION_ROLE_CHANGE_PASSWORD_GROUP', 'AUDIT_CHANGE_GROUP', 'BACKUP_RESTORE_GROUP', 'DATABASE_CHANGE_GROUP', 'DATABASE_OBJECT_CHANGE_GROUP', 'DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP', 'DATABASE_OBJECT_PERMISSION_CHANGE_GROUP', 'DATABASE_OPERATION_GROUP', 'DATABASE_OWNERSHIP_CHANGE_GROUP', 'DATABASE_PERMISSION_CHANGE_GROUP', 'DATABASE_PRINCIPAL_CHANGE_GROUP', 'DATABASE_PRINCIPAL_IMPERSONATION_GROUP', 'DATABASE_ROLE_MEMBER_CHANGE_GROUP', 'DBCC_GROUP', 'LOGIN_CHANGE_PASSWORD_GROUP', 'LOGOUT_GROUP', 'SCHEMA_OBJECT_CHANGE_GROUP', 'SCHEMA_OBJECT_OWNERSHIP_CHANGE_GROUP', 'SCHEMA_OBJECT_PERMISSION_CHANGE_GROUP', 'SERVER_OBJECT_CHANGE_GROUP', 'SERVER_OBJECT_OWNERSHIP_CHANGE_GROUP', 'SERVER_OBJECT_PERMISSION_CHANGE_GROUP', 'SERVER_OPERATION_GROUP', 'SERVER_PERMISSION_CHANGE_GROUP', 'SERVER_PRINCIPAL_CHANGE_GROUP', 'SERVER_PRINCIPAL_IMPERSONATION_GROUP', 'SERVER_ROLE_MEMBER_CHANGE_GROUP', 'SERVER_STATE_CHANGE_GROUP', 'TRACE_CHANGE_GROUP', 'USER_CHANGE_PASSWORD_GROUP', 'DATABASE_OBJECT_ACCESS_GROUP' | Sort-Object
        $sql = "SELECT @@SERVERNAME as SqlInstance, a.name AS 'AuditName',
                s.name AS 'SpecName',
                d.audit_action_name AS 'ActionName',
                d.audited_result AS 'Result'
                FROM sys.server_audit_specifications s
                JOIN sys.server_audits a ON s.audit_guid = a.audit_guid
                JOIN sys.server_audit_specification_details d ON s.server_specification_id = d.server_specification_id
                WHERE a.is_state_enabled = 1
                AND d.audit_action_name IN ('$($list -join "','")')
                Order by d.audit_action_name"
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance
                $results = $server.Query($sql)
                foreach ($item in $list) {
                    if ($item -notin $results.ActionName) {
                        [PSCustomObject]@{
                            SqlInstance = $instance
                            ActionName  = $item
                            Result      = "Missing"
                        }
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure for database $($db.Name) on $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
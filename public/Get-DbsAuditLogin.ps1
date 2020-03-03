function Get-DbsAuditLogin {
    <#
    .SYNOPSIS
        Returns a list of (non-compliant) servers that are not auditing logins either by Audits or via "Both failed and successful logins"

    .DESCRIPTION
        Returns a list of (non-compliant) servers that are not auditing logins either by Audits or via "Both failed and successful logins"

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
        Tags: V-79297, V-79287, V-79289
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAuditLogin -SqlInstance sql2017, sql2016, sql2012

        Gets a list of SQL Server must generate audit records when concurrent logons/connections by the same user from different workstations occur.
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

                $auditresult = $server.Query("SELECT @@SERVERNAME as SqlInstance, a.name AS 'AuditName',
                        s.name AS 'SpecName',
                        d.audit_action_name AS 'ActionName',
                        d.audited_result AS 'Result'
                        FROM sys.server_audit_specifications s
                        JOIN sys.server_audits a ON s.audit_guid = a.audit_guid
                        JOIN sys.server_audit_specification_details d ON s.server_specification_id = d.server_specification_id
                        WHERE a.is_state_enabled = 1 AND d.audit_action_name = 'SUCCESSFUL_LOGIN_GROUP' ")

                $regread = $server.Query("EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel'")

                if (-not ($auditresult -or $regread.Data -eq 3)) {
                    [PSCustomObject]@{
                        SqlInstance   = $server.Name
                        LoginTracking = $false
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
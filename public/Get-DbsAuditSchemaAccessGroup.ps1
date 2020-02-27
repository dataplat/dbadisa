function Get-DbsAuditSchemaAccessGroup {
    <#
    .SYNOPSIS
        Gets a list of audits that record when privileges/permissions are retrieved or are failed to be retrieved.

    .DESCRIPTION
        Gets a list of audits that record when privileges/permissions are retrieved or are failed to be retrieved.

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
        Tags: V-79137, V-79139, V-79301, V-79299, V-79251, V-79253, V-79255, V-79257, V-79267, V-79269, V-79271, V-79273, V-79279, V-79281, V-79283, V-79285, V-79301
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAuditSchemaAccessGroup -SqlInstance sql2017, sql2016, sql2012

        Gets a list of audits that record when privileges/permissions are retrieved or are failed to be retrieved for sql2017, sql2016 and sql2012

    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        $server = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential

        try {
            $server.Query("SELECT @@SERVERNAME as SqlInstance, a.name AS 'AuditName',
            s.name AS 'SpecName',
            d.audit_action_name AS 'ActionName',
            d.audited_result AS 'Result'
            FROM sys.server_audit_specifications s
            JOIN sys.server_audits a ON s.audit_guid = a.audit_guid
            JOIN sys.server_audit_specification_details d ON s.server_specification_id = d.server_specification_id
            WHERE a.is_state_enabled = 1 AND d.audit_action_name = 'SCHEMA_OBJECT_ACCESS_GROUP'")
        } catch {
            Stop-Function -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue -EnableException:$EnableException
        }
    }
}
function Get-DbsAuditFilter {
    <#
    .SYNOPSIS
        Gets a list of non-compliant audit filters.

    .DESCRIPTION
        Gets a list of non-compliant audit filters.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Audit
       The name of the DISA Audit.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79303
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAuditFilter -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant audit filters on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsAuditFilter -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant audit filters on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsAuditFilter -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\auditfilters.csv -NoTypeInformation

        Gets a list of non-compliant audit filters sql2017, sql2016 and sql2012 to D:\disa\auditfilters.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [string[]]$Audit = (Get-PSFConfigValue -FullName dbadisa.app.auditname),
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        $servers = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
        foreach ($server in $servers) {
            try {
                $server.Query("SELECT @@SERVERNAME as SqlInstance, a.name AS 'AuditName',
                            predicate AS AuditFilter
                            FROM sys.server_audits
                            WHERE predicate IS NOT NULL")
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue -EnableException:$EnableException
            }
        }
    }
}
function Set-DbsAuditStartupState {
    <#
    .SYNOPSIS
        Sets startup state for compliance audit to ON.

    .DESCRIPTION
        Sets startup state for compliance audit to ON.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Audit
       The name of the DISA Audit.

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79141
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsAuditStartupState -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant audit states on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Set-DbsAuditStartupState -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant audit states on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Set-DbsAuditStartupState -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\auditstartup.csv -NoTypeInformation

        Gets a list of non-compliant audit startup states sql2017, sql2016 and sql2012 to D:\disa\auditstartup.csv
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [string[]]$Audit = (Get-PSFConfigValue -FullName dbadisa.app.auditname),
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            foreach ($currentaudit in $audit) {
                try {
                    $server = Connect-DbaInstance -SqlInstance $instance
                    if ($PSCmdlet.ShouldProcess($instance, "Starting $currentaudit")) {
                        $sql = "ALTER SERVER AUDIT [$Audit] WITH (STATE = ON)"
                        Write-PSFMessage -Message $sql -Level Verbose
                        $null = $server.Query($sql)
                        [pscustomobject]@{
                            SqlInstance  = $server.Name
                            Audit        = $currentaudit
                            StartupState = "ON"
                        }
                    }
                } catch {
                    Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}
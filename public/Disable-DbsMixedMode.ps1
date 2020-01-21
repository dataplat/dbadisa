function Disable-DbsMixedMode {
    <#
    .SYNOPSIS
        Disables mixed mode

    .DESCRIPTION
        Disables mixed mode

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: DISA, STIG
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Disable-DbsMixedMode -SqlInstance sql2017, sql2016, sql2012

        Disables mixed mode on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Disable-DbsMixedMode -SqlInstance sql2017, sql2016, sql2012 -WhatIf

        Shows what would happen if you ran the command
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        $servers = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential -DisableException:$($EnableException -eq $false)
        foreach ($server in $servers) {
            try {
                $mode = $server.Settings.LoginMode
                if ($mode -ne "Integrated") {
                    if ($PSCmdlet.ShouldProcess($server.Name, "Changing login mode from $mode to Integrated")) {
                        $server.Settings.LoginMode = "Integrated"
                        $server.Alter()
                        [PSCustomObject]@{
                            SqlInstance = $server.Name
                            Status      = "Success. Please restart SQL Server."
                        }
                        Write-Message -Level Verbose -Message "You must restart SQL Server $($server.Name) for this setting to go into effect"
                    }
                } else {
                    Write-Message -Level Output -Message "Integrated authentication already set on $($server.Name)"
                }
            } catch {
                Stop-PSFunction -EnableException:$EnableException -ErrorRecord $_ -Message "Failure on $($server.Name)"
            }
        }
    }
}
function Disable-DbsSaAccount {
    <#
    .SYNOPSIS
        Disable and rename sa account

    .DESCRIPTION
        Disable and rename sa account

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER NewName
        NewName for sa account

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .LINK
        https://dbadisa.readthedocs.io/en/latest/functions/Disable-DbsSaAccount/

    .NOTES
        Tags: DISA, STIG
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Disable-DbsSaAccount -SqlInstance Sql2016 -NewName newsa
        Disables and renames sa account
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(Mandatory)]
        [string]$NewName,
        [switch]$EnableException
    )

    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance -SqlCredential $sqlcredential -MinimumVersion 11
            } catch {
                Stop-Function -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            try {
                $login = Get-DbaLogin -SqlInstance $server | Where-Object Id -eq 1

                if ($login.Name -eq "sa") {
                    Rename-DbaLogin -SqlInstance $server -Login $login -NewLogin $NewName
                }

                if ($login.IsDisabled -eq $false) {
                    $login.Disable()
                }
            } catch {
                Stop-Function -Message "Failed to rename sa account." -ErrorRecord $_ -Continue -Target $instance
            }
        }
    }
}
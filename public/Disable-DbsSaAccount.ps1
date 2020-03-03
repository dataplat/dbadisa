function Disable-DbsSaAccount {
    <#
    .SYNOPSIS
        Disable and/or rename sa account

    .DESCRIPTION
        Disable and/or rename sa account

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER NewName
        NewName for sa account

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79319, V-79317
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Disable-DbsSaAccount -SqlInstance Sql2016 -NewName newsa

        Disables and renames sa account
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [string]$NewName,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance -MinimumVersion 11
            } catch {
                Stop-PSFFunction -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            try {
                $login = Get-DbaLogin -SqlInstance $server | Where-Object Id -eq 1

                if ($NewName) {
                    Rename-DbaLogin -SqlInstance $server -Login $login -NewLogin $NewName
                }

                if ($login.IsDisabled -eq $false) {
                    $login.Disable()
                }
            } catch {
                Stop-PSFFunction -Message "Failed to rename sa account." -ErrorRecord $_ -Continue -Target $instance
            }
        }
    }
}
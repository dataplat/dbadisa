function Set-DbsAuditLogin {
    <#
    .SYNOPSIS
        Sets "Both failed and successful logins"

    .DESCRIPTION
        Sets "Both failed and successful logins"

    .PARAMETER SqlInstance
        The target SQL Server instance or instances Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state

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
        PS C:\> Set-DbsAuditLogin -SqlInstance sql2017, sql2016, sql2012

        Sets "Both failed and successful logins" on sql2017, sql2016 and sql2012
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance
                if ($PSCmdlet.ShouldProcess($instance, "Setting AuditLevel for $instance using xp_instance_regwrite")) {
                    $null = $server.Query("EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, 3")
                    $regread = $server.Query("EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel'")

                    if ($regread.Data -eq 3) {
                        [PSCustomObject]@{
                            SqlInstance   = $server.Name
                            LoginTracking = $true
                        }
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure for $instance" -ErrorRecord $_ -Continue
            }
        }
    }
}
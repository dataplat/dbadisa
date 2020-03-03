function Set-DbsDbRecoveryModel {
    <#
    .SYNOPSIS
        Sets all user databases to the FULL recovery model

    .DESCRIPTION
        Sets all user databases to the FULL recovery model

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER InputObject
        Allows piping from Get-DbaDatabase

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79083
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsDbRecoveryModel -SqlInstance sql2017, sql2016, sql2012

        Sets all user databases to the FULL recovery model on sql2017, sql2016, and sql2012
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase @PSBoundParameters -ExcludeSystem | Where-Object IsAccessible
        }
        $results = $InputObject | Set-DbaDbRecoveryModel -RecoveryModel Full
        Select-DefaultView -InputObject $results -Property SqlInstance, 'Name as Database', RecoveryModel
    }
}
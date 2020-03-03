function Disable-DbsDbContainment {
    <#
    .SYNOPSIS
        Disables database containment features

    .DESCRIPTION
        Disables database containment features

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

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
        Tags: V-79061
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Disable-DbsDbContainment -SqlInstance sql2017, sql2016, sql2012

        Disables database containment features on sql2017, sql2016 and sql2012
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        Set-DbaSpConfigure @PSBoundParameters -Name ContainmentEnabled -Value 0
    }
}
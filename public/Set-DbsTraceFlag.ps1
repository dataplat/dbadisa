function Set-DbsTraceFlag {
    <#
    .SYNOPSIS
        Sets trace flag 3625.

    .DESCRIPTION
        Sets trace flag 3625 to hide information from non-sysadmins in error messages.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER Credential
        Login to the target _Windows Server_ instance using alternative credentials. Accepts PowerShell credentials (Set-Credential).

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79097, V-79217
        Author: Tracy Boggiano (@TracyBoggiano), databasesuperhero.com

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsTraceFlag -SqlInstance sql2017, sql2016, sql2012

        Sets the 3625 trace flag on sql2017, sql2016, and sql2012

    .EXAMPLE
        PS C:\> Set-DbsTraceFlag -SqlInstance sql2017, sql2016, sql2012 -Confirm:$false

        Sets the 3625 trace flag on sql2017, sql2016, and sql2012 without confirmation prompts
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$Credential,
        [switch]$EnableException
    )
    process {
        Set-DbaStartupParameter @PSBoundParameters -TraceFlag 3625 | Select-Object SqlInstance, TraceFlags
    }
}
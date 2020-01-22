function Set-DbsConnectionLimit {
    <#
    .SYNOPSIS
        Sets the max number of UserConnections to comply with V-79119.

    .DESCRIPTION
        Sets the max number of UserConnections to comply with V-79119. Note you still need to document this method.

        "If a mechanism other than a logon trigger is used, verify its correct operation by the appropriate means."

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Value
        The max number of connections that can connect to the SQL Server

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79119
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsConnectionLimit -SqlInstance sql2017, sql2016, sql2012 -Value 5000

        Sets the max number of connections to 5000

    .EXAMPLE
        PS C:\> Set-DbsConnectionLimit -SqlInstance sql2017, sql2016, sql2012 -Value 5000 -WhatIf

        Shows what would happen if the command would run
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(Mandatory)]
        [int]$Value,
        [switch]$EnableException
    )
    process {
        Set-DbaSpConfigure @PSBoundParameters -Name UserConnections
    }
}
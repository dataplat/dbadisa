function Get-DbsRemoteAccess {
    <#
    .SYNOPSIS
        Gets non-compliant Remote Access settings

    .DESCRIPTION
        Gets non-compliant Remote Access settings

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79337, NonCompliantResults
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsRemoteAccess -SqlInstance sql2017, sql2016, sql2012

        Only returns non-compliant Remote Access settings from sql2017, sql2016 and sql2012
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        Get-DbaSpConfigure @PSBoundParameters -Name RemoteAccess | Where-Object RunningValue -eq 1
    }
}
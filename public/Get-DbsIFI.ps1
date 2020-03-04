function Get-DbsIFI {
    <#
    .SYNOPSIS
        Gets all non-compliant Instant File Initialization (IFI) settings from all instances on a computer

    .DESCRIPTION
        Gets all non-compliant Instant File Initialization (IFI) settings from all instances on a computer

    .PARAMETER ComputerName
        The target SQL Server

    .PARAMETER Credential
        Login to the target computer using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79213, NonCompliantResults
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsIFI -ComputerName sql01

        Gets all non-compliant Instant File Initialization (IFI) settings from all instances on sql01
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [Alias("cn", "host", "Server")]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        Get-DbaPrivilege @PSBoundParameters | Where-Object InstantFileInitialization
    }
}
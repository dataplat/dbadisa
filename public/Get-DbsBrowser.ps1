function Get-DbsBrowser {
    <#
    .SYNOPSIS
        Gets non-compliant SQL Browser service states (Running)

    .DESCRIPTION
        Gets non-compliant SQL Browser service states (Running)

    .PARAMETER ComputerName
        The SQL Server (or server in general) that you're connecting to This command handles named instances.

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79353, V-79349
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsBrowser -ComputerName Sql2016

       Gets non-compliant SQL Browser services
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        Get-DbaService @PSBoundParameters -Type Browser | Where-Object State -eq Running
    }
}
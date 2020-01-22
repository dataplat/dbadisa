function Get-DbsProtocol {
    <#
    .SYNOPSIS
        Gets all non-compliant protocols enabled from all instances on a computer

    .DESCRIPTION
        Gets all non-compliant protocols enabled from all instances on a computer

    .PARAMETER ComputerName
        The target SQL Server

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79185
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsProtocol -ComputerName sql01

        Gets all non-compliant protocols enabled from all instances on sql01
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [Alias("cn", "host", "Server")]
        [DbaInstanceParameter[]]$ComputerName = $env:COMPUTERNAME,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            Get-DbaInstanceProtocol -ComputerName $computer -Credential $Credential -EnableException:$EnableException |
            Where-Object { $psitem.Name -ne 'tcp' -and $psitem.IsEnabled }
        }
    }
}
function Get-DbsTcpPort {
    <#
    .SYNOPSIS
        Returns all Tcp Ports in use by SQL Server

    .DESCRIPTION

        Returns all Tcp Ports in use by SQL Server

    .PARAMETER ComputerName
        The target server or instance.

    .PARAMETER Credential
        Login to the target computer using alternative credentials.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79187
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsTcpPort -ComputerName server01, server02

        Returns all Tcp Ports in use by SQL Server on server01 and server02
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        Get-DbaTcpPort -SqlInstance $ComputerName -All
    }
}
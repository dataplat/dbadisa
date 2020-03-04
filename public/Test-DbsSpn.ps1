function Test-DbsSpn {
    <#
    .SYNOPSIS
        Returns a list of instances that do not have an SPN

    .DESCRIPTION
        Returns a list of instances that do not have an SPN

    .PARAMETER ComputerName
        The target server or instance

    .PARAMETER Credential
        Login to the target computer using alternative credentials.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79123
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Test-DbsSpn -ComputerName sql2016, sql2017, sql2012

        Gets all instances that do not have an SPN from sql2016, sql2017 and sql2012
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        Test-DbaSpn @PSBoundParameters | Where-Object IsSet -eq $false
    }
}
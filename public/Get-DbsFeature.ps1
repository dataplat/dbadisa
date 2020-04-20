function Get-DbsFeature {
    <#
    .SYNOPSIS
        Returns a list of all features that may be not required and must be documented

    .DESCRIPTION
        Returns a list of all features that may be not required and must be documented

    .PARAMETER ComputerName
        The target server or instance

    .PARAMETER Credential
        Login to the target computer using alternative credentials.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79173, V-79175, V-79247
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsFeature -ComputerName sql2016, sql2017, sql2012

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
        Get-DbaFeature @PSBoundParameters 3>$null | Where-Object Feature -ne 'Database Engine Services'
    }
}
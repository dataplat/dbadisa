function Get-DbsFeature {
    <#
    .SYNOPSIS
        Returns a list of all features that may be not required and must be documented.

    .DESCRIPTION
        Returns a list of all features that may be not required and must be documented.

    .PARAMETER ComputerName
        The SQL Server (or server in general) that you're connecting to.

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: DISA, STIG, V-79173
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbadisa.readthedocs.io/en/latest/functions/Get-DbsFeature

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
        Get-DbaFeature @PSBoundParameters | Where-Object Feature -ne 'Database Engine Services'
    }
}
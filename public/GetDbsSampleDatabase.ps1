function Get-DbsSampleDatabase {
    <#
    .SYNOPSIS
        Returns a list of prohibited sample databases.

    .DESCRIPTION
        Returns a list of prohibited sample databases.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79195, V-79171
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> GetDbsSampleDatabase -SqlInstance sql2017, sql2016, sql2012

        Returns a list of prohibited sample databases for sql2017, sql2016, and sql2012

    .EXAMPLE
        PS C:\> GetDbsSampleDatabase -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\sampledbs.csv -NoTypeInformation

        Exports a list of prohibited sample databases for sql2017, sql2016 and sql2012 to D:\disa\sampledbs.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        Get-DbaDatabase @PSBoundParameters | Where-Object Name -in 'pubs', 'Northwind', 'AdventureWorks', 'WorldwideImporters'
    }
}
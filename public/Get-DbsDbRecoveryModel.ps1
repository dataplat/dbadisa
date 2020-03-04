function Get-DbsDbRecoveryModel {
    <#
    .SYNOPSIS
        Returns a list of all non-compliant (non-full) database recovery models.

    .DESCRIPTION
        Returns a list of all non-compliant (non-full) database recovery models.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbaDatabase

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79083
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbRecoveryModel -SqlInstance sql2017, sql2016, sql2012

        Returns a list of all non-compliant (non-full) database recovery models.

    .EXAMPLE
        PS C:\> Get-DbsDbRecoveryModel -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\recovery.csv -NoTypeInformation

        Exports all non-compliant (non-full) database recovery models for all databases on sql2017, sql2016 and sql2012 to D:\disa\recovery.csv
    #>

    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeDatabase master, msdb, tempdb, model
        }

        $results = $InputObject | Where-Object RecoveryModel -ne Full
        Select-DefaultView -InputObject $results -Property SqlInstance, 'Name as Database', RecoveryModel
    }
}
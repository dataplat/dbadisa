function Get-DbsDbContainedUser {
    <#
    .SYNOPSIS
        Returns a list of non-compliant users for all contained databases

    .DESCRIPTION
        Returns a list of non-compliant users for all contained databases

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
        Tags: V-79193, non-compliant
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbContainedUser -SqlInstance sql2017, sql2016, sql2012

        Returns a list of non-compliant users for all contained databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbContainedUser -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\contained.csv -NoTypeInformation

        Exports a list of non-compliant users for all contained databases on sql2017, sql2016 and sql2012 to D:\disa\contained.csv
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
            $InputObject = Get-DbaDatabase @PSBoundParameters | Where-Object ContainmentType
        }
        foreach ($db in $InputObject) {
            try {
                $db.Query("SELECT distinct @@SERVERNAME as SqlInstance, DB_NAME() as [Database], Name as ContainedUser FROM sys.database_principals WHERE type_desc = 'SQL_USER' AND authentication_type_desc = 'DATABASE'")
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Name) on $($db.Parent.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
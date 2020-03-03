function Test-DbsDbInputValidity {
    <#
    .SYNOPSIS
        Tests a db to see if it's got contraints

    .DESCRIPTION
        Tests a db to see if it's got contraints

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
        Tags: V-79095
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Test-DbsDbInputValidity -SqlInstance sql2017, sql2016, sql2012

        Tests a db to see if it's got contraints on sql2017, sql2016 and sql2012
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
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeSystem
        }

        foreach ($db in $InputObject) {
            try {
                Write-PSFMessage -Level Verbose -Message "Processing $($db.Name) on $($db.Parent.Name)"
                $totaltables = ($db.Query("select count(*) as [Count] from sys.tables tab")).Count
                $checks = $db | Get-DbsDbInputValidity
                [pscustomobject]@{
                    SqlInstance = $db.SqlInstance
                    Database    = $db.Name
                    TotalTables = $totaltables
                    TotalChecks = @($checks).Count
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
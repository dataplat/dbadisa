function Test-DbsDbInputValidity {
    <#
    .SYNOPSIS
        Returns a list of all input validations

    .DESCRIPTION
        Returns a list of all input validations

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

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

        Returns a list of all input validations

    .EXAMPLE
        PS C:\> Test-DbsDbInputValidity -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\checks.csv -NoTypeInformation

        Exports input validation for all databases on sql2017, sql2016 and sql2012 to D:\disa\checks.csv
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
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -EnableException:$EnableException -ExcludeSystem
        }

        foreach ($db in $InputObject) {
            $checks = $db | Get-DbsDbInputValidity
            $total = $checks | Select-Object -ExpandProperty TableCount -First 1
            [pscustomobject]@{
                SqlInstance = $db.SqlInstance
                Database    = $db.Name
                TotalTables = $total
                TotalChecks = @($checks).Count
            }
        }
    }
}
function Get-DbsAuditMaxValue {
    <#
    .SYNOPSIS
        Gets a list of non-compliant max values (rollover and file size)

    .DESCRIPTION
        Gets a list of non-compliant max values (rollover and file size)

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER Audit
       The name of the DISA Audit.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79149, V-79227, NonCompliantResults
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAuditMaxValue -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant max values (rollover and file size) for sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsAuditMaxValue -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\maxvalues.csv -NoTypeInformation

        Exports a list of non-compliant max values (rollover and file size) on sql2017, sql2016 and sql2012 to D:\disa\maxvalues.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [string[]]$Audit = (Get-PSFConfigValue -FullName dbadisa.app.auditname),
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            foreach ($instanceaudit in $audit) {
                $params = @{
                    SqlInstance     = $instance
                    SqlCredential   = $SqlCredential
                    Audit           = $instanceaudit
                    EnableException = $EnableException
                }
                $stigaudit = Get-DbaInstanceAudit @params
                if (-not $stigaudit) {
                    [PSCustomObject]@{
                        SqlInstance          = $instance
                        Name                 = $Audit
                        MaximumRolloverFiles = $null
                        MaximumFileSize      = $null
                        Enabled              = $null
                    }
                    Stop-PSFFunction -Message "Audit $instanceaudit not found on $instance" -Continue
                } else {
                    $stigaudit | Where-Object { $PSItem.MaximumRolloverFiles -eq 0 -or $PSItem.MaximumFileSize -eq 0 } | Select-DefaultView -Property SqlInstance, Name, MaximumValuesFiles, Enabled
                }
            }
        }
    }
}
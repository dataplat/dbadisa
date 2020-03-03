function Get-DbsAuditOnFailure {
    <#
    .SYNOPSIS
        Gets a list of non-compliant audit onfailure actions

    .DESCRIPTION
        Gets a list of non-compliant audit onfailure actions

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER Audit
       The name of the DISA Audit

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79147
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAuditOnFailure -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant audit onfailure actions for sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsAuditOnFailure -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\auditonfailure.csv -NoTypeInformation

        Exports a list of instance permissions for all databases on sql2017, sql2016 and sql2012 to D:\disa\auditonfailure.csv
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
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            $stigaudit = Get-DbaInstanceAudit -SqlInstance $instance -Audit $Audit | Where-Object OnFailure -ne 'Shutdown'
            if (-not $stigaudit) {
                Stop-PSFFunction -Message "Audit $Audit not found on $instance" -Continue
            } else {
                $stigaudit | Select-DefaultView -Property SqlInstance, Name, Onfailure, Enabled
            }
        }
    }
}
function Get-DbsLoginProperty {
    <#
    .SYNOPSIS
        Gets non-compliant login properties.

    .DESCRIPTION
        Gets non-compliant login properties.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: DISA, STIG, V-79191
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsLoginProperty -SqlInstance sql2017, sql2016, sql2012

        Only returns non-compliant login properties from sql2017, sql2016 and sql2012

    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        Get-DbaLogin @PSBoundParameters | Where-Object {
            (-not $psitem.PasswordExpirationEnabled -or -not $psitem.PasswordPolicyEnforced) -and $psitem.LoginType -eq 'SqlLogin' -and $psitem.Id -ne 1 -and $psitem.Name -notin '##MS_PolicyEventProcessingLogin##', '##MS_PolicyTsqlExecutionLogin##'
        } | Select-DefaultView -Property SqlInstance, Name, PasswordExpirationEnabled, PasswordPolicyEnforced
    }
}
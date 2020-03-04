function Get-DbsAdminRoleMember {
    <#
    .SYNOPSIS
        Gets members of the sysadmin and securityadmin server roles

    .DESCRIPTION
        Gets members of the sysadmin and securityadmin server roles

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79217, V-79219, V-79235
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAdminRoleMember -SqlInstance sql2017, sql2016, sql2012

        Gets members of the sysadmin and securityadmin server roles on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsAdminRoleMember -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\serverroles.csv -NoTypeInformation

       Gets members of the sysadmin and securityadmin server roles and exports them to D:\DISA\serverroles.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        Get-DbaServerRoleMember @PSBoundParameters | Where-Object Role -in sysadmin, securityadmin
    }
}
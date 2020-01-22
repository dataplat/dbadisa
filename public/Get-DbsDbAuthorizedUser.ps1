function Get-DbsDbAuthorizedUser {
    <#
    .SYNOPSIS
        Returns a list of all users for a database. These users are presumed to be authorized.

    .DESCRIPTION
        Returns a list of all users for a database. These users are presumed to be authorized.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags:
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbAuthorizedUser -SqlInstance sql2017, sql2016, sql2012

        Returns a list of all users for a database. These users are presumed to be authorized.

    .EXAMPLE
        PS C:\> Get-DbsDbAuthorizedUser -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\authorized.csv -NoTypeInformation

        Exports authorized users for all databases on sql2017, sql2016 and sql2012 to D:\disa\authorized.csv
    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        Get-DbaDbUser @PSBoundParameters | Select-Object SqlInstance, Database, Name, Login, LoginType, AuthenticationType, HasDbAccess, DefaultSchema
    }
}
function Set-DbsTraceFlag {
    <#
    .SYNOPSIS
        Sets trace flag 3625.

    .DESCRIPTION
        Sets trace flag 3625 to hide information from non-sysadmins in error messages.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Set-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79097
        Author: Tracy Boggiano (@TracyBoggiano), databasesuperhero.com

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsTraceFlag -SqlInstance sql2017, sql2016, sql2012

        Sets trace flag on servers.

    #>

    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        $parameters = Get-DbaStartupParameter -SQLInstance @PSBoundParameters
        $traceflags = $parameters.TraceFlags.Split(",")

        if (@(Get-DbaTraceFlag -SQLInstance @PSBoundParameters -TraceFlag 3625).Count -eq 1) {
            Get-DbaTraceFlag -SQLInstance @PSBoundParameters -TraceFlag 3625
        } elseif ($traceflags -match 3625) {
            Write-Message -Level Output -Message "Startup parameter for trace flag 3625 has been set, SQL needs to be restarted for it to take effect."
        } elseif ($traceflags -notmatch 3625) {
            Set-DbaStartupParameter -SqlInstance @PSBoundParameters -TraceFlag 3625
        } else {
            Write-Message -Level Output -MessageWrite-Host "Startup parameter for trace flag 3625 has already been set"
        }
    }
}
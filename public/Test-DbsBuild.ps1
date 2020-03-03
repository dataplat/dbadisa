function Test-DbsBuild {
    <#
    .SYNOPSIS
        Obtains evidence that software patches are consistently applied to SQL Server within the time frame defined for each patch.

    .DESCRIPTION
        Obtains evidence that software patches are consistently applied to SQL Server within the time frame defined for each patch.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79249
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Test-DbsBuild -SqlInstance sql2017, sql2016, sql2012

        Obtains evidence that software patches are consistently applied to SQL Server within the time frame defined for each patch.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance
                $build = Get-DbaBuildReference -SqlInstance $server
                $outdated = $build | Where-Object SupportedUntil -lt (Get-Date)
                $latest = Test-DbaBuild -SqlInstance $server -Latest

                if ($outdated -or -not $latest.Compliant) {
                    [PSCustomObject]@{
                        SqlInstance    = $server.Name
                        SupportedUntil = $build.SupportedUntil
                        BuildLevel     = $latest.BuildLevel
                        BuildTarget    = $latest.BuildTarget
                        Compliant      = $false
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
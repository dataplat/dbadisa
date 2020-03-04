function Test-DbsDiskSpace {
    <#
    .SYNOPSIS
        Returns a list of non-compliant disks that fall below the threshold (25% by default)

    .DESCRIPTION
        Returns a list of non-compliant disks that fall below the threshold (25% by default)

    .PARAMETER ComputerName
        The target SQL Server

    .PARAMETER Credential
        Login to the target computer using alternative credentials

    .PARAMETER Threshold
        The minimum disk space free threshold

    .PARAMETER InputObject
        Allows piping from Get-DbaDiskSpace

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79229, NonCompliantResults
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Test-DbsDiskSpace -ComputerName sql01

        Returns a list of non-compliant disks that fall below the threshold (25% by default)
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [Alias("cn", "host", "Server")]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [Sqlcollaborative.Dbatools.Computer.DiskSpace[]]$InputObject,
        [int]$Threshold = 25,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        if ($ComputerName) {
            $InputObject = Get-DbaDiskSpace -Computer $computername
        }
        $InputObject | Where-Object PercentFree -lt $Threshold
    }
}
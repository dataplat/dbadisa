function Get-DbsTimeSource {
    <#
    .SYNOPSIS
        Returns a list of non-compliant time sources

    .DESCRIPTION
        Returns a list of non-compliant time sources

    .PARAMETER ComputerName
        The target SQL Server

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79233
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsTimeSource -ComputerName sql01

        Returns a list of non-compliant time sources
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [Alias("cn", "host", "Server")]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            try {
                $partofodomain = Invoke-PSFCommand -ComputerName $computer -ScriptBlock {
                    (Get-CimInstance -ClassName Win32_ComputerSystem).PartOfDomain
                } -ErrorAction Stop

                $cmos = Invoke-PSFCommand -ComputerName $computer -ScriptBlock {
                    (w32tm /query /source) -match 'CMOS'
                } -ErrorAction Stop

                if (-not $partofdomain -or $cmos) {
                    [PSCustomObject]@{
                        ComputerName = $computer
                        DomainJoined = $partofodomain
                        CmosSource   = $cmos
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $computer" -ErrorRecord $_
            }
        }
    }
}
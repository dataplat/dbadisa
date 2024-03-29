function Get-DbsFips {
    <#
    .SYNOPSIS
        Returns a list of computers that are not FIPS compliant

    .DESCRIPTION
        Returns a list of computers that are not FIPS compliant

    .PARAMETER ComputerName
        The target server or instance

    .PARAMETER Credential
        Login to the target computer using alternative credentials.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-67871, V-79113, V-79197, V-79199, V-79203, V-79305, V-79307, V-79309, NonCompliantResults
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsFips -ComputerName sql2016, sql2017, sql2012

        Gets FIPS disabled state from sql2016, sql2017 and sql2012
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            if (-not (Test-ElevationRequirement -ComputerName $computer)) {
                return
            }
            try {
                $enabled = Invoke-PSFCommand -ComputerName $computer -ScriptBlock {
                    Get-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy | Select-Object -ExpandProperty Enabled
                }
                if ($enabled) {
                    [pscustomobject]@{
                        ComputerName = $computer
                        FipsDisabled = $($enabled -eq $false)
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure" -ErrorRecord $_ -Continue
            }
        }
    }
}
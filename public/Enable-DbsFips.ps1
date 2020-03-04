function Enable-DbsFips {
    <#
    .SYNOPSIS
        Enables FIPS

    .DESCRIPTION
        Enables FIPS

    .PARAMETER ComputerName
        The target server or instance

    .PARAMETER Credential
        Login to the target computer using alternative credentials

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-67871, V-79113, V-79197, V-79199, V-79203, V-79305, V-79307, V-79309
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Enable-DbsFips -ComputerName sql2016, sql2017, sql2012

        Enables FIPS on sql2016, sql2017 and sql2012
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
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
            if ($PSCmdlet.ShouldProcess($computer, "Enabling FIPS")) {
                try {
                    $null = Invoke-PSFCommand -ComputerName $computer -ScriptBlock { New-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy -name Enabled -value 0 -Force }
                    [pscustomobject]@{
                        ComputerName = $computer
                        FipsEnabled  = $true
                    }
                } catch {
                    Stop-PSFFunction -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}
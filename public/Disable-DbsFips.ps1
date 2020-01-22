function Disable-DbsFips {
    <#
    .SYNOPSIS
        Disables FIPS

    .DESCRIPTION
        Disables FIPS

    .PARAMETER ComputerName
        The SQL Server (or server in general) that you're connecting to.

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user.

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.


    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .LINK
        https://dbadisa.readthedocs.io/en/latest/functions/Disable-DbsFips

    .NOTES
        Tags: V-79199
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Disable-DbsFips -ComputerName sql2016, sql2017, sql2012
        Disables FIPS on sql2016, sql2017 and sql2012
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            if ($PSCmdlet.ShouldProcess($computer, "Disabling FIPS")) {
                try {
                    $null = Invoke-Command2 -ComputerName $computer -Credential $credential -ScriptBlock { New-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy -name Enabled -value 0 -Force }
                    [pscustomobject]@{
                        ComputerName = $computer
                        FipsDisabled = $true
                    }
                } catch {
                    Stop-Function -Message "Failure" -ErrorRecord $_ -Continue -EnableException:$EnableException
                }
            }
        }
    }
}
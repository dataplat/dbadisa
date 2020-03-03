function Disable-DbsCEIP {
    <#
    .SYNOPSIS
        Disables all instances of CEIP on a server via both services and the registry (x64 and x86)

    .DESCRIPTION
        Disables all instances of CEIP on a server via both services and the registry (x64 and x86)

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
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79313, V-79315
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Disable-DbsCEIP -ComputerName sql2016, sql2017, sql2012

        Disables all instances of CEIP on sql2016, sql2017 and sql2012

    .EXAMPLE
        PS C:\> Disable-DbsCEIP -ComputerName sql2016, sql2017, sql2012 -Credential ad\altdba

        Disables all instances of CEIP on sql2016, sql2017 and sql2012 using alternative Windows credentials
#>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            if ((Get-DbsCEIP -Computer $computer).Enabled) {
                if ($PSCmdlet.ShouldProcess($computer, "Disabling telemetry")) {
                    try {
                        # thanks to https://blog.dbi-services.com/sql-server-tips-deactivate-the-customer-experience-improvement-program-ceip/
                        Invoke-PSFCommand -ComputerName $computer -ScriptBlock {
                            $services = Get-Service | Where-Object Name -Like "*TELEMETRY*"
                            $services | Stop-Service
                            $services | Set-Service -StartupType Disabled
                            $keys = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server', 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server' -Recurse -ErrorAction Stop | Where-Object -Property Property -eq 'EnableErrorReporting'
                            foreach ($key in $keys) {
                                $null = $key | Set-ItemProperty -Name EnableErrorReporting -Value 0
                                $null = $key | Set-ItemProperty -Name CustomerFeedback -Value 0
                            }
                        }
                    } catch {
                        Stop-PSFFunction -Message "Failure on $computer" -ErrorRecord $_ -Continue
                    }
                }
            }
            Get-DbsCEIP -Computer $computer
        }
    }
}
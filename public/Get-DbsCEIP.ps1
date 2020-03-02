function Get-DbsCEIP {
    <#
    .SYNOPSIS
        Returns a list of accounts that have installed or modified SQL Server.

    .DESCRIPTION
        Returns a list of accounts that have installed or modified SQL Server.

    .PARAMETER ComputerName
        The SQL Server (or server in general) that you're connecting to.

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user.

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
        PS C:\> Get-DbsCEIP -ComputerName sql2016, sql2017, sql2012

        Returns a list of accounts that have isntalled or modified SQL Server on sql2016, sql2017 and sql2012
#>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            # thanks to https://blog.dbi-services.com/sql-server-tips-deactivate-the-customer-experience-improvement-program-ceip/
            try {
                Invoke-PSFCommand -ErrorAction SilentlyContinue -ComputerName $computer -Credential $Credential -ScriptBlock {
                    $enabled = $false
                    $services = Get-Service | Where-Object Name -Like "*TELEMETRY*"

                    if ($services.Status -contains 'Running') {
                        $enabled = $true
                    }

                    $keycollection = @()
                    $keys = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server', 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server' -Recurse -ErrorAction Stop | Where-Object -Property Property -eq 'EnableErrorReporting'
                    foreach ($key in $keys) {
                        $keycollection += ([PSCustomObject]@{
                                Name                 = $key.Name
                                EnableErrorReporting = ($key | Get-ItemProperty -Name EnableErrorReporting).EnableErrorReporting
                                CustomerFeedback     = ($key | Get-ItemProperty -Name CustomerFeedback).CustomerFeedback
                            } | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.Name } -PassThru -Force)
                    }

                    if ($services.Status -contains 'Running' -or $keycollection.EnableErrorReporting -contains 1 -or $keycollection.CustomerFeedback -contains 1) {
                        $enabled = $true
                    }

                    [PSCustomObject]@{
                        ComputerName = $env:COMPUTERNAME
                        Enabled      = $enabled
                        Services     = $services
                        Keys         = $keycollection
                    }
                } | Select-DefaultView -Property ComputerName, Enabled, Services, Keys

            } catch {
                Stop-PSFFunction -Message "Failure on $computer" -ErrorRecord $_ -Continue
            }
        }
    }
}
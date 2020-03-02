function Disable-DbsCEIP {
    <#
    .SYNOPSIS
        Disables CEIP

    .DESCRIPTION
        Disables CEIP

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
        PS C:\> Disable-DbsCEIP -ComputerName sql2016, sql2017, sql2012

        Disables CEIP on sql2016, sql2017 and sql2012
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
            try {
                Invoke-PSFCommand -ErrorAction SilentlyContinue -ComputerName $computer -Credential $Credential -ScriptBlock {
                    $services = Get-Service | Where-Object Name -Like "*TELEMETRY*"
                    $services | Stop-Service
                    $services | Set-Service -StartupType Disabled
                    $keys = Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server', 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Microsoft SQL Server' -Recurse -ErrorAction Stop | Where-Object -Property Property -eq 'EnableErrorReporting'
                    foreach ($key in $keys) {
                        $null = $key | Set-ItemProperty -Name EnableErrorReporting -Value 0
                        $null = $key | Set-ItemProperty -Name CustomerFeedback -Value 0
                    }
                }
                Get-DbsCEIP -Computer $computer -Credential $Credential
            } catch {
                Stop-Function -Message "Failure on $computer" -ErrorRecord $_ -Continue
            }
        }
    }
}
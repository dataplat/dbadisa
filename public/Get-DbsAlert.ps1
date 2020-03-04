function Get-DbsAlert {
    <#
    .SYNOPSIS
        Checks both Agent Alerts and Database Mail to ensure SQL Server provides immediate, real-time alerts to appropriate support staff

    .DESCRIPTION
        Checks both Agent Alerts and Database Mail to ensure SQL Server provides immediate, real-time alerts to appropriate support staff

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79231, NonCompliantResults
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsAlert -SqlInstance sql2017, sql2016, sql2012

        Checks to ensure both Agent Alerts and Database Mail to ensure SQL Server provides immediate, real-time alerts to appropriate support staff
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
                $alerts = Get-DbaAgentAlert -SqlInstance $server
                $mailserver = (Get-DbaDbMailAccount -SqlInstance $server).MailServers

                if (-not $alerts -and -not $mailserver) {
                    [PSCustomObject]@{
                        SqlInstance  = $instance
                        Compliant    = $false
                        HasAlerts    = ($null -ne $alerts)
                        HasMailSetup = ($null -ne $mailserver)
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $instance" -ErrorRecord $_ -Continue
            }
        }
    }
}
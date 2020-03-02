function Disable-DbsBrowser {
    <#
    .SYNOPSIS
        Disables and stops the SQL Server Broswer service on computers with no named instances

    .DESCRIPTION
        Disables and stops the SQL Server Broswer service on computers with no named instances

    .PARAMETER ComputerName
        The SQL Server (or server in general) that you're connecting to. This command handles named instances

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79353, V-79349
        Author: Tracy Boggiano (@TracyBoggiano), databasesuperhero.com
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Disable-DbsBrowser -ComputerName Sql2016, sql2019

        Disables and stops the SQL Server Broswer service on sql2016 and sql2019 if no named instances exist
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        $PSDefaultParameterValues['*:EnableException'] = $true
        $PSDefaultParameterValues['*:Credential'] = $Credential
    }
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            try {
                $null = Test-ElevationRequirement -ComputerName $computer
                $ports = Invoke-PSFCommand -Computer $computer -ScriptBlock {
                    [void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SqlWmiManagement')
                    $wmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
                    $null = $wmi.Initialize()
                    $wmi.ServerInstances.ServerProtocols.IPAddresses.IPAddressProperties | Where-Object { $PSItem.Name -eq 'TcpPort' -and $PSItem.Value -ne 1433 } |
                    Select-Object -Unique -Property Value
                }

                foreach ($port in $allports) {
                    Write-Message -Level Verbose -Message "Found instance with port $($port.Value) on $($env:ComputerName)"
                }

                if ($ports) {
                    $disabled = $false
                    $notes = "SQL services found on ports other than 1433"
                } else {
                    try {
                        $browser = Get-DbaService -ComputerName $Computer -Type Browser
                        $null = $browser | Stop-DbaService
                        $null = $browser | Set-Service -StartupType Disabled
                        $disabled = $true
                        $notes = "No SQL services found on ports other than 1433"
                    } catch {
                        Stop-Function -EnableException:$EnableException -Message "Error setting services on $computer" -ErrorRecord $_
                    }
                }
                if ($PSCmdlet.ShouldProcess($computer, "Showing output")) {
                    [pscustomobject]@{
                        ComputerName    = $computer
                        BrowserDisabled = $disabled
                        Notes           = $notes
                    }
                }
            } catch {
                Stop-Function -EnableException:$EnableException -Message "Error setting services on $computer" -ErrorRecord $_
            }
        }
    }
}
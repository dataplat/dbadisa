function Disable-DbsBrowser {
    <#
    .SYNOPSIS
        Disable and stop broswer service

    .DESCRIPTION
        Disable and stop broswer service on computers with no named instances

    .PARAMETER ComputerName
        The SQL Server (or server in general) that you're connecting to. This command handles named instances.

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags:V-79353, V-79349
        Author: Tracy Boggiano (@TracyBoggiano), databasesuperhero.com
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Disable-DbsBrowser -ComputerName Sql2016

        Disables and stops Browser service is not named instances exist
#>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            $allports = Get-DbaTcpPort -SqlInstance $Computer -Credential $Credential -All -EnableException:$EnableException
            $ports = $allports | Where-Object Port -ne 1433

            foreach ($port in $allports) {
                Write-Message -Level Verbose -Message "Found instance $($port.InstanceName) on $($port.ComputerName) with IP $($port.IPAddress) on port $($port.Port)"
            }
            if ($ports) {
                $disabled = $false
                $notes = "SQL services found on ports other than 1433"
            } else {
                try {
                    $browser = Get-DbaService -ComputerName $Computer -Type Browser -EnableException:$EnableException
                    $null = $browser | Stop-DbaService -EnableException:$EnableException
                    $null = $browser | Set-Service -StartupType Disabled
                    $disabled = $true
                    $notes = "No SQL services found on ports other than 1433"
                } catch {
                    Stop-Function -EnableException:$EnableException -Message "Error setting services on $computer" -ErrorRecord $_
                }
            }

            [pscustomobject]@{
                ComputerName    = $computer
                BrowserDisabled = $disabled
                Notes           = $notes
            }
        }
    }
}
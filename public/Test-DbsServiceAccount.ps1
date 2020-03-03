function Test-DbsServiceAccount {
    <#
    .SYNOPSIS
        Tests all SQL Server related services on a server to ensure none have the same service account

    .DESCRIPTION
        Tests all SQL Server related services on a server to ensure none have the same service account

    .PARAMETER ComputerName
        The target SQL Server

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79245
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Test-DbsServiceAccount -ComputerName sql01

        Tests all SQL Server related services to ensure none have the same service account
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
            $services = Get-DbaService -ComputerName $computer
            # no sql service account must be the same on the same computer, no matter the instance
            foreach ($service in $services) {
                $accounts = $services | Where-Object StartName -eq $service.StartName
                if ($accounts.Count -gt 1) {
                    $service | Add-Member -NotePropertyName DuplicateCount -NotePropertyValue $accounts.Count -Passthru |
                    Select-DefaultView -Property ComputerName, ServiceName, ServiceType, InstanceName, DisplayName, StartName, State, StartMode, DuplicateCount
                }
            }
        }
    }
}
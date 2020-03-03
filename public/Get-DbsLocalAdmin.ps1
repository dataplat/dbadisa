function Get-DbsLocalAdmin {
    <#
    .SYNOPSIS
        Gets a list of Windows administrators on a SQL Server

    .DESCRIPTION
        Gets a list of Windows administrators on a SQL Server

    .PARAMETER ComputerName
        The target SQL Server

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79237
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsLocalAdmin -ComputerName sql01

        Gets a list of Windows administrators on a SQL Server
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
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            try {
                $results = Invoke-PSFCommand -ComputerName $computer -ScriptBlock { Get-LocalGroupMember -Name Administrators } -ErrorAction Stop
                foreach ($result in $results) {
                    [PSCustomObject]@{
                        ComputerName = $computer
                        Type         = $result.ObjectClass
                        Account      = $result.Name
                        Source       = $result.PrincipalSource
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $computer" -ErrorRecord $_
            }
        }
    }
}
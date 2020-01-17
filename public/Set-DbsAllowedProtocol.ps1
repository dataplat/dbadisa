function Set-DbsAllowedProtocol {
    <#
    .SYNOPSIS
        Disables all non-tcp protocols for all instances on a computer, enables TCP

    .DESCRIPTION
        Disables all non-tcp protocols for all instances on a computer, enables TCP

        Settings go into effect after the SQL Service has been restarted

    .PARAMETER ComputerName
        The target SQL Server

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
        Tags: DISA, STIG
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsAllowedProtocol -ComputerName sql01

        Disables all protocols except for tcp for all instances on sql01

    .EXAMPLE
        PS C:\> Set-DbsAllowedProtocol -ComputerName sql01 -Whatif

        Shows what protocols on what instance would be disabled if the command would run
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(ValueFromPipeline)]
        [Alias("cn", "host", "Server")]
        [DbaInstanceParameter[]]$ComputerName = $env:COMPUTERNAME,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            $protocols = Get-DbaInstanceProtocol -ComputerName $computer -Credential $Credential
            foreach ($protocol in $protocols) {
                if ($protocol.Name -eq 'Tcp') {
                    if ($PSCmdlet.ShouldProcess($computer, "Enabling $($protocol.Name) for $($protocol.InstanceName)")) {
                        $return = [bool](($protocol.Enable()).ReturnValue)
                        if ($return -eq 0) { $results = "False" } else { $results = "True" }
                        $protocol | Add-Member -NotePropertyName Disabled -NotePropertyValue $results
                        $protocol | Add-Member -NotePropertyName Notes -NotePropertyValue "Restart required" -PassThru |
                        Select-DefaultView -Property ComputerName, DisplayName, InstanceName, Disabled, Notes
                    }
                } else {
                    if ($PSCmdlet.ShouldProcess($computer, "Disabling $($protocol.Name) for $($protocol.InstanceName)")) {
                        $return = [bool](($protocol.Disable()).ReturnValue)
                        if ($return -eq 0) { $results = "True" } else { $results = "False" }
                        $protocol | Add-Member -NotePropertyName Disabled -NotePropertyValue $results
                        $protocol | Add-Member -NotePropertyName Notes -NotePropertyValue "Restart required" -PassThru |
                        Select-DefaultView -Property ComputerName, DisplayName, InstanceName, Disabled, Notes
                    }
                }
            }
        }
    }
}
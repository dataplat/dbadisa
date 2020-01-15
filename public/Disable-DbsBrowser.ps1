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
            Tags: DISA, STIG
            Author: Tracy Boggiano (@TracyBoggiano), databasesuperhero.com
            Copyright: (c) 2010 by Chrissy LeMaire, licensed under MIT
            License: MIT https://opensource.org/licenses/MITl

        .EXAMPLE
            PS C:\> Disable-DbsBrowser -ComputerName Sql2016
            Disables and stops Browser service is not named instances exist

        .LINK
        https://dbadisa.readthedocs.io/en/latest/functions/Disable-DbsBrowser/
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [string[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )

    process {
        foreach ($Computer in $ComputerName) {
            $instanceNames = @()

            $instances = Get-DbaService -ComputerName $Computer -Type Engine -Credential $Crendential

            ForEach ($instance in $instances) {
                if ($instance.InstanceName -ne "MSSQLSERVER") {
                    $instanceName = [pscustomobject] @{
                        InstanceName = $instance.InstanceName
                    }
                    $instanceNames += $instanceName
                }
            }

            if ($instanceNames.Count -eq 0) {
                $null = Stop-DbaService -ComputerName $Computer -Type Browser
                $null = Set-Service -ComputerName $Computer -DisplayName Browser -StartupType Disabled

            } else {
                foreach ($name in $instanceNames) {
                    Write-Message -Level Verbose -Message "The Browser was not disabled on $computer because instance $($name.InstanceName) exist."
                }
            }
        }
    }
}
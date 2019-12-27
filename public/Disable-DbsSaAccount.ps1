function Disable-DbsSaAccount {
    <#
        .SYNOPSIS
            Disable and rename sa account

        .DESCRIPTION
            Disable and rename sa account

        .PARAMETER SqlInstance
            The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

        .PARAMETER SqlCredential
            Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

            Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

            For MFA support, please use Connect-DbaInstance.

        .PARAMETER NewName
            NewName for sa account

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
            PS C:\> Disable-DbsSaAccount -SqlInstance Sql2016 -NewName newsa
            Disables and renames sa account

        .LINK
        https://dbadisa.readthedocs.io/en/latest/functions/Disable-DbsSaAccount/
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(Mandatory)]
        [string]$NewName,
        [switch]$EnableException
    )

    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $sqlcredential -MinimumVersion 11
            } catch {
                Stop-Function -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            try {
                if ($server.VersionMajor -ge 11) {
                    $login = Get-DbaLogin -SqlInstance $server | Where-Object Id -eq 1 -and Name -eq "sa"

                    if ($null -ne $login.Name) {

                    }
                }
            } catch {
                Stop-Function -Message "Failed to install stored procedure." -ErrorRecord $_ -Continue -Target $instance
            }
        }
    }
}
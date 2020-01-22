function Get-DbsFips {
    <#
    .SYNOPSIS
        Returns a list of computers that are not FIPS compliant

    .DESCRIPTION
        Returns a list of computers that are not FIPS compliant

    .PARAMETER ComputerName
        The SQL Server (or server in general) that you're connecting to.

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags:
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbadisa.readthedocs.io/en/latest/functions/Get-DbsFips

    .EXAMPLE
        PS C:\> Get-DbsFips -ComputerName sql2016, sql2017, sql2012

        Gets FIPS disabled state from sql2016, sql2017 and sql2012
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
                $enabled = Invoke-Command2 -ComputerName $computer -Credential $credential -ScriptBlock {
                    Get-ItemProperty HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy | Select-Object -ExpandProperty Enabled
                } -Raw
                if ($enabled) {
                    [pscustomobject]@{
                        ComputerName = $computer
                        FipsDisabled = $($enabled -eq $false)
                    }
                }
            } catch {
                Stop-Function -Message "Failure" -ErrorRecord $_ -Continue -EnableException:$EnableException
            }
        }
    }
}
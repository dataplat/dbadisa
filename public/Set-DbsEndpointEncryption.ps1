function Set-DbsEndpointEncryption {
    <#
    .SYNOPSIS
        Sets non-compliant endpoint encryption algorithms for non-compliant endpoints

    .DESCRIPTION
        Sets non-compliant endpoint encryption algorithms for non-compliant endpoints

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79323
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsEndpointEncryption -SqlInstance sql2017, sql2016, sql2012 | Set-DbsEndpointEncryption

        Sets non-compliant endpoint encryption algorithms to AES on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsEndpointEncryption -SqlInstance sql2017, sql2016, sql2012 | Out-GridView -Passthru | Set-DbsEndpointEncryption

        Sets selected non-compliant endpoint encryption algorithms to AES on sql2017, sql2016 and sql2012
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Endpoint[]]$InputObject,
        [switch]$EnableException
    )
    process {
        foreach ($endpoint in $InputObject) {
            if ($PSCmdlet.ShouldProcess($endpoint.Parent.name, "Changing endpoint $($endpoint.Name) encryption from $($endpoint.Algorithm) to AES")) {
                $endpoint.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm = [Microsoft.SqlServer.Management.Smo.EndpointEncryptionAlgorithm]::Aes
                $endpoint.Alter()
                [PSCustomObject]@{
                    SqlInstance = $endpoint.Parent.Name
                    Name        = $endpoint.Name
                    Algorithm   = "Aes"
                }
            }
        }
    }
}
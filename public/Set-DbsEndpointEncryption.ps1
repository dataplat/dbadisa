function Set-DbsEndpointEncryption {
    <#
    .SYNOPSIS
        Sets non-compliant endpoint encryption algorithms for non-compliant endpoints

    .DESCRIPTION
        Sets non-compliant endpoint encryption algorithms for non-compliant endpoints

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER InputObject
        Allows piping from Get-DbaEndpoint

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79323, V-79325
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
            $result = [PSCustomObject]@{
                SqlInstance                = $endpoint.Parent.Name
                Name                       = $endpoint.Name
                DatabaseMirroringAlgorithm = $result.DatabaseMirroringAlgorithm
                ServiceBrokerAlgorithm     = $result.ServiceBrokerAlgorithm
            }
            if ($endpoint.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm) {
                if ($PSCmdlet.ShouldProcess($endpoint.Parent.name, "Changing database mirroring endpoint $($endpoint.Name) encryption from $($endpoint.Algorithm) to AES")) {
                    $endpoint.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm = [Microsoft.SqlServer.Management.Smo.EndpointEncryptionAlgorithm]::Aes
                    $endpoint.Alter()
                    $result.DatabaseMirroringAlgorithm = "Aes"
                }
            }
            if ($endpoint.Payload.ServiceBroker.EndpointEncryptionAlgorithm) {
                if ($PSCmdlet.ShouldProcess($endpoint.Parent.name, "Changing service broker endpoint $($endpoint.Name) encryption from $($endpoint.Algorithm) to AES")) {
                    $endpoint.Payload.ServiceBroker.EndpointEncryptionAlgorithm = [Microsoft.SqlServer.Management.Smo.EndpointEncryptionAlgorithm]::Aes
                    $endpoint.Alter()
                    $result.ServiceBrokerAlgorithm = "Aes"
                }
            }
            $result
        }
    }
}
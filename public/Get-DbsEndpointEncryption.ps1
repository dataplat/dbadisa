function Get-DbsEndpointEncryption {
    <#
    .SYNOPSIS
        Gets a list of non-compliant endpoint encryption algorithms

    .DESCRIPTION
        Gets a list of non-compliant endpoint encryption algorithms

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79323, V-79325, NonCompliantResults
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsEndpointEncryption -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant endpoint encryption algorithms on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsEndpointEncryption -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\startupproc.csv -NoTypeInformation

        Gets a list of non-compliant endpoint encryption algorithms on sql2017, sql2016 and sql2012 to D:\disa\startupproc.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        $endpoints = Get-DbaEndpoint @PSBoundParameters | Where-Object {
            ($PSItem.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm -and $PSItem.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm -ne 'AES') -or
            ($PSItem.Payload.ServiceBroker.EndpointEncryptionAlgorithm -and $PSItem.Payload.ServiceBroker.EndpointEncryptionAlgorithm -ne 'AES')
        }
        foreach ($endpoint in $endpoints) {
            $endpoint |
            Add-Member -MemberType NoteProperty -Name DatabaseMirroringAlgorithm -Value $endpoint.Payload.DatabaseMirroring.EndpointEncryptionAlgorithm -PassThru |
            Add-Member -MemberType NoteProperty -Name ServiceBrokerAlgorithm -Value $endpoint.Payload.ServiceBroker.EndpointEncryptionAlgorithm -PassThru |
            Select-DefaultView -Property SqlInstance, Id, Name, DatabaseMirroringAlgorithm, ServiceBrokerAlgorithm, Port, EndpointState, EndpointType, Owner, IsAdminEndpoint, Fqdn, IsSystemObject
        }
    }
}
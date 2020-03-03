function Get-DbsDbOwnerFixedServerRole {
    <#
    .SYNOPSIS
        Gets a listing of user databases whose owner is a member of a fixed server role

    .DESCRIPTION
        Gets a listing of user databases whose owner is a member of a fixed server role

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbaDatabase

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79111
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbOwnerFixedServerRole -SqlInstance sql2017, sql2016, sql2012

        Gets a listing of user databases whose owner is a member of a fixed server role for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbOwnerFixedServerRole -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\fixedserverrole.csv -NoTypeInformation

        Exports a list of user databases whose owner is a member of a fixed server role for all databases on sql2017, sql2016 and sql2012 to D:\disa\fixedserverrole.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        try {
            $server = Connect-DbaInstance -SqlInstance $instance -MinimumVersion 11
        } catch {
            Stop-PSFFunction -Message "Failure on $($server.Name)" -ErrorRecord $_ -Continue
        }

        foreach ($instance in $SqlInstance) {
            try {
                $roles = Get-DbaServerRole -SqlInstance $server | Where-Object IsFixedRole
                $dbs = Get-DbaDatabase -SqlInstance $server -ExcludeSystem
                foreach ($db in $dbs) {

                    $fixedrolesmatch = $roles | Where-Object Login -contains $db.Owner
                    foreach ($match in $fixedrolesmatch) {
                        [PSCustomObject]@{
                            SqlInstance = $db.SqlInstance
                            Database    = $db.Name
                            Owner       = $db.Owner
                            FixedRole   = $match.Role
                            db          = $db
                        } | Select-DefaultView -Property SqlInstance, Database, Owner, FixedRole
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
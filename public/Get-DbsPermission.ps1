function Get-DbsPermission {
    <#
    .SYNOPSIS
        Gets a list of instance permissions using the 'Instance permissions assignments to logins and roles.sql' file provided by DISA

    .DESCRIPTION
        Gets a list of instance permissions using the 'Instance permissions assignments to logins and roles.sql' file provided by DISA

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79125
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsPermission -SqlInstance sql2017, sql2016, sql2012

        Gets a list of instance permissions for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsPermission -SqlInstance sql2017, sql2016, sql2012

        Gets a list of instance permissions for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsPermission -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\instanceperms.csv -NoTypeInformation

        Exports a list of instance permissions for all databases on sql2017, sql2016 and sql2012 to D:\disa\instanceperms.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
        $sql = [IO.File]::ReadAllText("$script:ModuleRoot\bin\sql\Instance permissions assignments to logins and roles.sql")
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance
                $results = $server.Query($sql)
                foreach ($result in $results) {
                    [pscustomobject]@{
                        SqlInstance    = $server.Name
                        SecurableClass = $result.'Securable Class'
                        Securable      = $result.Securable
                        Grantee        = $result.Grantee
                        GranteeType    = $result.'Grantee Type'
                        Permission     = $result.Permission
                        State          = $result.State
                        Grantor        = $result.Grantor
                        GrantorType    = $result.'Grantor Type'
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
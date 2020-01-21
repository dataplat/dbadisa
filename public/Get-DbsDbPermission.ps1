function Get-DbsDbPermission {
    <#
    .SYNOPSIS
        Gets a list of database permissions.

    .DESCRIPTION
        Gets a list of database permissions.

        Uses the Database permission assignments to users and roles.sql file provided by DISA.

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
        Tags: DISA, STIG
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbPermission -SqlInstance sql2017, sql2016, sql2012

        Gets a list of database permissions for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbPermission -SqlInstance sql2017, sql2016, sql2012

        Gets a list of database permissions for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbPermission -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\dbperms.csv -NoTypeInformation

        Exports a list of database permissions for all databases on sql2017, sql2016 and sql2012 to D:\disa\dbperms.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        $sql = [IO.File]::ReadAllText("$script:ModuleRoot\bin\sql\Database permission assignments to users and roles.sql")
    }
    process {
        $databases = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential | Get-DbaDatabase
        foreach ($db in $databases) {
            try {
                $results = $db.Query($sql)
            } catch {
                Stop-Function -Message "Failure for $($db.Name) on $($db.Parent.Name)" -ErrorRecord $_ -Continue -EnableException:$EnableException
            }
            foreach ($result in $results) {
                [pscustomobject]@{
                    SqlInstance          = $db.Parent.Name
                    Database             = $db.name
                    SecurableTypeOrClass = $result.'Securable Type or Class'
                    SchemaOrOwner        = $result.'Schema/Owner'
                    Securable            = $result.Securable
                    Column               = $result.Column
                    GranteeType          = $result.'Grantee Type'
                    Grantee              = $result.Grantee
                    Permission           = $result.Permission
                    Grantor              = $result.Grantor
                    GrantorType          = $result.'Grantor Type'
                }
            }
        }
    }
}
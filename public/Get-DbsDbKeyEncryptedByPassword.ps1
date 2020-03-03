function Get-DbsDbKeyEncryptedByPassword {
    <#
    .SYNOPSIS
       Returns a list of non-compliant Database Master Key that are not encrypted by the Service Master Key

    .DESCRIPTION
       Returns a list of non-compliant Database Master Key that are not encrypted by the Service Master Key

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

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
        Tags: V-79085
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbKeyEncryptedByPassword -SqlInstance sql2017, sql2016, sql2012

       Returns a list of non-compliant Database Master Key that are not encrypted by the Service Master Key for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbKeyEncryptedByPassword -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\access.csv -NoTypeInformation

       Returns a list of non-compliant Database Master Key that are not encrypted by the Service Master Key for all databases on sql2017, sql2016 and sql2012 to D:\disa\access.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
        $sql = "SELECT @@SERVERNAME as SqlInstance, name as [Database], COUNT(name) as Count
                FROM sys.symmetric_keys s, sys.key_encryptions k
                WHERE s.name = '##MS_DatabaseMasterKey##'
                AND s.symmetric_key_id = k.key_id
                AND k.crypt_type = 'ESKP'"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeSystem
        }

        foreach ($db in $InputObject) {
            try {
                Write-PSFMessage -Message "Processing $($db.Name) on $($db.Parent.Name)"
                $db.Query($sql)
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
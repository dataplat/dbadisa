function Get-DbsDbTde {
    <#
    .SYNOPSIS
       Returns a list of non-compliant (unencrypted) databases

    .DESCRIPTION
       Returns a list of non-compliant (unencrypted) databases

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
        Tags: V-79115, V-79117, V-79205
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbTde -SqlInstance sql2017, sql2016, sql2012

        Returns a list of non-compliant (unencrypted) databases for all databases on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbTde -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\access.csv -NoTypeInformation

        Returns a list of non-compliant (unencrypted) databases for all databases on sql2017, sql2016 and sql2012 to D:\disa\access.csv
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
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeSystem
        }

        foreach ($db in $InputObject) {
            try {
                if (-not $db.EncryptionEnabled) {
                    $db | Select-DefaultView -Property SqlInstance, 'Name as Database', EncryptionEnabled
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
            }
        }

        <#
        Write-PSFMessage -Message "Executing sql on $($db.Name) for $($db.Parent.Name)"
        $db.Query($sql)
        turns out, not going to use this
        $sql = "SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database],
                CASE Encryption_state
                WHEN 0 THEN 'No database encryption key present, no encryption'
                WHEN 1 THEN 'Unencrypted'
                WHEN 2 THEN 'Encryption in progress'
                WHEN 3 THEN 'Encrypted'
                WHEN 4 THEN 'Key change in progress'
                WHEN 5 THEN 'Decryption in progress'
                WHEN 6 THEN 'Protection change in progress'
                END AS [EncryptionState]
                FROM sys.dm_database_encryption_keys"
        #>
    }
}
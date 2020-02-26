function Get-DbsDbSchemaOwner {
    <#
    .SYNOPSIS
        Returns a list of all schema owners

    .DESCRIPTION
        Returns a list of all schema owners

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
        Tags: V-79077
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbSchemaOwner -SqlInstance sql2017, sql2016, sql2012

        Returns a list of all schema owners

    .EXAMPLE
        PS C:\> Get-DbsDbSchemaOwner -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\schemaowners.csv -NoTypeInformation

        Exportsa list of all schema owners for all databases on sql2017, sql2016 and sql2012 to D:\disa\schemaowners.csv
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
        $sql = "SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database], S.name AS SchemaName, P.name AS OwningPrincipal
                        FROM sys.schemas S
                        JOIN sys.database_principals P ON S.principal_id = P.principal_id
                        ORDER BY S.name"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -EnableException:$EnableException -ExcludeSystem
        }

        foreach ($db in $InputObject) {
            $dbs = $db.Parent.Databases
            try {
                Write-PSFMessage -Level Verbose -Message "Processing $($db.Name) on $($db.Parent.Name)"
                $results = $db.Query($sql)
                foreach ($result in $results) {
                    [PSCustomObject]@{
                        SqlInstance     = $result.SqlInstance
                        Database        = $result.Database
                        SchemaName      = $result.SchemaName
                        OwningPrincipal = $result.OwningPrincipal
                        db              = ($dbs | Where-Object Name -eq $result.Database)
                    } | Select-DefaultView -Property SqlInstance, Database, SchemaName, OwningPrincipal
                }
            } catch {
                Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
function Get-DbsDbExternalProcessAccess {
    <#
    .SYNOPSIS
        Returns a listing of accounts currently configured for use by external processes.

    .DESCRIPTION
        Returns a listing of accounts currently configured for use by external processes.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbaDatabase

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79221
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbExternalProcessAccess -SqlInstance sql2017, sql2016, sql2012

        Returns a listing of accounts currently configured for use by external processes for sql2017, sql2016 and sql2012
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
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase @PSBoundParameters -ExcludeDatabase msdb
        }
        foreach ($db in $InputObject) {
            try {
                $db.Query("SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database],
                        'Credential' as [Type], C.Name as CredentialName,
                        NULL as ProxyName, C.credential_identity as [Identity]
                        FROM sys.credentials C
                        UNION
                        SELECT @@SERVERNAME as SqlInstance, DB_NAME() as [Database],
                        'Proxy' as [Type], C.Name as CredentialName, P.name AS ProxyName,
                        C.credential_identity as [Identity]
                        FROM sys.credentials C
                        JOIN msdb.dbo.sysproxies P ON C.credential_id = P.credential_id
                        WHERE P.enabled = 1")
            } catch {
                Stop-PSFFunction -Message "Failure for database $($db.Name) on $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
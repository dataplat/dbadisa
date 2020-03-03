function Get-DbsSystemPermission {
    <#
    .SYNOPSIS
        Gets permissions that were identified as not allowed in the check content

    .DESCRIPTION
        Gets permissions that were identified as not allowed in the check content

    .PARAMETER SqlInstance
        The target SQL Server instance or instances Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79129
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsSystemPermission -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant audit states on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsSystemPermission -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant audit states on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsSystemPermission -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\auditstates.csv -NoTypeInformation

        Gets a list of non-compliant audit states sql2017, sql2016 and sql2012 to D:\disa\auditstates.csv
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
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance
                $cluster = $server.Query("SELECT SERVERPROPERTY('IsClustered') as IsClustered, SERVERPROPERTY('IsHadrEnabled') as IsHadrEnabled")

                if ($cluster.IsClustered -and $cluster.IsHadrEnabled) {
                    $collection = "CONNECT SQL", "ALTER ANY AVAILABILITY GROUP", "VIEW SERVER STATE ", "VIEW ANY DATABASE"
                } elseif ($cluster.IsClustered -and -not $cluster.IsHadrEnabled) {
                    $collection = "CONNECT SQL", "VIEW SERVER STATE ", "VIEW ANY DATABASE"
                } elseif (-not $cluster.IsClustered -and $cluster.IsHadrEnabled) {
                    $collection = "CONNECT SQL", "ALTER ANY AVAILABILITY GROUP", "VIEW ANY DATABASE"
                } else {
                    $collection = "CONNECT SQL", "VIEW ANY DATABASE"
                }

                $results = $server.Query("EXECUTE AS LOGIN = 'NT AUTHORITY\SYSTEM'
                                SELECT permission_name FROM fn_my_permissions(NULL,NULL)
                                REVERT")

                $results = $results | Where-Object permission_name -notin $collection
                foreach ($result in $results.permission_name) {
                    [pscustomobject]@{
                        SqlInstance = $server.Name
                        Login       = "NT AUTHORITY\SYSTEM"
                        Permission  = $result
                        Server      = $server
                    } | Select-DefaultView -Property SqlInstance, Login, Permission
                }
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
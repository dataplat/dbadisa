function Remove-DbsSystemPermission {
    <#
    .SYNOPSIS
        Remoes non-compliant audit states.

    .DESCRIPTION
       Removes non-compliant audit states.

       If you remove permissions for 'NT AUTHORITY\SYSTEM' using this command and they continue to persist, check to ensure
       that the permissions are not granted by a role such as sysadmin.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

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
        PS C:\> Remove-DbsSystemPermission -SqlInstance sql2017, sql2016, sql2012

        Gets a list of non-compliant audit states on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Remove-DbsSystemPermission -SqlInstance sql2017, sql2016 and sql2012

        Removes all non-compliant permissions for NT AUTHORITY\SYSTEM on sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsSystemPermission -SqlInstance sql2014 | Out-GridView -PassThru | Remove-DbsSystemPermission

        Gets a list of non-compliant permissions for NT AUTHORITY\SYSTEM, prompts to select specific permissions, then removes the selected permissions
    #>
    [CmdletBinding()]
    param (
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(ValueFromPipeline)]
        [pscustomobject[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if ($SqlInstance) {
            $servers = Connect-DbaInstance -SqlInstance $SqlInstance -SqlCredential $SqlCredential
            foreach ($server in $servers) {
                try {
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
                        $sql = "REVOKE $result TO [NT AUTHORITY\SYSTEM]"
                        Write-PSFMessage -Level Verbose -Message $sql
                        $server.Query($sql)

                        $sql = "REVOKE EXEC ON $result From [NT AUTHORITY\SYSTEM]"
                        Write-PSFMessage -Level Verbose -Message $sql
                        $server.Query($sql)

                        [pscustomobject]@{
                            SqlInstance = $server.Name
                            Permission  = $result
                            Login       = "NT AUTHORITY\SYSTEM"
                            Revoked     = $true
                        }
                    }
                } catch {
                    Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue -EnableException:$EnableException
                }
            }
        }

        foreach ($item in $InputObject) {
            try {
                $server = $item.Server
                $result = $item.Permission
                $sql = "REVOKE $result TO [NT AUTHORITY\SYSTEM]"
                Write-PSFMessage -Level Verbose -Message $sql
                $server.Query($sql)

                $sql = "REVOKE EXEC ON $result From [NT AUTHORITY\SYSTEM]"
                Write-PSFMessage -Level Verbose -Message $sql
                $server.Query($sql)

                [pscustomobject]@{
                    SqlInstance = $server.Name
                    Permission  = $result
                    Login       = "NT AUTHORITY\SYSTEM"
                    Revoked     = $true
                }
            } catch {
                Stop-PSFFunction -Message "Failure for $($server.Name)" -ErrorRecord $_ -Continue -EnableException:$EnableException
            }
        }
    }
}
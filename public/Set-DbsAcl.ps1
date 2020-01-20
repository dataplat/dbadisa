function Set-DbsAcl {
    <#
    .SYNOPSIS
        Sets the permissions required by DISA for SQL Server directories.

    .DESCRIPTION
        Sets the required permissions for SQL Server directories.

        By default, it will detect and secure the default Data, Log and Backup directories.

        Currently, this is accomplished using admin UNC shares so they should be available to your account.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER Account
        The account name or names that are to be granted permissions along with the service accounts.

    .PARAMETER Path
        By default, the ACLs on the paths to the data, log and backup files will be modified.

        If you want to set permissions on a specific path, use this option.

        Note that if your Backup directory is a UNC share, it will be skipped.

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER Force
        If this switch is enabled, the sp_WhoisActive will be downloaded from the internet even if previously cached.

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
        PS C:\> Set-DbsAcl -SqlInstance sql2017, sql2016, sql2012 -Account "AD\SQL Admins"

        Sets permissions for the default data, log and backups on sql2017, sql2016, sql2012.

        Adds appropriate permissions for the "AD\SQL Admins" group as well as the SQL Server service accounts.

    .EXAMPLE
        PS C:\> Get-DbaRegServer -SqlInstance sqlcentral | Set-DbsAcl -Account "AD\SQL Admins"

        Sets the appropriate permissions for all SQL Servers stored in the sqlcentral registered server.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(Mandatory)]
        [string[]]$Account,
        [string[]]$Path,
        [switch]$EnableException
    )

    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-SqlInstance -SqlInstance $instance -SqlCredential $sqlcredential
            } catch {
                Stop-Function -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            if (-not $PSBoundParameters.Path) {
                $defaults = Get-DbaDefaultPath -SqlInstance $server
                $Path = $defaults.Data, $defaults.Log, $defaults.Backup | Where-Object { $_ -notmatch '\\\\' } | Select-Object -Unique
            }

            if ($PSCmdlet.ShouldProcess($instance, "Changing permissions for $Path for $instance")) {
                try {
                    $instancename = $instance.InstanceName
                    $services = Get-DbaService -ComputerName $instance
                    $dbengine = $services | Where-Object DisplayName -match "SQL Server \($instancename\)"
                    $dbaccount = $dbengine.StartName
                    $agentengine = $services | Where-Object DisplayName -match "SQL Server Agent \($instancename\)"
                    $agentaccount = $agentengine.StartName

                    if ($dbaccount.length -lt 2) {
                        Stop-Function -Message "Couldn't get service information for $instance, moving on" -Continue
                    }

                    foreach ($folder in $Path) {
                        Write-Message -Level Verbose -Message "Modifying $folder on $instance"
                        $remote = Join-AdminUnc -Servername $server.ComputerName -FilePath $folder

                        try {
                            $acl = Get-Acl -Path $remote
                            $acl.SetAccessRuleProtection($true, $true)
                            $null = Set-Acl -Path $remote -AclObject $acl
                        } catch {
                            Stop-Function -Message "Issing setting file permissions on $remote" -ErrorRecord $_ -Continue

                        }

                        $acl = Get-Acl -Path $remote
                        $access = $acl.Access

                        foreach ($a in $access) {
                            $null = $acl.RemoveAccessRule($a)
                        }

                        # Add local admin
                        $accountdisplay = @()
                        foreach ($username in $Account) {
                            $accountdisplay += $username
                            $permission = $username, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                            $acl.SetAccessRule($rule)
                        }

                        $accountdisplay += $dbaccount
                        $permission = "$dbaccount", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                        $acl.SetAccessRule($rule)

                        if ($dbaccount -ne $agentaccount) {
                            $accountdisplay += $agentaccount
                            $permission = "$agentaccount", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                            $acl.SetAccessRule($rule)
                        }
                        $null = Set-Acl -Path $remote -AclObject $acl
                    }

                    [PSCustomObject]@{
                        ComputerName        = $server.ComputerName
                        InstanceName        = $server.ServiceName
                        SqlInstance         = $server.DomainInstanceName
                        Account             = $accountdisplay -join ", "
                        Status              = "Success"
                        Path                = $Path -join ", "
                        PreviousPermissions = $access
                    }
                } catch {
                    Stop-Function -Message "Failed to set permissions on $instance" -ErrorRecord $_ -Continue -Target $instance
                }
            }
        }
    }
}
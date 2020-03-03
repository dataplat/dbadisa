function Set-DbsAcl {
    <#
    .SYNOPSIS
        Sets the permissions required by DISA for SQL Server directories.

    .DESCRIPTION
        Sets the required permissions for SQL Server directories.

        By default, it will detect and secure the default Data, Log and Backup directories.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

        This is required to get specific information about the paths to modify. The base computer name is also used to
        perform the actual modifications.

    .PARAMETER SqlCredential
        Login to the target _SQL Server_ instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

    .PARAMETER Credential
        Login to the target _Windows_ server using alternative credentials. Accepts PowerShell credentials (Get-Credential).

    .PARAMETER Owner
        The account that will be set as the folder owner.

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
        Tags: V-79215, V-79151, V-79153, V-79155, V-79163
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsAcl -SqlInstance sql2017, sql2016, sql2012 -Account "AD\SQL Admins" -Owner "AD\SQL Service"

        Sets permissions for the default data, log and backups on sql2017, sql2016, sql2012.

        Adds appropriate permissions for the "AD\SQL Admins" group as well as the SQL Server service accountsas Full Access.

        Also sets the owner of the folder to "AD\SQL Service"

    .EXAMPLE
        PS C:\> Get-DbaRegServer -SqlInstance sqlcentral | Set-DbsAcl -Account "AD\SQL Admins" -Owner "AD\SQL Service"

        Sets the appropriate permissions for all SQL Servers stored in the sqlcentral registered server.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [PsCredential]$Credential,
        [parameter(Mandatory)]
        [string]$Owner,
        [parameter(Mandatory)]
        [string[]]$Account,
        [string[]]$Path,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($instance in $SqlInstance) {
            try {
                $server = Connect-DbaInstance -SqlInstance $instance
            } catch {
                Stop-PSFFunction -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            if (-not $PSBoundParameters.Path) {
                $defaults = Get-DbaDefaultPath -SqlInstance $server
                $Path = $defaults.Data, $defaults.Log, $defaults.Backup | Where-Object { $_ -notmatch '\\\\' } | Select-Object -Unique
            }

            try {
                $computername = $instance.ComputerName
                $instancename = $instance.InstanceName
                $services = Get-DbaService -ComputerName $instance 3>$null
                $dbengine = $services | Where-Object DisplayName -match "SQL Server \($instancename\)"
                $dbaccount = $dbengine.StartName
                $agentengine = $services | Where-Object DisplayName -match "SQL Server Agent \($instancename\)"
                $agentaccount = $agentengine.StartName

                if ($dbaccount.length -lt 2) {
                    Stop-PSFFunction -Message "Couldn't get service information for $instance, moving on" -Continue
                }

                foreach ($folder in $Path) {
                    Write-PSFMessage -Level Verbose -Message "Modifying $folder on $computername"

                    if ($PSCmdlet.ShouldProcess($computername, "Removing permission protections for $folder")) {
                        try {
                            Invoke-PSFCommand -ComputerName $computername -ScriptBlock {
                                param ($folder)
                                # set it as a script variable to ensure it persists in the session, may be excessive
                                $script:acl = Get-Acl -Path $folder -ErrorAction Stop
                                $script:acl.SetAccessRuleProtection($true, $true)
                                $null = Set-Acl -Path $folder -AclObject $script:acl -ErrorAction Stop
                            } -ArgumentList $folder -ErrorAction Stop
                        } catch {
                            Stop-PSFFunction -Message "Issue setting file permissions on $folder" -ErrorRecord $_ -Continue
                        }
                    }

                    if ($PSCmdlet.ShouldProcess($computername, "Collecting all access rules for $folder")) {
                        try {
                            $access = Invoke-PSFCommand -ComputerName $computername -ScriptBlock {
                                param ($folder)
                                (Get-Acl -Path $folder -ErrorAction Stop).Access
                            } -ArgumentList $folder -ErrorAction Stop
                        } catch {
                            Stop-PSFFunction -Message "Issue collecting file permissions on $folder" -ErrorRecord $_ -Continue
                        }
                    }

                    if ($PSCmdlet.ShouldProcess($computername, "Removing all access rules for $folder")) {
                        try {
                            Invoke-PSFCommand -ComputerName $computername -ScriptBlock {
                                param ($folder, $VerbosePreference)
                                $script:acl = Get-Acl -Path $folder
                                $access = $script:acl.Access

                                foreach ($a in $access) {
                                    $accessrule = "$($a.IdentityReference) - $($a.AccessControlType) - $($a.FileSystemRights)"
                                    Write-Verbose -Message "Removing access rule $accessrule from $folder on $env:COMPUTERNAME"
                                    $null = $script:acl.RemoveAccessRule($a)
                                }
                            } -ArgumentList $folder, $VerbosePreference -ErrorAction Stop
                        } catch {
                            Stop-PSFFunction -Message "Issue setting file permissions on $folder" -ErrorRecord $_ -Continue
                        }
                    }

                    # Add local admin
                    $accountdisplay = @()
                    foreach ($username in $Account) {
                        $accountdisplay += $username
                        if ($PSCmdlet.ShouldProcess($computername, "Adding full control for $username on $folder")) {
                            try {
                                Invoke-PSFCommand -ComputerName $computername -ScriptBlock {
                                    param ($username, $VerbosePreference)
                                    $permission = $username, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                                    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                                    $script:acl.SetAccessRule($rule)
                                } -ArgumentList $username, $VerbosePreference -ErrorAction Stop
                            } catch {
                                Stop-PSFFunction -Message "Issue setting file permissions for $username on $folder" -ErrorRecord $_ -Continue
                            }
                        }
                    }

                    if ($PSCmdlet.ShouldProcess($computername, "Setting the full control permissions for $dbaccount on $folder")) {
                        $accountdisplay += $dbaccount
                        if ($dbaccount -ne $agentaccount) {
                            $accountdisplay += $agentaccount
                        }
                        try {
                            $null = Invoke-PSFCommand -ComputerName $computername -ScriptBlock {
                                param ($dbaccount, $agentaccount, $VerbosePreference)
                                $permission = "$dbaccount", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                                $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                                $script:acl.SetAccessRule($rule)

                                if ($dbaccount -ne $agentaccount) {
                                    $accountdisplay += $agentaccount
                                    $permission = "$agentaccount", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                                    $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                                    $script:acl.SetAccessRule($rule)
                                }
                            } -ArgumentList $dbaccount, $agentaccount, $VerbosePreference -ErrorAction Stop
                        } catch {
                            Stop-PSFFunction -Message "Issue setting file permissions on $folder for $dbaacount or $agentaccount" -ErrorRecord $_ -Continue
                        }
                    }

                    if ($PSCmdlet.ShouldProcess($computername, "Changing the owner for $folder")) {
                        try {
                            $null = Invoke-PSFCommand -ComputerName $computername -ScriptBlock {
                                param ($Owner)
                                $script:acl.SetOwner([System.Security.Principal.NTAccount]$Owner)
                            } -ArgumentList $Owner -ErrorAction Stop
                        } catch {
                            Stop-PSFFunction -Message "Changing owner on $folder on $computername" -ErrorRecord $_ -Continue
                        }
                    }

                    if ($PSCmdlet.ShouldProcess($computername, "Performing the actual set")) {
                        try {
                            $null = Invoke-PSFCommand -ComputerName $computername -ScriptBlock {
                                param ($folder)
                                $null = Set-Acl -Path $folder -AclObject $script:acl
                            } -ArgumentList $folder -ErrorAction Stop
                        } catch {
                            Stop-PSFFunction -Message "Changing owner on $folder on $computername" -ErrorRecord $_ -Continue
                        }

                        [PSCustomObject]@{
                            ComputerName        = $server.ComputerName
                            InstanceName        = $server.ServiceName
                            SqlInstance         = $server.DomainInstanceName
                            Path                = $folder
                            Owner               = $Owner
                            Account             = $accountdisplay -join ", "
                            PreviousPermissions = $access
                            Status              = "Success"
                        }
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failed to set permissions on $instance" -ErrorRecord $_ -Continue -Target $instance
            }
        }
    }
}
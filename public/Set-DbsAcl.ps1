function Set-DbsAcl {
    <#
    .SYNOPSIS
        Automatically installs or updates sp_WhoisActive by Adam Machanic.

    .DESCRIPTION
        This command downloads, extracts and installs sp_WhoisActive with Adam's permission. To read more about sp_WhoisActive, please visit http://whoisactive.com and http://sqlblog.com/blogs/adam_machanic/archive/tags/who+is+active/default.aspx

        Please consider donating to Adam if you find this stored procedure helpful: http://tinyurl.com/WhoIsActiveDonate

        Note that you will be prompted a bunch of times to confirm an action.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances. Server version must be SQL Server version 2005 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

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

        Website: https://dbatools.io
        Copyright: (c) 2018 by dbatools, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbatools.io/Install-DbaDisaStigAudit

    .EXAMPLE
        PS C:\> Install-DbaDisaStigAudit -SqlInstance sqlserver2014a -Database master

        Downloads sp_WhoisActive from the internet and installs to sqlserver2014a's master database. Connects to SQL Server using Windows Authentication.

    .EXAMPLE
        PS C:\> Install-DbaDisaStigAudit -SqlInstance sqlserver2014a -SqlCredential $cred

        Pops up a dialog box asking which database on sqlserver2014a you want to install the procedure into. Connects to SQL Server using SQL Authentication.

    .EXAMPLE
        PS C:\> Install-DbaDisaStigAudit -SqlInstance sqlserver2014a -Database master -LocalFile c:\SQLAdmin\whoisactive_install.sql

        Installs sp_WhoisActive to sqlserver2014a's master database from the local file whoisactive_install.sql

    .EXAMPLE
        PS C:\> $instances = Get-DbaRegServer sqlserver
        PS C:\> Install-DbaDisaStigAudit -SqlInstance $instances -Database master

        Installs sp_WhoisActive to all servers within CMS
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline, Position = 0)]
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
                            Set-Acl -Path $remote -AclObject $acl #Whatif
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

                        Write-PesterMessage "$dbaccount is service account for $server"
                        $accountdisplay += $dbaccount
                        $permission = "$dbaccount", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                        $acl.SetAccessRule($rule)

                        if ($dbaccount -ne $agentaccount -and $server -notmatch 'AD') {
                            $accountdisplay += $agentaccount
                            Write-PesterMessage "$agentaccount is agent account for $server"
                            $permission = "$agentaccount", "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow"
                            $rule = New-Object System.Security.AccessControl.FileSystemAccessRule $permission
                            $acl.SetAccessRule($rule)
                        }
                        Set-Acl -Path $remote -AclObject $acl #-WhatIf
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
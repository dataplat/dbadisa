function Get-DbsAcl {
    <#
    .SYNOPSIS
        Gets the permissions required by DISA for SQL Server directories

    .DESCRIPTION
        Gets the required permissions for SQL Server directories

        By default, it will detect and secure the default Data, Log and Backup directories

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

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
        PS C:\> Get-DbsAcl -SqlInstance sql2017, sql2016, sql2012 -Account "AD\SQL Admins" -Owner "AD\SQL Service"

        Sets permissions for the default data, log and backups on sql2017, sql2016, sql2012.

        Adds appropriate permissions for the "AD\SQL Admins" group as well as the SQL Server service accountsas Full Access.

        Also sets the owner of the folder to "AD\SQL Service"

    .EXAMPLE
        PS C:\> Get-DbaRegServer -SqlInstance sqlcentral | Get-DbsAcl -Account "AD\SQL Admins" -Owner "AD\SQL Service"

        Sets the appropriate permissions for all SQL Servers stored in the sqlcentral registered server.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [PsCredential]$Credential,
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
                $Path = $defaults.Data, $defaults.Log, $defaults.Backup
                $auditpaths = Get-DbaInstanceAudit -SqlInstance $server | Select-Object -ExpandProperty FullName
                foreach ($auditpath in $auditpaths) {
                    $Path += Split-Path -Path $auditpath
                }
                $Path += $server.RootDirectory
                $Path = $Path | Select-Object -Unique
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
                    try {
                        $acls = Invoke-PSFCommand -ComputerName $computername -ScriptBlock {
                            param ($folder)
                            # set it as a script variable to ensure it persists in the session, may be excessive
                            $acl = Get-Acl -Path $folder -ErrorAction Stop

                            $access = $acl.Access
                            $accessrules = @()
                            foreach ($a in $access) {
                                $accessrules += "$($a.IdentityReference) - $($a.AccessControlType) - $($a.FileSystemRights)"
                            }
                            [PSCustomObject]@{
                                Acl         = $acl
                                AccessRules = $accessrules
                            }
                        } -ArgumentList $folder -ErrorAction Stop
                    } catch {
                        Stop-PSFFunction -Message "Issue getting file permissions on $folder" -ErrorRecord $_ -Continue
                    }
                    foreach ($aclobject  in $acls) {
                        [PSCustomObject]@{
                            ComputerName  = $server.ComputerName
                            InstanceName  = $server.ServiceName
                            SqlInstance   = $server.DomainInstanceName
                            Path          = $folder
                            Owner         = $aclobject.Acl.Owner
                            Permissions   = $aclobject.AccessRules
                            EngineAccount = $dbaccount
                            AgentAccount  = $agentaccount
                            AclObject     = $aclobject.Acl
                        }
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failed to set permissions on $instance" -ErrorRecord $_ -Continue -Target $instance
            }
        }
    }
}
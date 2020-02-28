function Get-DbsAcl {
    <#
    .SYNOPSIS
        Gets the permissions required by DISA for SQL Server directories.

    .DESCRIPTION
        Gets the required permissions for SQL Server directories.

        By default, it will detect and secure the default Data, Log and Backup directories.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

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

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79215, V-79151 & V-79153, V-79155
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
        [parameter(Mandatory)]
        [string]$Owner,
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
                Stop-PSFFunction -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            if (-not $PSBoundParameters.Path) {
                $defaults = Get-DbaDefaultPath -SqlInstance $server
                $Path = $defaults.Data, $defaults.Log, $defaults.Backup | Where-Object { $_ -notmatch '\\\\' } | Select-Object -Unique
            }

            try {
                $computername = $instance.ComputerName
                $instancename = $instance.InstanceName
                $services = Get-DbaService -ComputerName $instance -Credential $Credential 3>$null
                $dbengine = $services | Where-Object DisplayName -match "SQL Server \($instancename\)"
                $dbaccount = $dbengine.StartName
                $agentengine = $services | Where-Object DisplayName -match "SQL Server Agent \($instancename\)"
                $agentaccount = $agentengine.StartName

                if ($dbaccount.length -lt 2) {
                    Stop-PSFFunction -Message "Couldn't get service information for $instance, moving on" -Continue
                }

                foreach ($folder in $Path) {
                    Write-Message -Level Verbose -Message "Modifying $folder on $computername"
                    try {
                        $acls = Invoke-PSFCommand -ComputerName $computername -Credential $credential -ScriptBlock {
                            param ($folder)
                            # set it as a script variable to ensure it persists in the session, may be excessive
                            Get-Acl -Path $folder -ErrorAction Stop
                        } -ArgumentList $folder -ErrorAction Stop
                    } catch {
                        Stop-PSFFunction -Message "Issue setting file permissions on $folder" -ErrorRecord $_ -Continue
                    }
                    foreach ($acl  in $acls) {
                        [PSCustomObject]@{
                            ComputerName  = $server.ComputerName
                            InstanceName  = $server.ServiceName
                            SqlInstance   = $server.DomainInstanceName
                            Path          = $folder
                            Owner         = $acls.GetOwner()
                            EngineAccount = $dbaccount
                            AgentAccount  = $agentaccount
                        }
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Failed to set permissions on $instance" -ErrorRecord $_ -Continue -Target $instance
            }
        }
    }
}
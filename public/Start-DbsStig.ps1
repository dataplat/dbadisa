function Start-DbsStig {
    <#
    .SYNOPSIS
        Stigs a server

    .DESCRIPTION
        Stigs a server

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target _SQL Server_ instance using alternative credentials

    .PARAMETER Credential
        Login to the target _Windows_ instance using alternative credentials

    .PARAMETER Path
        Specifies the directory where the file or files will be exported.

    .PARAMETER Exclude
        Exclude one or more exports. This is autopopulated so just tab whatever you'd like

    .PARAMETER AclOwner
        The account that will be set as the folder owner

    .PARAMETER AclAccount
        The account name or names that are to be granted permissions along with the service accounts

    .PARAMETER AuditMaintainer
        Set the owner for Set-DbsDbSchemaOwner, this can be dangeroo

    .PARAMETER ConnectionLimit
        The max number of connections that can connect to the SQL Server

    .PARAMETER DbAuditMaintainer
        The login or logins that are to be granted permissions. This should be a Windows Group or you may violate another STI

    .PARAMETER SchemaOwner
        Set the owner for Set-DbsDbSchemaOwner, this can be dangeroo

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Start-DbsStig -SqlInstance sqlserver\instance

        All databases, logins, job objects and sp_configure options will be exported from
        sqlserver\instance to an automatically generated folder name in Documents.

    .EXAMPLE
        PS C:\> $params = @{
            SqlInstance = "sql2017"
            AclOwner = "ad\dba"
            AclAccount = "ad\dba"
            Exclude = "DbSchemaOwner", "AuditMaintainer"
            ConnectionLimit = 3000
            DbAuditMaintainer = "ad\auditors"
            SchemaOwner = "ad\bob"
        }
        PS C:\> Start-DbsStig @params

        Stigs dat
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Low")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [PSCredential]$Credential,
        [string[]]$Exclude,
        [string]$AclOwner,
        [string[]]$AclAccount,
        [string[]]$AuditMaintainer,
        [string[]]$DbAuditMaintainer,
        [string]$SchemaOwner,
        [int]$ConnectionLimit,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
        $verbs = 'Set', 'Disable', 'Enable', 'Repair', 'Remove', 'Revoke'
        $commands = Get-Command -module dbadisa | Where-Object { $PSItem.Verb -in $verbs -and $PSItem.Name -match 'Dbs' -and $PSItem.Name -ne'Set-DbsDbFileSize' } | Select-Object -ExpandProperty Name

        # This requires some extra elbow grease
        if ($PSboundparameters.Confirm) {
            $PSDefaultParameterValues['*Dbs*:Confirm'] = $true
        } else {
            $PSDefaultParameterValues['*Dbs*:Confirm'] = $false
        }
        if ($PSboundparameters.WhatIf) {
            $PSDefaultParameterValues['*Dbs*:WhatIf'] = $true
        } else {
            $PSDefaultParameterValues['*Dbs*:WhatIf'] = $false
        }
    }
    process {
        if ($Exclude -notcontains 'Acl' -and -not $AclAccount -and -not $AclOwner) {
            Stop-PSFFunction -Message "You must specify an AclAccount and AclOwner if you don't -Exclude Acl"
            return
        }

        if ($Exclude -notcontains 'DbSchemaOwner' -and -not $SchemaOwner) {
            Stop-PSFFunction -Message "You must specify SchemaOwner if you didn't -Exclude DbSchemaOwner"
            return
        }

        if ($Exclude -notcontains 'AuditMaintainer' -and -not $AuditMaintainer) {
            Stop-PSFFunction -Message "You must specify AuditMaintainer if you didn't -Exclude AuditMaintainer"
            return
        }

        if ($Exclude -notcontains 'DbAuditMaintainer' -and -not $DbAuditMaintainer) {
            Stop-PSFFunction -Message "You must specify DbAuditMaintainer if you didn't -Exclude DbAuditMaintainer"
            return
        }

        if ($Exclude -notcontains 'ConnectionLimit' -and -not $ConnectionLimit) {
            Stop-PSFFunction -Message "You must specify ConnectionLimit if you didn't -Exclude ConnectionLimit"
            return
        }

        foreach ($instance in $SqlInstance) {
            $stepCounter = 0
            $PSDefaultParameterValues['*Dba*:SqlInstance'] = $instance
            $PSDefaultParameterValues['*Dbs*:SqlInstance'] = $instance
            $PSDefaultParameterValues['*Dbs*:ComputerName'] = $instance.ComputerName

            if (-not (Test-ElevationRequirement -ComputerName $instance.ComputerName)) {
                return
            }

            foreach ($command in $commands) {
                $partname = $command -Replace ".*-Dbs", ""
                if ($Exclude -notcontains $partname) {
                    try {
                        $tagsRex = ([regex]'(?m)^[\s]{0,15}Tags:(.*)$')
                        $as = (Get-Help $command -Full).AlertSet | Out-String -Width 600
                        $tags = $tagsrex.Match($as).Groups[1].Value | Where-Object { $PSItem -match 'V-' }
                        $tags = $tags.Replace(", NonCompliantResults", "").Trim().Split(",")

                        Write-PSFMessage -Level Verbose -Message "Stigging $instance"
                        Write-ProgressHelper -StepNumber ($stepCounter++) -TotalSteps $commands.Count -Message "Running $command" -Activity "Stigging $instance"

                        switch ($command) {
                            "Set-DbsAcl" {
                                # so finallly heres whats up, it needs to be arguments
                                $results = Set-DbsAcl -Owner $AclOwner -Account $AclAccount 3>$warn
                            }
                            "Set-DbsDbSchemaOwner" {
                                $results = Set-DbsDbSchemaOwner -Owner $SchemaOwner 3>$warn
                            }
                            "Set-DbsAuditMaintainer" {
                                $results = Set-DbsAuditMaintainer -Login $AuditMaintainer 3>$warn
                            }
                            "Set-DbsDbAuditMaintainer" {
                                $results = Set-DbsDbAuditMaintainer -User $DbAuditMaintainer 3>$warn
                            }
                            "Set-DbsConnectionLimit" {
                                $results = Set-DbsConnectionLimit -Value $ConnectionLimit 3>$warn
                            }
                            "Set-DbsEndpointEncryption" {
                                $results = Get-DbsEndpointEncryption | Set-DbsEndpointEncryption 3>$warn
                            }
                            default {
                                $results = Invoke-Expression -Command $command 3>$warn
                            }
                        }

                        if ($warn) {
                            Write-PSFMessage -Level Verbose -Message "$warn"
                        }

                        [pscustomobject]@{
                            SqlInstance = $instance
                            Command     = $command
                            Tags        = $tags
                            Result      = "Success"
                            Results     = $results
                        } | Select-DefaultView -Property SqlInstance, Command, Result, Tags
                    } catch {
                        [pscustomobject]@{
                            SqlInstance = $instance
                            Command     = $command
                            Tags        = $tags
                            Result      = "Failure: $_"
                            Results     = $results
                        } | Select-DefaultView -Property SqlInstance, Command, Result, Tags
                        Stop-PSFFunction -Message "Failure" -ErrorRecord $_ -Continue
                    }
                }
            }
            Write-Progress -Activity "Performing Instance Export for $instance" -Completed
        }
    }
}
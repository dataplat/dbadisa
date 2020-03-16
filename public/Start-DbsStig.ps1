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
        PS C:\> Start-DbsStig -SqlInstance sqlcluster -Exclude Databases, Logins -Path C:\dr\sqlcluster

        Exports everything but logins and database restore scripts to C:\dr\sqlcluster

    .EXAMPLE
        PS C:\> Start-DbsStig -SqlInstance sqlcluster -Path C:\servers\ -NoPrefix

        Exports everything to C:\servers but scripts do not include prefix information.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [PSCredential]$Credential,
        [string[]]$Exclude,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
        $verbs = 'Set', 'Disable', 'Enable', 'Repair', 'Remove', 'Revoke'
        $commands = Get-Command -module dbadisa | Where-Object { $PSItem.Verb -in $verbs -and $PSItem.Name -match 'Dbs' } | Select-Object -ExpandProperty Name
        $commands = Get-Command -Module dbadisa
    }
    process {
        foreach ($instance in $SqlInstance) {
            $stepCounter = 0
            $PSDefaultParameterValues['*Dba*:SqlInstance'] = $instance
            $PSDefaultParameterValues['*Dbs*:SqlInstance'] = $instance
            $PSDefaultParameterValues['*Dbs*:ComputerName'] = $instance.ComputerName

            foreach ($command in $commands) {
                $partname = $command -Replace ".*-Dbs", ""
                if ($Exclude -notcontains $partname) {
                    try {
                        $tagsRex = ([regex]'(?m)^[\s]{0,15}Tags:(.*)$')
                        $as = (Get-Help $command -Full).AlertSet | Out-String -Width 600
                        $tags = $tagsrex.Match($as).Groups[1].Value | Where-Object { $PSItem -match 'V-' }
                        $tags = $tags.Replace(", NonCompliantResults", "").Trim().Split(",")

                        $results = Invoke-Expression -Command $command 3>$warn

                        if ($warn) {
                            Write-PSFMessage -Level Verbose -Message "$warn"
                        }

                        [pscustomobject]@{
                            SqlInstance = $instance
                            Command     = $command
                            Tags = $tags
                            Result      = $results
                        }
                    } catch {
                        [pscustomobject]@{
                            SqlInstance = $instance
                            Command     = $command
                            Tags        = $tags
                            Result      = "Failure: $_"
                        }
                        Stop-PSFFunction -Message "Failure" -ErrorRecord $_ -Continue
                    }
                }
            }
            Write-Progress -Activity "Performing Instance Export for $instance" -Completed
        }
    }
}
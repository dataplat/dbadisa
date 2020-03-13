function Export-DbsInstance {
    <#
    .SYNOPSIS
        Exports all required documentation for an instance and its underlying server

    .DESCRIPTION
        Exports all required documentation for an instance and its underlying server

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target _SQL Server_ instance using alternative credentials

    .PARAMETER Credential
        Login to the target _Windows_ instance using alternative credentials

    .PARAMETER Path
        Specifies the directory where the file or files will be exported.

    .PARAMETER WithReplace
        If this switch is used, databases are restored from backup using WITH REPLACE. This is useful if you want to stage some complex file paths.

    .PARAMETER NoRecovery
        If this switch is used, databases will be left in the No Recovery state to enable further backups to be added.

    .PARAMETER Exclude
        Exclude one or more objects to export

        Databases
        Logins
        AgentServer

    .PARAMETER Append
        Append to the target file instead of overwriting.

    .PARAMETER Append
        Specifies if it is a baseline

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Export-DbsInstance -SqlInstance sqlserver\instance

        All databases, logins, job objects and sp_configure options will be exported from
        sqlserver\instance to an automatically generated folder name in Documents.

    .EXAMPLE
        PS C:\> Export-DbsInstance -SqlInstance sqlcluster -Exclude Databases, Logins -Path C:\dr\sqlcluster

        Exports everything but logins and database restore scripts to C:\dr\sqlcluster

    .EXAMPLE
        PS C:\> Export-DbsInstance -SqlInstance sqlcluster -Path C:\servers\ -NoPrefix

        Exports everything to C:\servers but scripts do not include prefix information.
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PSCredential]$SqlCredential,
        [PSCredential]$Credential,
        [Alias("FilePath")]
        [string]$Path = (Get-PSFConfigValue -FullName dbadisa.path.export),
        [string[]]$Exclude,
        [switch]$Append,
        [switch]$Baseline,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
        $null = Test-ExportDirectory -Path $Path
        <#
        Get-DbsAlert
        Get-DbsAuditDisabled
        Get-DbsAuditFilter
        Get-DbsAuditLogin
        Get-DbsAuditMaxValue
        Get-DbsAuditOnFailure
        Get-DbsAuditStartupState
        Get-DbsBrowser
        Get-DbsC2
        Get-DbsDbAlterPermission
        Get-DbsDbContainedUser
        Get-DbsDbKeyEncryptedByPassword
        Get-DbsDbKeyNotEncryptedByServer
        Get-DbsDbProhibitedKeyAlgorithm
        Get-DbsDbRecoveryModel
        Get-DbsDbTde
        Get-DbsEndpointEncryption
        Get-DbsExternalScripts
        Get-DbsFilestreamAccess
        Get-DbsFips
        Get-DbsHadoopConnectivity
        Get-DbsIFI
        Get-DbsLoginProperty
        Get-DbsOleAutomation
        Get-DbsPolybaseExport
        Get-DbsProtocol
        Get-DbsRemoteAccess
        Get-DbsRemoteDataArchive
        Get-DbsReplicationXp
        Get-DbsSaAccount
        Get-DbsSampleDatabase
        Get-DbsSqlClr
        Get-DbsSystemPermission
        Get-DbsTimeSource
        Get-DbsTraceFlag
        Get-DbsUserOptions
        Get-DbsXPCmdShell
        Test-DbsDiskSpace
        #>
        $commands = Get-Command -module dbadisa | Where-Object Verb -in 'Get', 'Test' | Select-Object -ExpandProperty Name
        $noncompliant = Find-DbsCommand -Tag NonCompliantResults | Select-Object -ExpandProperty CommandName

    }
    process {
        foreach ($instance in $SqlInstance) {
            $stepCounter = 0
            $PSDefaultParameterValues['*Dba*:SqlInstance'] = $instance
            $PSDefaultParameterValues['*Dbs*:SqlInstance'] = $instance
            $PSDefaultParameterValues['*Dbs*:ComputerName'] = $instance.ComputerName

            try {
                $server = Connect-DbaInstance -MinimumVersion 10
            } catch {
                Stop-PSFFunction -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            # Ola-style what's up
            $basepath = Join-PSFPath -Path $Path -Child $server.name.replace('\', '$')

            if ($Baseline) {
                $exportPath = "$basepath\baseline"
            } else {
                $timeNow = (Get-Date -uformat "%m%d%Y%H%M%S")
                $exportPath = "$basepath\$timenow"
            }

            if (-not (Test-Path $exportPath)) {
                try {
                    $null = New-Item -ItemType Directory -Path $exportPath -ErrorAction Stop
                } catch {
                    Stop-PSFFunction -Message "Failure" -ErrorRecord $_
                    return
                }
            }

            foreach ($command in $commands) {
                $partname = $filename = $command.Replace("Get-Dbs","").Replace("Test-Dbs","")
                if ($Exclude -notcontains $partname) {
                    if ($command -in $noncompliant) {
                        $filename = "$partname-noncompliant"
                    }
                    $filename = "$exportPath\$filename.xml"
                    Write-PSFMessage -Level Verbose -Message "Exporting $partname to $filename"
                    Write-ProgressHelper -StepNumber ($stepCounter++) -TotalSteps $commands.Count -Message "Exporting $partname to $filename"
                    Invoke-Expression -Command $command | Select-Object -Property * -ExcludeProperty Parent | Export-CliXml -Path $filename -Depth 2
                    Get-ChildItem -Path $filename -ErrorAction Ignore # -WarningAction SilentlyContinue
                }
            }

            Write-Progress -Activity "Performing Instance Export for $instance" -Completed
        }
    }
}
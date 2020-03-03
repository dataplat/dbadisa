function Move-DbsAuditFile {
    <#
    .SYNOPSIS
        Moves .sqlaudit files to a central repository using UNC shares

    .DESCRIPTION
        Moves .sqlaudit files to a central repository using UNC shares

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

        This is required to get specific information about the paths to modify. The base computer name is also used to
        perform the actual modifications.

    .PARAMETER SqlCredential
        Login to the target SQL Server instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

    .PARAMETER Destination
        Central repo

    .PARAMETER NoCompress
        Skip zip

    .PARAMETER Path
        Pat dat

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79311, V-79223, V-79225
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Move-DbsAuditFile -SqlInstance sql2017

        Move it
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [string[]]$Path,
        [string]$Destination,
        [switch]$NoCompress,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
        Function Move-AuditFile {
            [cmdletbinding()]
            param (
                [Parameter(Mandatory, ValueFromPipeline)]
                [System.IO.FileInfo]$File,
                [Parameter(Mandatory)]
                [string]$ServerName
            )

            process {
                foreach ($f in $file) {
                    Write-ProgressHelper -Activity "Moving sqlaudit files from $instance to $Destination" -Message "Moving $($results.FileName)" -TotalSteps $results.Count -StepNumber ($filecount++ | Write-Output)
                    $timestamp = (Get-date -Format yyyyMMddHHmm)
                    $shortname = $f.BaseName
                    $ext = $f.Extension.TrimStart(".")
                    $filename = "$servername-$shortname-$timestamp.$ext"
                    $f | Move-Item -Destination "$Destination\$filename" -ErrorAction SilentlyContinue
                    if ($NoCompress) {
                        Get-ChildItem -Path "$Destination\$filename" -ErrorAction SilentlyContinue
                    }
                }
            }
        }

        $PSDefaultParameterValues["*:ErrorAction"] = "Stop"
    }
    process {
        if (-not (Test-Path -Path $Destination)) {
            Stop-PSFFunction -Message "$Destination not accessible. Please check the path and permissions."
            return
        }

        foreach ($instance in $SqlInstance) {
            Write-ProgressHelper -Activity "Processing instances" -Message "Processing $instance" -TotalSteps $SqlInstance.Count -StepNumber (++$instancecount | Write-Output)
            $results = @()
            $files = @()
            $filecount = 0

            try {
                $server = Connect-DbaInstance -SqlInstance $instance
            } catch {
                Stop-PSFFunction -Message "Error occurred while establishing connection to $instance" -Category ConnectionError -ErrorRecord $_ -Target $instance -Continue
            }

            try {
                if (-not $PSBoundParameters.Path) {
                    $Path = (Get-DbaDefaultPath -SqlInstance $server).Data
                    $files += Get-DbaFile -SqlInstance $server -Path "$Path\STIG" | Where-Object FileName -match '.sqlaudit'
                }

                $files += Get-DbaFile -SqlInstance $server -Path $Path | Where-Object FileName -match '.sqlaudit'
                $servername = $server.Name -Replace '\\', '$'

                foreach ($file in $files) {
                    $filename = Split-Path -Path $file.FileName -Leaf
                    if ($filename -match '_') {
                        $results += $file
                    }
                }

                if ($results) {
                    if ($server -eq $env:COMPUTERNAME) {
                        Get-ChildItem -Path $results.Filename | Sort-Object LastWriteTime -Descending |
                            Select-Object -Skip 1 | Move-AuditFile -ServerName $servername
                    } else {
                        Get-ChildItem -Path $results.RemoteFilename | Sort-Object LastWriteTime -Descending |
                            Select-Object -Skip 1 | Move-AuditFile -ServerName $servername
                    }

                    Write-Progress -Activity "Moving sqlaudit files from $instance" -Completed
                }
            } catch {
                Stop-PSFFunction -Message "Failure when processing $instance" -ErrorRecord $_ -Continue -Target $instance
            }
        }
        Write-Progress -Activity "Processing instances" -Completed
    }
    end {
        if (-not $NoCompress) {
            # Zip any sqlaudit not zipped
            $auditfiles = Get-ChildItem "$Destination\*.sqlaudit"
            foreach ($audit in $auditfiles) {
                try {
                    $basename = $audit.BaseName
                    if ($PSCmdlet.ShouldProcess("Compressing $basename")) {
                        Compress-Archive $audit.FullName -DestinationPath "$Destination\$basename.zip" -CompressionLevel Optimal -Update
                        Get-ChildItem -Path "$Destination\$basename.zip"
                    }
                    Remove-Item -Path $audit
                } catch {
                    Stop-PSFFunction -Message "Failure" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}
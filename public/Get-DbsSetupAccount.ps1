function Get-DbsSetupAccount {
    <#
    .SYNOPSIS
        Returns a list of accounts that have installed or modified SQL Server.

    .DESCRIPTION
        Returns a list of accounts that have installed or modified SQL Server.

    .PARAMETER ComputerName
        The SQL Server (or server in general) that you're connecting to.

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically Gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79167
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .LINK
        https://dbadisa.readthedocs.io/en/latest/functions/Get-DbsSetupAccount

    .EXAMPLE
        PS C:\> Get-DbsSetupAccount -ComputerName sql2016, sql2017, sql2012

        Returns a list of accounts that have isntalled or modified SQL Server on sql2016, sql2017 and sql2012
#>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$ComputerName,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            $regroots = Get-DbaRegistryRoot -Computer $computer | Select-Object -ExpandProperty RegistryRoot
            foreach ($regroot in $regroots) {
                Invoke-PSFCommand -ErrorAction SilentlyContinue -ComputerName $computer -ArgumentList $regroot, $script:allnumbers -ScriptBlock {
                    $results = Get-ChildItem -Path 'HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\*' -ErrorAction SilentlyContinue | Where-Object PSChildName -in $args[1]
                    $dirs = $results | Get-ItemProperty -ErrorAction SilentlyContinue | Select-Object -ExpandProperty VerSpecificRootDir
                    foreach ($dir in $dirs) {
                        $realdir = "$dir\setup bootstrap\Log"
                        $files = Get-ChildItem $realdir -Recurse -File -ErrorAction SilentlyContinue | Where-Object { $psitem -ne $null }

                        $stringmatch = Select-String -ErrorAction SilentlyContinue -Pattern "LogonUser = " -Path $files.FullName
                        foreach ($string in $stringmatch) {
                            if ($string -match '(?<Path>.+):(?<Number>\d+):Property\(S\): LogonUser = (?<Username>\w+)') {
                                $null = $matches.Remove(0)
                                $null = $matches.Remove("Number")
                                $null = $matches.Add("ComputerName", $env:ComputerName)
                                $null = $matches.Add("FullString", $string)
                                # Add extra properties with $matches.Add($Name, $Value) here
                                [pscustomobject]$matches
                            }
                        }
                    }
                } | Select-Object ComputerName, Username, Path, FullString | Select-DefaultView -Property ComputerName, Username, Path
            }
        }
    }
}
function Test-DbsInstallPath {
    <#
    .SYNOPSIS
        Tests the installation path to ensure it is not part of the Windows directory or in an application folder

    .DESCRIPTION
        Tests the installation path to ensure it is not part of the Windows directory or in an application folder

    .PARAMETER ComputerName
        The target SQL Server

    .PARAMETER Credential
        Credential object used to connect to the computer as a different user


    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79169
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Test-DbsInstallPath -ComputerName sql01

        Tests the installation path for all instances on sql01 to ensure they are not part of the Windows directory or in an application folder

    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [Alias("cn", "host", "Server")]
        [DbaInstanceParameter[]]$ComputerName = $env:COMPUTERNAME,
        [PSCredential]$Credential,
        [switch]$EnableException
    )
    process {
        foreach ($computer in $ComputerName.ComputerName) {
            $regroots = Get-DbaRegistryRoot -Computer $computer -Credential $Credential | Select-Object -ExpandProperty RegistryRoot
            foreach ($regroot in $regroots) {
                Invoke-PSFCommand -ComputerName $computer -Credential $Credential -ArgumentList "$regroot\Setup" -ScriptBlock {
                    $rootdir = $currentdir = Get-ItemProperty -Path $args | Select-Object -ExpandProperty SqlPath
                    $osroot = ([system.io.directoryinfo]$rootdir).Root
                    $appdirmatch = $false
                    do {
                        $currentdir = Split-Path -Path $currentdir
                        if ($currentdir -ne $osroot) {
                            $appmatch = Get-ChildItem -Path "$currentdir\*exe"
                            if ($appmatch) {
                                $appdirmatch = $true
                            }
                        }
                    } until ( ($currentdir -eq $osroot) -or $appmatch)

                    [pscustomobject]@{
                        ComputerName = $env:COMPUTERNAME
                        RootDir      = $rootdir
                        WinDir       = $env:windir
                        WindirMatch  = $env:windir -match [regex]::escape($rootdir)
                        AppdirMatch  = $appdirmatch
                        AppdirExe    = $appmatch
                    }
                } | Select-Object -Property * -ExcludeProperty PSComputerName, RunspaceId
            }
        }
    }
}
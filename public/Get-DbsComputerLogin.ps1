function Get-DbsComputerLogin {
    <#
    .SYNOPSIS
        Returns a list of all server logins that are computers.

    .DESCRIPTION
        Returns a list of all server logins that are computers.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79131
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsComputerLogin -SqlInstance sql2017, sql2016, sql2012

        Returns a list of all server logins that are computers for sql2017, sql2016, and sql2012

    .EXAMPLE
        PS C:\> Get-DbsComputerLogin -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\computeruser.csv -NoTypeInformation

        Exports a list of all server logins that are computers to D:\disa\computeruser.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        $logins = Get-DbaLogin @PSBoundParameters | Where-Object Name -like '*$' | Sort-Object -Unique SqlInstance, Database, Login

        foreach ($login in $logins) {
            # parse ad\user
            if ($login.Name -match "\\") {
                $loginname = $login.Name.Split("\")[1]
            } elseif ($login.Name -match "\@") {
                # or parse user@ad.local
                $loginname = $login.Name.Split("@")[0]
            } else {
                $loginname = $login.Name
            }

            $loginname = $loginname.TrimEnd('$')
            $found = ([ADSISearcher]"(&(ObjectCategory=Computer)(Name=$($loginname)))").FindAll()

            if ($found.Path) {
                Select-DefaultView -InputObject $login -Property SqlInstance, Database, Name
            }
        }
    }
}
function Get-DbsDbComputerUser {
    <#
    .SYNOPSIS
        Returns a list of all database user accounts that are computers.

    .DESCRIPTION
        Returns a list of all database user accounts that are computers.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbaDatabase

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79067
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbComputerUser -SqlInstance sql2017, sql2016, sql2012

        Returns a list of all database user accounts that are computers for sql2017, sql2016, and sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbComputerUser -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\computeruser.csv -NoTypeInformation

        Exports a list of all database user accounts that are computers to D:\disa\computeruser.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance
        }

        foreach ($db in $InputObject) {
            $users = $db | Get-DbaDbUser | Where-Object Name -like '*$' | Sort-Object -Unique SqlInstance, Database, Login
            foreach ($user in $users) {
                try {
                    # parse ad\user
                    if ($user.Login -match "\\") {
                        $username = $user.Login.Split("\")[1]
                    } elseif ($user.Login -match "\@") {
                        # or parse user@ad.local
                        $username = $user.Login.Split("@")[0]
                    } else {
                        $username = $user.Login
                    }

                    $username = $username.TrimEnd('$')
                    $found = ([ADSISearcher]"(&(ObjectCategory=Computer)(Name=$($username)))").FindAll()

                    if ($found.Path) {
                        Select-DefaultView -InputObject $user -Property SqlInstance, Database, Name
                    }
                } catch {
                    Stop-PSFFunction -Message "Failure on database $($user.Parent.Name) on $($db.Parent.Name)" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}
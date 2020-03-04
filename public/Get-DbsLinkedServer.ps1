function Get-DbsLinkedServer {
    <#
    .SYNOPSIS
        Gets a list of linked servers and their logins

    .DESCRIPTION
        Gets a list of linked servers and their logins

    .PARAMETER SqlInstance
        The target SQL Server instance or instances

    .PARAMETER SqlCredential
        Login to the target SQL Server instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically gets advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79183
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsLinkedServer -SqlInstance sql2017, sql2016, sql2012

        Gets a list of linked servers and their logins for sql2017, sql2016 and sql2012

    .EXAMPLE
        PS C:\> Get-DbsLinkedServer -SqlInstance sql2017, sql2016, sql2012 | Export-Csv -Path D:\DISA\linkedservers.csv -NoTypeInformation

        Gets a list of linked servers and their logins for sql2017, sql2016 and sql2012 and exports them to D:\DISA\linkedservers.csv
    #>
    [CmdletBinding()]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [switch]$EnableException
    )
    process {
        $linkedservers = Get-DbaLinkedServer @PSBoundParameters
        foreach ($linkedserver in $linkedservers) {
            $logins = @()
            $lslogins = $linkedserver.LinkedServerLogins | Where-Object { $PSItem.Login -or $PSItem.RemoteUser }
            foreach ($login in $lslogins) {
                $logins += ([PSCustomObject]@{
                        Login       = $login.Name
                        RemoteUser  = $login.RemoteUser
                        Impersonate = $login.Impersonate
                    } | Add-Member -MemberType ScriptMethod -Name ToString -Value { $this.RemoteUser } -PassThru -Force)
            }
            [PSCustomObject]@{
                SqlInstance = $linkedserver.Parent.Name
                Name        = $linkedserver.Name
                Logins      = $logins
            }
        }
    }
}
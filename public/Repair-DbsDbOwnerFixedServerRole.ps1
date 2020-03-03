function Repair-DbsDbOwnerFixedServerRole {
    <#
    .SYNOPSIS
        Removes unauthorized users from roles and/or sets the owner of the database to an authorized login

    .DESCRIPTION
        Removes unauthorized users from roles and/or sets the owner of the database to an authorized login

    .PARAMETER Type
        The type of repair - remove user from role, set a new db owner, or both

        Options: "RemoveRoleMember", "SetOwner"

    .PARAMETER NewOwner
        The type of repair - remove user from role, set a new db owner, or both

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbsDbOwnerFixedServerRole

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79111
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbOwnerFixedServerRole -SqlInstance sql2017, sql2016, sql2012 | Remove-DbsDbOwnerFixedServerRole

        Removes unauthorized users from their associated roles

    .EXAMPLE
        PS C:\> Get-DbsDbOwnerFixedServerRole -SqlInstance sql2017, sql2016, sql2012 | Remove-DbsDbOwnerFixedServerRole -Confirm:$false

        Removes unauthorized users from their associated roles and does not prompt

    .EXAMPLE
        PS C:\> Get-DbsDbOwnerFixedServerRole -SqlInstance sql2017, sql2016, sql2012 | Out-GridView -Passthru | Remove-DbsDbOwnerFixedServerRole -Type SetOwner -NewOwner AD\chantel.phillip -Confirm:$false

        Sets the owner of the database to an authorized login, AD\chantel.phillip
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [parameter(ValueFromPipeline)]
        [pscustomobject[]]$InputObject,
        [ValidateSet("RemoveRoleMember", "SetOwner")]
        [string[]]$Type = "RemoveRoleMember",
        [string]$NewOwner,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        if ($Type -contains "SetOwner" -and -not $NewOwner) {
            Stop-PSFFunction -Message "You must specify -NewOwner when using the SetOwner type"
            return
        }
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeSystem |
                Where-Object ContainmentType -eq $null
        }
        foreach ($fixedrole in $InputObject) {
            $db = $fixedrole.db
            $role = $fixedrole.FixedRole
            $login = $fixedrole.Owner
            if ($Type -contains "RemoveRoleMember") {
                if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Removing $login from $role")) {
                    try {
                        $sql = "ALTER SERVER ROLE [$role] DROP MEMBER [$login]"
                        Write-PSFMessage -Level Verbose -Message $sql
                        $db.Query($sql)
                        [pscustomobject]@{
                            SqlInstance = $fixedrole.SqlInstance
                            Database    = $fixedrole.Database
                            Account     = $fixedrole.Owner
                            Repaired    = $true
                        }
                    } catch {
                        Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
                    }
                }
            }
            if ($Type -contains "SetOwner") {
                if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Altering owner for $($fixedrole.Database), changing to $NewOwner")) {
                    try {
                        $sql = "ALTER AUTHORIZATION ON database::[$($fixedrole.Database)] TO [$NewOwner]"
                        Write-PSFMessage -Level Verbose -Message $sql
                        $db.Query($sql)
                        [pscustomobject]@{
                            SqlInstance = $fixedrole.SqlInstance
                            Database    = $fixedrole.Database
                            Account     = $fixedrole.Owner
                            Repaired    = $true
                        }
                    } catch {
                        Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
                    }
                }
            }
        }
    }
}
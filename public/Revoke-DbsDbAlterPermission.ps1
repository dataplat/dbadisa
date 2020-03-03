function Revoke-DbsDbAlterPermission {
    <#
    .SYNOPSIS
        Removes non-compliant alter permissions

    .DESCRIPTION
        Removes non-compliant alter permissions

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbsDbAlterPermission

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79109, V-79075, V-79081
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbAlterPermission -SqlInstance sql2017, sql2016, sql2012 | Revoke-DbsDbAlterPermission

        Revokes non-compliant alter permissions on sql2017, sql2016, sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbAlterPermission -SqlInstance sql2017, sql2016, sql2012 | Out-GridView -Passthru | Revoke-DbsDbAlterPermission -Confirm:$false

        Revokes _selected_ non-compliant alter permissions on sql2017, sql2016, sql2012, does not prompt
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [parameter(ValueFromPipeline)]
        [pscustomobject[]]$InputObject,
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeSystem |
            Where-Object ContainmentType -eq $null
        }

        foreach ($permission in $InputObject) {
            if ($PSCmdlet.ShouldProcess($instance, "Installing $sqlfile on $instance to $Path")) {
                $db = $permission.db
                $object = $permission.ObjectName
                $principal = $permission.PrincipalName
                try {
                    $sql = "REVOKE ALTER ON [$object] TO [$principal]"
                    $db.Query($sql)
                    [pscustomobject]@{
                        SqlInstance = $permission.SqlInstance
                        Database    = $permission.Database
                        Object      = $object
                        Principal   = $principal
                        Revoked     = $true
                    }
                } catch {
                    Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name)" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}
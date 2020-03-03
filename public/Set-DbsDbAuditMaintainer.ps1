function Set-DbsDbAuditMaintainer {
    <#
    .SYNOPSIS
        Creates the database audit maintainer role, sets the permissions for the role, and adds logins.

        NOTE! This command revokes permz.

    .DESCRIPTION
        Creates the database audit maintainer role, sets the permissions for the role, and adds logins.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances Server version must be SQL Server version 2012 or higher.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials

    .PARAMETER Database
        Allows databases to be piped in from Get-DbaDatabase.

    .PARAMETER Role
        Name to be given the audit maintainer role.

    .PARAMETER User
        The login or logins that are to be granted permissions. This should be a Windows Group or you may violate another STIG.

    .PARAMETER InputObject
        Allows piping from Get-DbsDbAuditMaintainer

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79073
        Author: Tracy Boggiano (@TracyBoggiano), databasesuperhero.com

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsDbAuditMaintainer -SqlInstance sql2017, sql2016, sql2012 -User "AD\SQL Admins"

        Set permissions for the DATABASE_AUDIT_MAINTAINERS role on sql2017, sql2016, sql2012 for user AD\SQL Admins on Prod database.

    .EXAMPLE
        PS C:\> Set-DbsDbAuditMaintainer -SqlInstance sql2017, sql2016, sql2012 -Role auditmaintainers -User "AD\SQL Admins"

        Set permissions for the auditmaintainers role on sql2017, sql2016, sql2012 for user AD\SQL Admins on Prod database.
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(Mandatory, ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [string]$Role = "DATABASE_AUDIT_MAINTAINERS",
        [parameter(Mandatory)]
        [string[]]$User,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )

    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -ExcludeDatabase tempdb | Where-Object IsAccessible
        }

        foreach ($db in $InputObject) {
            # chek to see if dbowner too
            # New-DbaDbUser -SqlInstance sql2012 -Database blah -Login base\ctrlb
            # check to ensure that they are using domain\user or user@domain
            try {
                $sql = "IF DATABASE_PRINCIPAL_ID('$($Role)') IS NULL CREATE ROLE [$($Role)]"
                Write-PSFMessage -Level Verbose -Message $sql
                if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Create role $Role")) {
                    $db.Query($sql)
                }

                $sql = "GRANT ALTER ANY DATABASE AUDIT TO [$($Role)]"
                Write-PSFMessage -Level Verbose -Message $sql
                if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Granting ALTER ANY DATABASE AUDIT to $Role")) {
                    $db.Query($sql)
                }

                foreach ($databaseuser in $db.Users) {
                    $sql = "REVOKE ALTER ANY DATABASE AUDIT FROM [$($databaseuser.Name)]"
                    Write-PSFMessage -Level Verbose -Message $sql
                    if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Revoking ALTER ANY DATABASE AUDIT from role $Role")) {
                        $db.Query($sql)
                    }

                    $sql = "REVOKE CONTROL FROM [$($databaseuser.Name)]"
                    Write-PSFMessage -Level Verbose -Message $sql
                    if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Revoking CONTROL from role $Role")) {
                        $db.Query($sql)
                    }
                }

                foreach ($dbuser in $user) {
                    $loginexists = $db.Parent.Logins | Where-Object Name -eq $dbuser
                    if (-not $loginexists) {
                        if ($dbuser -notmatch '\\' -and $dbuser -notmatch '@') {
                            Stop-PSFFunction -Message "The only way we can create a new user is if it's Windows. Please either use a Windows account or add the user manually." -Continue
                        }

                        if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Creating login for $dbuser")) {
                            $null = New-DbaLogin -SqlInstance $db.Parent -Login $dbuser
                        }
                    }

                    $userexists = $db.Users | Where-Object Name -eq $dbuser

                    if (-not $userexists) {
                        $sql = "CREATE USER [$dbuser] FOR LOGIN [$dbuser]"
                        Write-PSFMessage -Level Verbose -Message $sql
                        if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Create user for login $dbuser")) {
                            $db.Query($sql)
                        }
                    }

                    $casedname = Get-DbaDbUser  -SqlInstance $SqlInstance -Database $db.Name | Where-Object Name -eq $dbuser | Select-Object -ExpandProperty Name
                    $sql = "ALTER ROLE [$($Role)] ADD MEMBER [$($casedname)]"
                    Write-PSFMessage -Level Verbose -Message $sql

                    if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Adding member $casedname to role $Role")) {
                        $db.Refresh()
                        $db.Query($sql)

                        [pscustomobject]@{
                            SqlInstance = $db.SqlInstance
                            Database    = $db.Name
                            User        = $dbuser
                            Status      = "Successfully added to $Role"
                        }
                    }
                }
            } catch {
                Stop-PSFFunction -Message "Could not modify $db on $($db.Parent.Name)" -ErrorRecord $_ -Continue
            }
        }
    }
}
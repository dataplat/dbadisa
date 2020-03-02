function Set-DbsDbFileSize {
    <#
    .SYNOPSIS
        Sets databases to a non-default growth and growth type. 64MB by default.

    .DESCRIPTION
        Sets databases to a non-default growth and growth type. 64MB by default.

    .PARAMETER SqlInstance
        The target SQL Server instance or instances.

    .PARAMETER SqlCredential
        Login to the target instance using alternative credentials. Accepts PowerShell credentials (Get-Credential).

        Windows Authentication, SQL Server Authentication, Active Directory - Password, and Active Directory - Integrated are all supported.

        For MFA support, please use Connect-DbaInstance.

    .PARAMETER GrowthType
        The growth type. Valid values are MB, KB, GB or TB. MB by default.

    .PARAMETER Growth
        The growth value. 64 by default.

    .PARAMETER WhatIf
        If this switch is enabled, no actions are performed but informational messages will be displayed that explain what would happen if the command were to run.

    .PARAMETER Confirm
        If this switch is enabled, you will be prompted for confirmation before executing any operations that change state.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags:
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Set-DbsDbFileSize -SqlInstance sql2017, sql2016, sql2012

        Sets all non-default sized database files on sql2017, sql2016, sql2012 to 64MB.

    .EXAMPLE
        PS C:\> Get-DbaDatabase -SqlInstance sql2016 -Database test | Set-DbsDbFileSize -GrowthType GB -Growth 1

        Sets the test database on sql2016 to a growth of 1GB

        .EXAMPLE
        PS C:\> Set-DbsDbFileSize -SqlInstance sql2017, sql2016, sql2012 -WhatIf

        Shows what would happen if the command were executed
    #>

    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "Medium")]
    param (
        [parameter(ValueFromPipeline)]
        [DbaInstanceParameter[]]$SqlInstance,
        [PsCredential]$SqlCredential,
        [ValidateSet("KB", "MB", "GB", "TB")]
        [string]$GrowthType = "MB",
        [int]$Growth = 64,
        [parameter(ValueFromPipeline)]
        [Microsoft.SqlServer.Management.Smo.Database[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if ($SqlInstance) {
            $InputObject = Get-DbaDatabase -SqlInstance $SqlInstance -SqlCredential $SqlCredential -ExcludeDatabase tempdb -EnableException:$EnableException | Where-Object IsAccessible
        }

        foreach ($db in $InputObject) {
            $allfiles = @($db.FileGroups.Files, $db.LogFiles)
            foreach ($file in $allfiles) {
                if (($file.GrowthType -eq "Percent" -or ($file.GrowthType -eq "KB" -and $file.Growth -eq 1024)) -or (Was-Bound -Parameter Growth) -or (Was-Bound -Parameter GrowthType)) {
                    if ($PSCmdlet.ShouldProcess($db.Parent, "Setting filegrowth for $($file.Name) in $($db.name) to $($Growth)$($GrowthType)")) {
                        # SMO gave me some weird errors so I'm just gonna go with T-SQL
                        try {
                            $sql = "ALTER DATABASE $db MODIFY FILE ( NAME = N'$($file.Name)', FILEGROWTH = $($Growth)$($GrowthType) )"
                            Write-PSFMessage -Level Verbose -Message $sql
                            $db.Query($sql)
                        } catch {
                            Stop-PSFFunction -EnableException:$EnableException -Message "Could not modify $db on $($db.Parent.Name)" -ErrorRecord $_ -Continue
                        }
                        [pscustomobject]@{
                            SqlInstance = $db.SqlInstance
                            Database    = $db.Name
                            GrowthType  = $GrowthType
                            Growth      = $Growth
                            File        = $file.Name
                            FileName    = $file.FileName
                            Status      = $db.Status
                        }
                    }
                }
            }
        }
    }
}
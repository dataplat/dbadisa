function Set-DbsDbSchemaOwner {
    <#
    .SYNOPSIS
        Sets a schema owner

    .DESCRIPTION
        Sets a schema owner

        Basically performs ALTER AUTHORIZATION ON SCHEMA::[<Schema Name>] TO [<Principal Name>]

    .PARAMETER Owner
        Sets the new owner

    .PARAMETER InputObject
        Allows databases to be piped in from Get-DbsDbSchemaOwner

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Tags: V-79077
        Author: Chrissy LeMaire (@cl), netnerds.net

        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        PS C:\> Get-DbsDbSchemaOwner -SqlInstance sql2017, sql2016, sql2012 | Set-DbsDbSchemaOwner

        Sets a schema owner for schemas per db on sql2017, sql2016, sql2012

    .EXAMPLE
        PS C:\> Get-DbsDbSchemaOwner -SqlInstance sql2017, sql2016, sql2012 | Out-GridView -Passthru | Set-DbsDbSchemaOwner -Owner ad\dbschemaowner -Confirm:$false

        Sets a schema owner for _selected_ schemas on sql2017, sql2016, sql2012, does not prompt
    #>
    [CmdletBinding(SupportsShouldProcess, ConfirmImpact = "High")]
    param (
        [parameter(ValueFromPipeline)]
        [pscustomobject[]]$InputObject,
        [string]$Owner,
        [switch]$EnableException
    )
    process {
        foreach ($result in $InputObject) {
            $db = $result.db
            $object = $result.SchemaName
            if ($PSCmdlet.ShouldProcess($db.Parent.Name, "Altering authorization on $object to $Owner on $($db.Name)")) {

                try {
                    $sql = "ALTER AUTHORIZATION ON SCHEMA::[$object] TO [$Owner]"
                    Write-PSFMessage -Level Verbose -Message $sql
                    $db.Query($sql)
                    [pscustomobject]@{
                        SqlInstance = $result.SqlInstance
                        Database    = $result.Database
                        Schema      = $object
                        Owner       = $Owner
                        Success     = $true
                    }
                } catch {
                    $message = $_.Exception.InnerException.InnerException.InnerException.InnerException.Message
                    if (-not $message) {
                        $message = $_
                    }
                    Stop-PSFFunction -Message "Failure on $($db.Parent.Name) for database $($db.Name) | $message" -ErrorRecord $_ -Continue
                }
            }
        }
    }
}
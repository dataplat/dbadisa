<#
    .SYNOPSIS
        Lists all checks, tags and unique identifiers

    .DESCRIPTION
        Lists all checks, tags and unique identifiers

    .PARAMETER Pattern
        May be any string, supports wildcards.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .EXAMPLE
        Get-DbsCheck

        Retrieves all of the available checks

    .EXAMPLE
        Get-DbsCheck backups

        Retrieves all of the available tags that match backups

    .LINK
    https://dbadisa.readthedocs.io/en/latest/functions/Get-DbsCheck/
#>
function Get-DbsCheck {
    [CmdletBinding()]
    param (
        [string]$Pattern,
        [switch]$EnableException
    )

    process {
        $script:localapp = Get-DbsConfigValue -Name app.localapp
        if ($Pattern) {
            if ($Pattern -notmatch '\*') {
                @(Get-Content "$script:localapp\checks.json" | Out-String | ConvertFrom-Json).ForEach{
                    $output = $psitem | Where-Object {
                        $_.Group -match $Pattern -or $_.Description -match $Pattern -or
                        $_.UniqueTag -match $Pattern -or $_.AllTags -match $Pattern -or $_.Type -match $Pattern
                    }
                    @($output).ForEach{
                        Select-DefaultView -InputObject $psitem -TypeName Check -Property 'Group', 'Type', 'UniqueTag', 'AllTags', 'Config', 'Description'
                    }
                }
            } else {
                @(Get-Content "$script:localapp\checks.json" | Out-String | ConvertFrom-Json).ForEach{
                    $output = $psitem | Where-Object {
                        $_.Group -like $Pattern -or $_.Description -like $Pattern -or
                        $_.UniqueTag -like $Pattern -or $_.AllTags -like $Pattern -or $_.Type -like $Pattern
                    }
                    @($output).ForEach{
                        Select-DefaultView -InputObject $psitem -TypeName Check -Property 'Group', 'Type', 'UniqueTag', 'AllTags' , 'Config', 'Description'
                    }
                }
            }
        } else {
            $output = Get-Content "$script:localapp\checks.json" | Out-String | ConvertFrom-Json
            @($output).ForEach{
                Select-DefaultView -InputObject $psitem -TypeName Check -Property 'Group', 'Type', 'UniqueTag', 'AllTags', 'Config', 'Description'
            }
        }
    }
}
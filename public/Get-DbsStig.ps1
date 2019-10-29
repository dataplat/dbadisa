function Get-DbsStig {
    <#
.SYNOPSIS
    Retrieves raw configuration values by name.

.DESCRIPTION
    Retrieves raw configuration values by name.

    Can be used to search the existing configuration list.

.PARAMETER Name
    Default: "*"

    The name of the configuration element(s) to retrieve.
    May be any string, supports wildcards.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-DbsConfigValue app.sqlinstance

    Retrieves the raw value for the key "app.sqlinstance"

.LINK
https://dbadisa.readthedocs.io/en/latest/functions/Get-DbsConfig/
#>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [object[]]$Path,
        [int[]]$Version,
        [switch]$EnableException
    )
    begin {
        if (-not $Path) {
            $Path = Get-ChildItem -Recurse "$script:ModuleRoot\bin\xml\*.xml"
        }
    }
    process {
        foreach ($file in $Path) {
            $xml = [xml](Get-Content -Path $file.FullName -Raw)
            foreach ($group in $xml.Benchmark.Group) {
                $rule = $group.Rule
                if ($rule.Version.StartsWith("SQL4")) {
                    $sqlversion = "2014"
                } elseif ($rule.Version.StartsWith("SQL2")) {
                    $sqlversion = "2012"
                } elseif ($rule.Version.StartsWith("SQL6")) {
                    $sqlversion = "2016"
                } else {
                    $sqlversion = "2008"
                }

                if ($Version -and $sqlversion -ne $Version) { }
                if ($file.FullName -match 'nstance') {
                    $type = "Instance"
                } else {
                    $type = "Database"
                }

                [pscustomobject]@{
                    Type        = $type
                    SqlVersion  = $sqlversion
                    VulnID      = $group.id
                    RuleID      = $rule.id
                    Severity    = $rule.severity
                    Weight      = $rule.weight
                    Version     = $rule.version
                    Title       = $rule.title
                    Description = ($rule.description -replace '<[^>]+>', '').TrimEnd("false")
                    FixText     = $rule.fixtext.'#text'
                    Check       = $rule.check.'check-content'
                }
            }
        }
    }
}
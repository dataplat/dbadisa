function Get-DbsStig {
    <#
    .SYNOPSIS
        Parses the U_MS_SQL_Server_2014_Database_STIG_V1R6_Manual-xccdf style XML files from DISA into PowerShell objects

    .DESCRIPTION
        Parses the U_MS_SQL_Server_2014_Database_STIG_V1R6_Manual-xccdf style XML files from DISA into PowerShell objects

    .PARAMETER Path
        The Path to the STIG xml file. Not required, as they've been included.

    .PARAMETER Version
        By default, SQL Server 2014 and above stigs are returned. This allows you to filter by version.

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        Get-DbsStig

        Return checklsits for database and instance for SQL Server 2014 and 2016

    .EXAMPLE
        Get-DbsStig -Version 2014

        Return checklsits for database and instance for SQL Server 2014 only

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
        function get-stig {
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
    process {
        if ($Version) {
            get-stig | Where-Object SqlVersion -in $Version
        } else {
            get-stig
        }
    }
}
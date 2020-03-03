Function New-DbsDocTemplate {
    <#
.SYNOPSIS
    Creates a documentation template in markdown that makes it easy to provide the necessary documentation to auditors
.DESCRIPTION

    Creates a documentation template in markdown that makes it easy to provide the necessary documentation to auditors

.PARAMETER FilePath
    The output markdown file path

.PARAMETER Version
    The SQL Server version. 2016 by default.

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    New-DbsDocTemplate -FilePath C:\temp\sql2016.md

    Creates a DISA documentation template for 2016

.EXAMPLE
    New-DbsDocTemplate -FilePath C:\temp\sql2014.md -Version 2014

    Creates a DISA documentation template for 2014

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [string]$FilePath,
        [int]$Version = 2016,
        [ValidateSet("Description", "FixText", "Check")]
        [string[]]$Include = @("Description", "FixText", "Check"),
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\set-defaults.ps1"
    }
    process {
        $vulns = Get-DbsStig | Where-Object SqlVersion -eq $Version
        Set-Content -Path $FilePath -Value ""
        foreach ($vuln in $vulns) {
            $vulnid = $vuln.VulnId
            $title = $vuln.Title
            $fixtext = ($vuln.FixText).Replace('\�', '').Replace('\Â  ', ' ')
            $description = ($vuln.Description).Replace('\�', '').Replace('\Â  ', ' ')
            $check = ($vuln.Check).Replace('\�', '').Replace('\Â  ', ' ')

            Add-Content -Path $FilePath -Value "## $vulnid - $title"
            Add-Content -Path $FilePath -Value "`r`n"
            if ($Include -contains "Description") {
                Add-Content -Path $FilePath -Value "### Description"
                Add-Content -Path $FilePath -Value $description
                Add-Content -Path $FilePath -Value "`r`n"
            }
            if ($Include -contains "FixText") {
                Add-Content -Path $FilePath -Value "### Fix text"
                Add-Content -Path $FilePath -Value $fixtext
                Add-Content -Path $FilePath -Value "`r`n"
            }
            if ($Include -contains "Check") {
                Add-Content -Path $FilePath -Value "### Check"
                Add-Content -Path $FilePath -Value $check
                Add-Content -Path $FilePath -Value "`r`n"
            }
            Add-Content -Path $FilePath -Value "`r`n"
        }
        Get-ChildITem -Path $FilePath
    }
}
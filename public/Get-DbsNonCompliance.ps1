function Get-DbsNonCompliance {
    <#
    .SYNOPSIS
        Easily see non-compliant server info

    .DESCRIPTION
        Easily see non-compliant server info

    .PARAMETER Path
        The file/files/directories to compare

    .PARAMETER EnableException
        By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
        This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
        Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

    .NOTES
        Author: Chrissy LeMaire (@cl), netnerds.net
        Copyright: (c) 2020 by Chrissy LeMaire, licensed under MIT
        License: MIT https://opensource.org/licenses/MIT

    .EXAMPLE
        Get-ChildItem R:\disa | Get-DbsNonCompliance

        Easily see non-compliant server info

    .EXAMPLE
        Export-DbsInstance -SqlInstance sql2017, sql01, sql02 | Get-DbsNonCompliance

        Easily see non-compliant server info
    #>
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline)]
        [Alias("FilePath")]
        [System.IO.FileInfo[]]$Path = (Get-PSFConfigValue -FullName dbadisa.path.export),
        [switch]$EnableException
    )
    begin {
        . "$script:ModuleRoot\private\Set-Defaults.ps1"
        $files = @()
    }
    process {
        try {
            $files += Get-ChildItem -Path $Path -Recurse -ErrorAction Stop | Where-Object Name -match noncompliant
        } catch {
            Stop-Function -Message "Failure processing $Path" -ErrorRecord $_
        }
    }
    end {
        $commands = Get-Command -Module dbadisa

        foreach ($file in ($files | Sort-Object -Unique FullName)) {
            $instance = (Split-Path -Path $file.Directory.Parent.FullName -Leaf).Replace('$','\')
            $noncompliant = (Split-Path -Path $file -Leaf).Replace("-noncompliant.xml","")
            $command = $commands | Where-Object Name -match $noncompliant | Select-Object -First 1
            $thishelp = Get-Help $command -Full

            $tagsRex = ([regex]'(?m)^[\s]{0,15}Tags:(.*)$')
            $as = $thishelp.AlertSet | Out-String -Width 600
            $tags = $tagsrex.Match($as).Groups[1].Value | Where-Object { $PSItem -match 'V-' }
            $tags = $tags.Replace(", NonCompliantResults", "")
            [pscustomobject]@{
                SqlInstance = $instance
                NonCompliant = $noncompliant
                ID = $tags.Trim().Split(",")
            } | Select-DefaultView -Property SqlInstance, NonCompliant, ID -Type NonCompliant
        }
    }
}
<#
.SYNOPSIS
Returns the release notes for the module - organised by date

.DESCRIPTION
Grabs the release notes for the dbadisa module and returns either the latest or all of them

.PARAMETER Latest
A Switch to return the latest release notes only

.EXAMPLE
Get-DbsReleaseNote

Returns the release notes for the dbadisa module

.EXAMPLE
Get-DbsReleaseNote -Latest

Returns just the latest release notes for the dbadisa module

.LINK
https://dbadisa.readthedocs.io/en/latest/functions/Get-DbsReleaseNote/

.NOTES
30/05/2012 - RMS
#>
function Get-DbsReleaseNote {
    Param (
        [switch]$Latest
    )

    $releasenotes = Get-Content $ModuleRoot\RELEASE.md -Raw

    if ($Latest) {
        ($releasenotes -Split "##Latest")[0]
    } else {
        $releasenotes
    }
}
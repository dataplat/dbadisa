<#
.SYNOPSIS
    Clears the data source directory created by Update-DbsPowerBiDataSource
.DESCRIPTION
    Clears the data source directory created by Update-DbsPowerBiDataSource ("C:\windows\temp\dbadisa\*.json" by default). This command makes it easier to clean up data used by PowerBI via Start-DbsPowerBi.
.PARAMETER Path
    The directory to your JSON files, which will be removed. "C:\windows\temp\dbadisa\*.json" by default
.PARAMETER Environment
    Removes the JSON files for a specific environment
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
.EXAMPLE
    Clear-DbsPowerBiDataSource
    Removes "$env:windir\temp\dbadisa\*.json"
.EXAMPLE
    Clear-DbsPowerBiDataSource -Environment Production
    Removes "$env:windir\temp\dbadisa\*Production*.json"

.LINK
https://dbadisa.readthedocs.io/en/latest/functions/Clear-DbsPowerBiDataSource/
#>
function Clear-DbsPowerBiDataSource {
    [CmdletBinding()]
    param (
        [string]$Path = "$env:windir\temp\dbadisa",
        [string]$Environment,
        [switch]$EnableException
    )
    if($IsLinux){
        Write-PSFMessage "We cannot run this command from linux at the moment" -Level Warning
        Return
        }
    $null = Remove-Item "$Path\*$Environment*.json" -ErrorAction SilentlyContinue
}
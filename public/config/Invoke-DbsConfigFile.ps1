<#
.SYNOPSIS
Opens the default location of the json config file for easy edits.

.DESCRIPTION
Opens the default location of the json config file for easy edits. Follow with Import-DbsConfig to import changes.

.PARAMETER Path
The path to open, by default is "$script:localapp\config.json"

.PARAMETER EnableException
By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
Invoke-DbsConfigFile

Opens "$script:localapp\config.json" for editing. Follow with Import-DbsConfig.

.LINK
https://dbadisa.readthedocs.io/en/latest/functions/Invoke-DbsConfigFile/

#>
function Invoke-DbsConfigFile {
    [CmdletBinding()]
    param (
        [string]$Path = "$script:localapp\config.json",
        [switch]$EnableException
    )

    process {
        if (-not (Test-Path -Path $Path)) {
            Stop-PSFFunction -Message "$Path does not exist. Run Export-DbsConfig to create a file."
            return
        }

        try {
            Invoke-Item -Path $Path
            Write-PSFMessage -Level	Output -Message "Remember to run Import-DbsConfig when you've finished your edits"
        } catch {
            Stop-PSFFunction -Message "Failure" -ErrorRecord $_
            return
        }
    }
}
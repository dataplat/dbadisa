#requires -Version 3.0
$script:ModuleRoot = $PSScriptRoot
function Import-ModuleFile {
    <#
		.SYNOPSIS
			Loads files into the module on module import.

		.DESCRIPTION
			This helper function is used during module initialization.
			It should always be dotsourced itself, in order to proper function.

			This provides a central location to react to files being imported, if later desired

		.PARAMETER Path
			The path to the file to load

		.EXAMPLE
			PS C:\> . Import-ModuleFile -File $function.FullName

			Imports the file stored in $function according to import policy
	    #>
    [CmdletBinding()]
    Param (
        [string]
        $Path
    )

    if ($doDotSource) { . $Path }
    else { $ExecutionContext.InvokeCommand.InvokeScript($false, ([scriptblock]::Create([io.file]::ReadAllText($Path))), $null, $null) }
}

# Import all internal functions
foreach ($function in (Get-ChildItem "$ModuleRoot\private" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $function.FullName
}

# Import all public functions
foreach ($function in (Get-ChildItem "$ModuleRoot\public" -Filter "*.ps1" -Recurse -ErrorAction Ignore)) {
    . Import-ModuleFile -Path $function.FullName
}

# Setup initial collections
if (-not $script:kbcollection) {
    $script:kbcollection = @{ }
}

if (-not $script:compcollection) {
    $script:compcollection = @{ }
}

# Register autocompleters
Register-PSFTeppScriptblock -Name Version -ScriptBlock { "2008", "2012", "2014", "2016" }

# Register the actual auto completer
Register-PSFTeppArgumentCompleter -Command Get-DbsStig -Parameter Version -Name Version

# some configs to help with autocompletes and other module level stuff
if ($IsLinux) {
    Set-PSFConfig -Module dbadisa -Name app.localapp -Value "$home\dbadisa" -Initialize -Description "Persisted files live here"
    Set-PSFConfig -Module dbadisa -Name app.maildirectory -Value "$home\dbadisa\dbadisa.mail" -Initialize -Description "Files for mail are stored here"
    Set-PSFConfig -Module dbadisa -Name path.export -Value "$home\dbadisa\exports" -Initialize -Description "Default location of exports"
} else {
    Set-PSFConfig -Module dbadisa -Name app.localapp -Value "$env:localappdata\dbadisa" -Initialize -Description "Persisted files live here"
    Set-PSFConfig -Module dbadisa -Name app.maildirectory -Value "$env:localappdata\dbadisa\dbadisa.mail" -Initialize -Description "Files for mail are stored here"
    Set-PSFConfig -Module dbadisa -Name path.export -Value "$home\Documents\dbadisa" -Initialize -Description "Default location of exports"
}

Set-PSFConfig -Module dbadisa -Name app.auditname -Value "DISA_STIG" -Initialize -Description "The standardized name of your DISA STIG Audit. Defaults to DISA_STIG."

$script:allnumbers = @(90, 100, 110, 120, 130, 140, 150, 160, 170, 180, 190, 200)

Register-PSFTeppScriptblock -Name ExportExclude -ScriptBlock {
    $commands = Get-Command -module dbadisa | Where-Object { $PSItem.Verb -in 'Get', 'Test' -and $PSItem.Name -match 'Dbs' -and $PSItem.Name -notin 'Get-DbsStig' } | Select-Object -ExpandProperty Name
    $commands -Replace ".*-Dbs", ""
}

Register-PSFTeppArgumentCompleter -Command Export-DbsInstance -Parameter Exclude -Name ExportExclude

Register-PSFTeppScriptblock -Name StigExclude -ScriptBlock {
    $verbs = 'Set', 'Disable', 'Enable', 'Repair', 'Remove', 'Revoke'
    $commands = Get-Command -module dbadisa | Where-Object { $PSItem.Verb -in $verbs -and $PSItem.Name -match 'Dbs' -and $PSItem.Name -ne 'Set-DbsDbFileSize' } | Select-Object -ExpandProperty Name
    $commands -Replace ".*-Dbs", ""
}

Register-PSFTeppArgumentCompleter -Command Start-DbsStig -Parameter Exclude -Name StigExclude
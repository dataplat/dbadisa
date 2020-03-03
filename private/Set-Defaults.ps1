$PSDefaultParameterValues['*:Credential'] = $Credential
$PSDefaultParameterValues['*:SqlCredential'] = $SqlCredential
$PSDefaultParameterValues['Connect-DbaInstance:DisableException'] = ($EnableException -eq $false)
#$PSDefaultParameterValues['*Dba*:EnableException'] = $true
#$PSDefaultParameterValues['*Dbs*:EnableException'] = $true
$PSDefaultParameterValues['Stop-PSFFunction:EnableException'] = $EnableException
<#
.SYNOPSIS
Resets configuration entries to their default values.

.DESCRIPTION
This function unregisters configuration values and then registers them back with the default values and type.

This can be used to get the dbadisa back to default state of configuration, or to resolve problems with a specific setting.

.PARAMETER Name
Name of the configuration key.

.EXAMPLE
Reset-DbsConfig

Resets all the configuration values for dbadisa.

.EXAMPLE
Reset-DbsConfig -Name policy.recoverymodel.type

Resets the policy.recoverymodel.type to the default value and type.

.LINK
https://dbadisa.readthedocs.io/en/latest/functions/Reset-DbsConfig/
#. $script:ModuleRoot/internal/functions/Invoke-ConfigurationScript.ps1
#>
function Reset-DbsConfig {
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "")]
    [CmdletBinding(DefaultParameterSetName = "FullName")]
    param (
        [Parameter(Mandatory = $false)]
        [string[]]$Name
    )
    process {
        if (!$Name) {
            # no name provided, get all known dbadisa settings
            $resolvedName = (Get-DbsConfig).Name
        } elseif ($Name -match '\*') {
            # wildcard is used, get only the matching settings
            $resolvedName = (Get-DbsConfig).Name | Where-Object { $psitem -like $Name }
        } else {
            $resolvedName = $Name
        }

        @($resolvedName).ForEach{
            $localName = $psitem.ToLower()
            if (-not (Get-DbsConfig -Name $localName)) {
                Stop-PSFFunction -FunctionName Reset-DbsConfig -Message "Setting named $localName does not exist. Use Get-DbsCheck to get the list of supported settings."
            } else {
                Write-PSFMessage -FunctionName Reset-DbsConfig -Message "resetting $localName"
                Unregister-PSFConfig -Module dbadisa -Name $localName
                [PSFramework.Configuration.ConfigurationHost]::Configurations.Remove("dbadisa.$localName") | Out-Null
            }
        }

        # set up everything that is now missing back to the default values
        Invoke-ConfigurationScript

        # display the new values
        @($resolvedName).ForEach{
            Get-DbsConfig -Name $psitem
        }
    }
}
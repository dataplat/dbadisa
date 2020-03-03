$script:ModuleRoot = $PSScriptRoot

if ($env:appveyor) {
    $env:psmodulepath = "$env:psmodulepath; C:\projects; C:\projects\dbadisa"
}

$PSDefaultParameterValues['Set-DbaSpConfigure:WarningAction'] = 'SilentlyContinue'
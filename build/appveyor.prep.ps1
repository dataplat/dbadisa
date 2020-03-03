Add-AppveyorTest -Name "appveyor.prep" -Framework NUnit -FileName "appveyor.prep.ps1" -Outcome Running
$sw = [system.diagnostics.stopwatch]::startNew()

if (-not (Test-Path -Path 'C:\Program Files\WindowsPowerShell\Modules\dbatools')) {
    #Get PSScriptAnalyzer (to check warnings)
    Write-Host -Object "appveyor.prep: Install PSScriptAnalyzer" -ForegroundColor DarkGreen
    Install-Module -Name PSScriptAnalyzer -SkipPublisherCheck -WarningAction SilentlyContinue | Out-Null

    #Get Pester (to run tests)
    Write-Host -Object "appveyor.prep: Install Pester" -ForegroundColor DarkGreen
    choco install pester | Out-Null

    #Get PSFramework (dependency)
    Write-Host -Object "appveyor.prep: Install PSFramework" -ForegroundColor DarkGreen
    Install-Module -Name PSFramework -SkipPublisherCheck -WarningAction SilentlyContinue | Out-Null

    #Get dbatools (dependency)
    Write-Host -Object "appveyor.prep: Install dbatools" -ForegroundColor DarkGreen
    Install-Module -Name dbatools -SkipPublisherCheck -WarningAction SilentlyContinue | Out-Null

    #Get dbachecks (dependency)
    Write-Host -Object "appveyor.prep: Install dbachecks" -ForegroundColor DarkGreen
    Install-Module -Name dbachecks -SkipPublisherCheck -WarningAction SilentlyContinue | Out-Null
}
$null = mkdir C:\temp

$sw.Stop()
Update-AppveyorTest -Name "appveyor.prep" -Framework NUnit -FileName "appveyor.prep.ps1" -Outcome Passed -Duration $sw.ElapsedMilliseconds
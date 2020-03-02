$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Command gets current agent log using LogNumber parameter" {
        $results = Disable-DbsBrowser -ComputerName $env:COMPUTERNAME
        It "Results are not empty" {
            $results | Should Not Be $Null
        }
    }
}
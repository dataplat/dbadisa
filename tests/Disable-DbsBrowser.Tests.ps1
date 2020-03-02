$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Write-Host -Object "Running $PSCommandpath" -ForegroundColor Cyan
. "$PSScriptRoot\constants.ps1"

Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Command gets current agent log using LogNumber parameter" {
        $results = Disable-DbsBrowser -ComputerName $env:COMPUTERNAME
        It "should report that browser is disabled" {
            $results.BrowserDisabled | Should -Be $true
        }
        $service = Get-Service *SQLBrowser*  -ComputerName $env:COMPUTERNAME
        It "should actually be disalbed" {
            $service.StartType | Should -Be 'Disabled'
        }
    }
}
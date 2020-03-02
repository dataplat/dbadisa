$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Disables SQL Server Browser on localhost" {
        $results = Disable-DbsBrowser -ComputerName $env:COMPUTERNAME
        It -Skip "should report that browser is disabled" {
            $results.BrowserDisabled | Should -Be $true
        }
        $service = Get-Service *SQLBrowser*  -ComputerName $env:COMPUTERNAME
        It -Skip "should actually be disabled" {
            $service.StartType | Should -Be 'Disabled'
        }
    }
}
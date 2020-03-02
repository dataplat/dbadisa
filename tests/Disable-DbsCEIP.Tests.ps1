$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Disables SQL Server Browser on localhost" {
        $results = Disable-DbsCEIP -ComputerName $env:COMPUTERNAME
        It "should report that CEIP was disabled" {
            $results.Enabled | Should -Be $false
        }
        $services = Get-Service *SQLTELEMETRY*  -ComputerName $env:COMPUTERNAME
        foreach ($service in $services) {
            It "$($service.Name) should actually be disabled" {
                $service.StartType | Should -Be "Disabled"
            }
        }
    }
}
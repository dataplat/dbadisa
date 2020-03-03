$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $null = Set-DbaSpConfigure -SqlInstance $env:COMPUTERNAME -Name AllowPolybaseExport -Value 1
    }
    Context "Disables database containment on localhost" {
        It "should report that containment is disabled" {
            $results = Disable-DbsPolybaseExport -SqlInstance $env:COMPUTERNAME
            $results.NewValue | Should -Be 0
        }

        It "should actually be disabled" {
            $config = Get-DbaSpConfigure -SqlInstance $env:COMPUTERNAME -Name AllowPolybaseExport
            $config.RunningValue | Should -Be 0
        }
    }
}
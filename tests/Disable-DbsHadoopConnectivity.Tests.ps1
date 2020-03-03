$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $null = Set-DbaSpConfigure -SqlInstance $env:COMPUTERNAME -Name HadoopConnectivity -Value 1 -WarningAction SilentlyContinue
    }
    Context "Disables polybase on localhost" {
        It "should report that polybase is disabled" {
            $results = Disable-DbsHadoopConnectivity -SqlInstance $env:COMPUTERNAME -WarningAction SilentlyContinue
            $results.NewValue | Should -Be 0
        }

        It "should actually be disabled" {
            $config = Get-DbaSpConfigure -SqlInstance $env:COMPUTERNAME -Name HadoopConnectivity
            $config.RunningValue | Should -Be 0
        }

        $results = Disable-DbsHadoopConnectivity -ComputerName $env:COMPUTERNAME -WhatIf
        It "should not return any objects when using whatif" {
            $results | Should -Be $null
        }
    }
}
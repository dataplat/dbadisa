$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $server = Connect-DbaInstance -SqlInstance $env:COMPUTERNAME
        $server.Settings.LoginMode = "Mixed"
        $server.Alter()
    }
    Context "Disables polybase on localhost" {
        It "should disable mixed mode" {
            $results = Disable-DbsMixedMode -SqlInstance $env:COMPUTERNAME
            $results.LoginMode | Should -match Integrated
        }

        It "should actually be disabled" {
            $server = Connect-DbaInstance -SqlInstance $env:COMPUTERNAME
            $server.Settings.LoginMode | Should -Be Integrated
        }

        $results = Disable-DbsMixedMode -SqlInstance $env:COMPUTERNAME -WhatIf
        It "should not return any objects when using whatif" {
            $results | Should -Be $null
        }
    }
}
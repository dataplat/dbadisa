$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        # Feature 'Advanced Analytics Extensions' is not installed.
        # $null = Set-DbaSpConfigure -SqlInstance $env:COMPUTERNAME -Name ExternalScriptsEnabled -Value 1
    }
    Context "Disables external scripts on localhost" {
        It -Skip "should report that polybase is disabled" {
            $results = Disable-DbsExternalScripts -SqlInstance $env:COMPUTERNAME
            $results.NewValue | Should -Be 0
        }

        It -Skip "should actually be disabled" {
            $config = Get-DbaSpConfigure -SqlInstance $env:COMPUTERNAME -Name ExternalScriptsEnabled
            $config.RunningValue | Should -Be 0
        }

        $results = Disable-DbsExternalScripts -SqlInstance $env:COMPUTERNAME -WhatIf -WarningAction SilentlyContinue
        It "should not return any objects when using whatif" {
            $results | Should -Be $null
        }
    }
}
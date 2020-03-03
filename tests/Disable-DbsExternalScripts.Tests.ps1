$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    BeforeAll {
        $null = Set-DbaSpConfigure -SqlInstance $env:COMPUTERNAME -Name ExternalScriptsEnabled -Value 1
    }
    Context "Disables external scripts on localhost" {
        $results = Disable-DbsExternalScripts -SqlInstance $env:COMPUTERNAME
        It "should report that polybase is disabled" {
            $results.NewValue | Should -Be 0
        }

        $config = Get-DbaSpConfigure -SqlInstance $env:COMPUTERNAME -Name ExternalScriptsEnabled
        It "should actually be disabled" {
            $config.RunningValue | Should -Be 0
        }
    }
}
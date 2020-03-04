$CommandName = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe "$commandname Integration Tests" -Tags "IntegrationTests" {
    Context "Disables some protocols on localhost" {
        It "should report that a protocol is disabled" {
            $results = Disable-DbsProtocol -ComputerName $env:COMPUTERNAME
            $results.Disabled | Should -Contain $true
        }
        It "should really be disabled" {
            Get-DbaInstanceProtocol -ComputerName $env:COMPUTERNAME | Where-Object Name -ne Tcp | Select-Object IsEnabled | Should -Not -Contain $true
        }
        $results = Disable-DbsProtocol -ComputerName $env:COMPUTERNAME -WhatIf
        It "should not return any objects when using whatif" {
            $results | Should -Be $null
        }
    }
}
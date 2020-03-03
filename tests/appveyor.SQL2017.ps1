$indent = '...'
Write-Host -Object "Running $PSCommandpath" -ForegroundColor DarkGreen
Import-Module dbatools

$sqlinstance = "localhost\SQL2017"
$instance = "SQL2017"
$port = "1433"

Write-Host -Object "$indent Setting up AppVeyor Services" -ForegroundColor DarkGreen
Set-Service -Name SQLBrowser -StartupType Automatic -WarningAction SilentlyContinue
Set-Service -Name "SQLAgent`$$instance" -StartupType Automatic -WarningAction SilentlyContinue
Start-Service SQLBrowser -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

Write-Host -Object "$indent Changing the port on $instance to $port" -ForegroundColor DarkGreen
$wmi = New-Object Microsoft.SqlServer.Management.Smo.Wmi.ManagedComputer
$uri = "ManagedComputer[@Name='$env:COMPUTERNAME']/ ServerInstance[@Name='$instance']/ServerProtocol[@Name='Tcp']"
$Tcp = $wmi.GetSmoObject($uri)
foreach ($ipAddress in $Tcp.IPAddresses) {
    $ipAddress.IPAddressProperties["TcpDynamicPorts"].Value = ""
    $ipAddress.IPAddressProperties["TcpPort"].Value = $port
}
$Tcp.Alter()
Write-Host -Object "$indent Starting $instance" -ForegroundColor DarkGreen

Start-Service "MSSQL`$$instance" -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

do {
    Start-Sleep 3
    $null = (& sqlcmd -S "$sqlinstance" -b -Q "select 1" -d master)
}
while ($lastexitcode -ne 0 -and $t++ -lt 10)

# Agent sometimes takes a moment to start
do {
    Write-Host -Object "$indent Waiting for SQL Agent to start" -ForegroundColor DarkGreen
    Start-Sleep 3
}
while ((Get-Service "SQLAgent`$$instance").Status -ne 'Running' -and $z++ -lt 10)

$server = Connect-DbaInstance -SqlInstance $sqlinstance
$server.Query("IF NOT EXISTS (select * from sys.symmetric_keys where name like '%DatabaseMasterKey%') CREATE MASTER KEY ENCRYPTION BY PASSWORD = '<StrongPassword>'")
$server.Query("IF EXISTS ( SELECT * FROM sys.tcp_endpoints WHERE name = 'End_Mirroring') DROP ENDPOINT endpoint_mirroring")
$server.Query("CREATE CERTIFICATE dbatoolsci_AGCert WITH SUBJECT = 'AG Certificate'")
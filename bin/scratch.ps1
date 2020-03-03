

function Invoke-SqlQuery ($sql) {
    foreach ($instance in $global:servers) {
        try {
            $server = Connect-DbaSqlServer -SqlInstance $instance
            $server.Query($sql)
        } catch {
            Write-Warning "Couldn't connect to $instance"
        }
    }
}

function Set-StigSqlServer ($str) {
    if ($str) {
        $global:sqlservers = $global:servers = $str
    } else {
        $global:sqlservers = $global:servers = $allsqlservers | Out-GridView -Passthru
    }
}

function Set-StigWinServer ($str) {
    if ($str) {
        $global:winservers = $str
    } else {
        $global:winservers = $allwinservers | Out-GridView -Passthru
    }
}

function Set-StigServer ([dbainstance]$str) {
    $global:sqlservers = $global:servers = $str.InputObject
    $cluster = $clusters | Where Cluster -in $str.InputObject
    if ($cluster) {
        $global:winservers = $cluster.Nodes
    } else {
        $global:winservers = $str.ComputerName
    }
    Write-PesterMessage "SQL Server set to: $global:sqlservers"
    Write-PesterMessage "Windows Server set to: $global:winservers"
}

function Reset-StigServer {
    $global:winservers = $allwinservers
    $global:sqlservers = $global:servers = $allsqlservers
}

function Add-StigTest {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline, Mandatory)]
        [string[]]$Test
    )
    begin {
        function Update-StigTest {
            [CmdletBinding()]
            param (
                [parameter(ValueFromPipeline, Mandatory)]
                [string]$Version,
                [parameter(Mandatory)]
                [string[]]$Test
            )
            process {
                $server = Connect-DbaSqlServer -SqlInstance localhost
                foreach ($v in $version) {
                    $test = $test -join ","
                    $test = $test.Trim()
                    $sql = "Update stigs.dbo.checklist SET tests = '$test' WHERE version = '$v'"
                    $server.Query($sql)
                    "Executing: $sql"
                }
            }
        }

        if (!$test) {
            [System.Reflection.Assembly]::LoadWithPartialName("System.windows.forms") | Out-Null
            $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
            $OpenFileDialog.Multiselect = $true
            $OpenFileDialog.initialDirectory = 'S:\DISA\Tests'
            $OpenFileDialog.filter = "PowerShell (*.ps1)| *.ps1"
            $OpenFileDialog.ShowDialog() | Out-Null
            if (-not $OpenFileDialog.FileName) { break }
            foreach ($file in $OpenFileDialog.FileNames) {
                $partial = Split-Path $file -Leaf
                $test += $partial.Split(".")[0]
            }
        }
    }
    process {
        $server = Connect-DbaSqlServer -SqlInstance localhost
        $server.Query("select id, version, severity, tests, title, description, checkcontent, fixtext from stigs.dbo.checklist") | Out-GridView -Passthru | Select -ExpandProperty Version | Update-StigTest -Test $test
    }
}

function Invoke-StigTest {
    $server = Connect-DbaInstance -SqlInstance localhost
    $tests = Get-StigTest | select id, version, severity, tests, title, description, checkcontent, fixtext | Out-GridView -Passthru | Select -ExpandProperty Tests
    foreach ($test in $tests) {
        if ($test -ne [System.DBNull]) {
            foreach ($single in ($test -split ",")) {
                $cleant = $single.trim()
                . "S:\DISA\Tests\$cleant.Tests.ps1"
            }
        } else {
            Write-Warning "No test available"
        }
    }
}

function Find-PesterTest {
    $a = @()
    foreach ($test in (Get-ChildItem S:\DISA\Tests)) {
        $filename = Split-Path $test -Leaf
        $a += [pscustomobject]@{
            File    = $filename
            Content = (Get-Content $test.Fullname -Raw)
        }
    }
    $tests = $a | Out-GridView -Passthru
    foreach ($test in $tests) {
        Add-StigTest -Test $test.File.Split(".")[0]
    }
}


function Add-DocRequirement {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string[]]$Version
    )
    begin {
        function Update-DocRequirement {
            [CmdletBinding()]
            param (
                [parameter(ValueFromPipeline, Mandatory)]
                [string]$Version
            )
            process {
                $server = Connect-DbaSqlServer -SqlInstance localhost
                foreach ($v in $version) {
                    $test = $test -join ","
                    $test = $test.Trim()
                    $sql = "Update stigs.dbo.checklist SET Documentation = 1 WHERE version = '$v'"
                    $server.Query($sql)
                    "Executing: $sql"
                }
            }
        }
    }
    process {
        $server = Connect-DbaSqlServer -SqlInstance localhost
        $server.Query("select id, version, documentation, severity, tests, title, description, checkcontent, fixtext from stigs.dbo.checklist") | Out-GridView -Passthru | Select -ExpandProperty Version | Update-DocRequirement
    }
}

function Get-StigTest ($version) {
    $server = Connect-DbaSqlServer -SqlInstance localhost
    $sql = "SELECT * FROM [stigs].[dbo].[checklist]"

    if ($version) {
        $sql = "$sql WHERE version = '$version'"
    }

    $server.Query($sql)
}

function Show-StigTest ($version) {
    Get-StigTest -Version $version | Out-GridView -Passthru
}

function Show-ExchangeStig {
    $server = Connect-DbaSqlServer -SqlInstance localhost
    $sql = "SELECT [Vulnerability]
      ,[RuleID]
      ,[Version]
      ,[Severity]
      ,[Title]
      ,[Description]
      ,[Check]
      ,[Fix]
  FROM [dbo].[webrules]"

    $server.Query($sql) | Out-GridView -Passthru
}

Function Import-Checklist {
    [CmdletBinding()]
    param (
        [string]$Path = 'S:\DISA\xml\sqlserver.ckl'
    )
    begin {
        Function Get-Checklist {
            $a = [xml](Get-Content $path)
            foreach ($b in $a.Checklist.Stigs.iSTIG.Vuln) {
                [pscustomobject]@{
                    Vulnerability            = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Vuln_Num).ATTRIBUTE_DATA
                    Severity                 = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Severity).ATTRIBUTE_DATA
                    Group                    = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Group_Title).ATTRIBUTE_DATA
                    Id                       = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Rule_ID).ATTRIBUTE_DATA
                    Version                  = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Rule_Ver).ATTRIBUTE_DATA
                    Title                    = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Rule_Title).ATTRIBUTE_DATA
                    Description              = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Vuln_Discuss).ATTRIBUTE_DATA
                    IAControls               = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq IA_Controls).ATTRIBUTE_DATA
                    CheckContent             = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Check_Content).ATTRIBUTE_DATA
                    FixText                  = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Fix_Text).ATTRIBUTE_DATA
                    FalsePositives           = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq False_Positives).ATTRIBUTE_DATA
                    FalseNegatives           = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq False_Negatives).ATTRIBUTE_DATA
                    Documentable             = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Documentable).ATTRIBUTE_DATA
                    Mitigations              = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Mitigations).ATTRIBUTE_DATA
                    PotentialImpact          = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Potential_Impact).ATTRIBUTE_DATA
                    ThirdPartyTools          = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Third_Party_Tools).ATTRIBUTE_DATA
                    MitigationControl        = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Mitigation_Control).ATTRIBUTE_DATA
                    Responsibility           = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Responsibility).ATTRIBUTE_DATA
                    SecurityOverrideGuidance = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Security_Override_Guidance).ATTRIBUTE_DATA
                    CheckContentRef          = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Check_Content_Ref).ATTRIBUTE_DATA
                    Class                    = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq Class).ATTRIBUTE_DATA
                    STIGRef                  = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq STIGRef).ATTRIBUTE_DATA
                    TargetKey                = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq TargetKey).ATTRIBUTE_DATA
                    CCIREF                   = ($b.STIG_DATA | Where VULN_ATTRIBUTE -eq CCI_REF).ATTRIBUTE_DATA
                }
            }
        }
    }
    process {
        $datatable = Get-Checklist
        $datatable | Out-DbaDataTable | Write-DbaDataTable -SqlInstance localhost -Table tempdb.dbo.checklist # -AutoCreate
    }
}


function Invoke-PSFCommand {
    [CmdletBinding()]
    param (
        [string]$ComputerName,
        [scriptblock]$ScriptBlock
    )

    if ($ComputerName -eq $env:COMPUTERNAME -or $computername -eq "." -or $Computername -eq "localhost") {
        Invoke-Command -ScriptBlock $ScriptBlock
    } else {
        Invoke-Command -ScriptBlock $ScriptBlock -ComputerName $ComputerName
    }
}

function Invoke-InstallCheck {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string]$ComputerName,
        [string]$Name

    )
    process {
        $scriptblock = {
            $paths = "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall", "HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall"
            foreach ($path in $paths) {
                Get-ChildItem -Verbose $path | ForEach-Object { $_.GetValue("DisplayName") }
            }
        }

        try {
            $commandresults = Invoke-PSFCommand -ComputerName $ComputerName -ScriptBlock $scriptblock -ErrorAction Stop | Where-Object { $_ -match $name }

            if ($commandresults) {
                foreach ($result in $commandresults) {
                    [pscustomobject]@{
                        ComputerName = $ComputerName
                        ProgramName  = $name
                        DisplayName  = $result
                        Exists       = $true
                    }
                }
            } else {
                [pscustomobject]@{
                    ComputerName = $ComputerName
                    ProgramName  = $name
                    DisplayName  = $null
                    Exists       = $false
                }
            }
        } catch {
            if ($_ -notmatch "exist") {
                [pscustomobject]@{
                    ComputerName = $ComputerName
                    ProgramName  = $name
                    DisplayName  = "Error: $_"
                    Exists       = "Unknown"
                }
            }
        }
    }
}

function Get-SqlServers {
    #Get-DbaRegisteredServerName -SqlInstance mgmtserver
    "mgmtserver"
}

function Get-WindowsServers {
    <#
	$winservers = @()
	foreach ($server in (Get-SqlServers)) {
		$instance = [dbainstanceparameter]$server
		$winservers += (Resolve-DbaNetworkName -ComputerName $instance.ComputerName).ComputerName
	}
	$winservers
    #>
    "mgmtserver"
}

function Invoke-FipsCheck {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string]$ComputerName

    )
    process {
        try {
            $scriptblock = { Get-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy' }
            $results = Invoke-PSFCommand -ComputerName $ComputerName -ScriptBlock $scriptblock -ErrorAction Stop
            [pscustomobject]@{
                ComputerName = $ComputerName
                Enabled      = $results.Enabled
            }
        } catch {
            [pscustomobject]@{
                ComputerName = $ComputerName
                Enabled      = "Unknown"
            }
        }
    }
}

function Invoke-StrongNameVerification {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string]$ComputerName

    )
    # Get-ADComputer -Filter { OperatingSystem -like '*Windows*' } | select -ExpandProperty name | Invoke-StrongNameVerification
    process {
        try {
            $scriptblock = { Get-ItemProperty -Path 'HKLM:\Software\Microsoft\StrongName\Verification' }
            Invoke-PSFCommand -ComputerName $ComputerName -ScriptBlock $scriptblock -ErrorAction Stop
        } catch {
            Write-Warning "$computername has nothing"
        }
    }
}

function Get-RecoveryModel {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [object[]]$SqlInstance

    )
    process { Get-DbaDatabase -SqlInstance $sqlinstance | Select SqlInstance, Name, RecoveryModel }
}

function Set-RecoveryModel {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [object]$SqlInstance

    )
    process {
        foreach ($s in (Get-DbaDatabase -SqlInstance $sqlinstance -NoSystemDb | Where RecoveryModel -eq 'Simple' )) {
            $s.RecoveryModel = 'Full'
            $s.Alter()
        }
    }
}

function Enable-FipsCompliance {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string]$ComputerName

    )
    process {
        try {
            $scriptblock = { Set-ItemProperty -Path HKLM:\System\CurrentControlSet\Control\Lsa\FIPSAlgorithmPolicy -name Enabled -value 1 }
            $results = Invoke-PSFCommand -ComputerName $ComputerName -ScriptBlock $scriptblock -ErrorAction Stop

            [pscustomobject]@{
                ComputerName = $ComputerName
                Enabled      = $true
                Notes        = "You must reboot for this setting to take effect"
            }
        } catch {
            write-warning $_
            [pscustomobject]@{
                ComputerName = $ComputerName
                Enabled      = "Unknown"
            }
        }
    }
}

function Get-Trustworthy {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [object]$SqlInstance

    )
    process {
        foreach ($db in (Get-DbaDatabase -SqlInstance $sqlinstance -ExcludeDatabase msdb)) { $db | Select SqlInstance, Name, Trustworthy }
    }
}

function Get-Filestream {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [object]$SqlInstance

    )
    process {
        foreach ($db in (Get-DbaDatabase -SqlInstance $sqlinstance)) { $db | Select SqlInstance, Name, DefaultFileStreamFileGroup, FilestreamDirectoryName, FilestreamNonTransactedAccess }
    }
}

function Get-RecoveryModel {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [object]$SqlInstance

    )
    process {
        foreach ($db in (Get-DbaDatabase -SqlInstance $sqlinstance)) { $db | Select SqlInstance, Name, DefaultFileStreamFileGroup, FilestreamDirectoryName, FilestreamNonTransactedAccess }
    }
}

function Rename-SaLogin {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [object]$SqlInstance

    )
    process {
        $sa = Get-DbaLogin -SqlInstance $SqlInstance -Login sa
        if ($sa) {	$sa.Rename("sqladmin") }
    }
}

function Get-Smalldatetime {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [object]$SqlInstance

    )
    process {
        foreach ($db in (Get-DbaDatabase -SqlInstance $sqlinstance -NoSystemDb)) {
            write-warning "$db on $SqlInstance"
            foreach ($column in ($db.Tables.Columns | Where-Object { $_.Parent.IsSystemObject -ne $true })) {
                if ($column.DataType.Name -eq 'smalldatetime') {
                    [pscustomobject]@{
                        SqlInstance = $db.Parent.Name
                        Database    = $db.Name
                        Table       = $column.Parent.Name
                        Column      = $column.Name
                        Datatype    = $column.DataType.Name
                    }
                }
            }
        }
    }
}

function Add-Trace {
    $servers = Get-DbaRegisteredServerName -sqlinstance localhost -Group Standard, Express
    foreach ($instance in $SqlInstance) {
        $version = (Connect-DbaSqlServer -SqlInstance $server).VersionMajor
        if ($version -eq 12) {
            $sql = Get-Content S:\DISA\sql-scripts\disa\trace-2014.sql
        } else {
            $sql = Get-Content S:\DISA\sql-scripts\disa\trace-2012.sql
        }
        $filepath = (Get-DbaDefaultPath -SqlInstance $server).Data
        $filepath = "$filepath\STIG"
        $servername = $server.Split(".")[0] -Replace '\\', '-'
        $sql = $sql -Replace 'REPLACETHISYALL', "$filepath\trace-$servername"
        write-warning "Adding trace to $server"
        $filename = "S:\DISA\sql-scripts\trace\$servername.sql"
        Set-Content -Value $sql -Path $filename
        try {
            sqlcmd -S $server -i $filename
            Write-Warning "Adding startup to $server"
            Invoke-DbaSqlCmd -ServerInstance $server -Query "EXEC SP_PROCOPTION 'STIG_Trace', 'startup', 'true';"
        } catch {
            write-warning "Had an issue with $server : $_"
        }
    }
}

Function New-StigDirectory {
    foreach ($instance in $SqlInstance) {
        $filepath = (Get-DbaDefaultPath -SqlInstance $server).Data
        $filepath = "$filepath\STIG"
        $exists = Test-DbaSqlPath -SqlInstance $server -Path $filepath
        If ($exists -eq $false) {
            New-DbaSqlDirectory -SqlInstance $server -Path $filepath
        }
    }
}

Function Get-StigFile ($SqlInstance) {
    if ($null -eq $SqlInstance) { $SqlInstance = $servers }
    foreach ($server in $SqlInstance) {
        $filepath = (Get-DbaDefaultPath -SqlInstance $server).Data
        $filepath = "$filepath\STIG"
        Get-DbaFile -SqlInstance $server -Path $filepath
    }
}

function Add-Audit {
    foreach ($instance in $SqlInstance) {
        $currentserver = Connect-DbaSqlServer -SqlInstance $server
        if ($currentserver.EngineEdition -match "Enterprise") {
            $sql = Get-Content S:\DISA\sql-scripts\disa\Audit.sql
            $filepath = (Get-DbaDefaultPath -SqlInstance $server).Data
            $filepath = "$filepath\STIG"
            $sql = $sql -Replace 'REPLACETHISYALL', $filepath
            write-warning "Adding audit to $server"
            $servername = $server.Split(".")[0] -Replace '\\', '-'
            $filename = "S:\DISA\sql-scripts\audit\$servername.sql"
            Set-Content -Value $sql -Path $filename
            sqlcmd -S $server -i $filename
        }
    }
}

Function Add-WinAdmin {
    foreach ($s in $winservers) { Invoke-Command -ComputerName $s -ScriptBlock { net localgroup administrators AD\svc.sqlstig.AD /add } }
}

Function Add-SqlAdmin {
    foreach ($instance in $servers) {
        $server = Connect-DbaSqlServer $instance
        $login = Get-DbaLogin -SqlInstance $server -Login 'AD\NSHQ SQL DBA'

        if ($null -eq $login) {
            Write-Output "Adding to $instance"
            $server.Query("CREATE LOGIN [AD\NSHQ SQL DBA] FROM WINDOWS WITH DEFAULT_DATABASE=[master]")
            $server.Query("EXEC master..sp_addsrvrolemember @loginame = N'AD\NSHQ SQL DBA', @rolename = N'sysadmin'")
        }
    }
}

Function Set-LoginMode {
    #select distinct sqlserver, loginname, dbname   FROM [WatchDBLogins].[dbo].[DbLogins] where loginname not like '%\%' and loginname != ''
    #select distinct sqlserver  FROM [WatchDBLogins].[dbo].[DbLogins] where loginname not like '%\%' and loginname != ''

    $winauthonly = $servers | Where-Object {$_ -notin '' }
    foreach ($s in $winauthonly) {
        try {
            $server = Connect-DbaSqlServer -SqlInstance $s
        } catch {
            continue
        }
        if ($server.LoginMode -ne "Integrated") {
            Write-Warning "Changing $s to Integrated"
            $server.LoginMode = "Integrated"
            $server.Alter()
        }
    }
}

Function Set-ADRecoveryModel {
    $AD = ""
    $dbs = $AD | Get-DbaDatabase -NoSystemDb | Where RecoveryModel -eq Simple

    foreach ($db in $dbs) {
        $db.RecoveryModel = "Full"
        $db.Alter()
    }
}

Function Set-MaxConnections {
    foreach ($instance in $SqlInstance) {
        Set-DbaSpConfigure -SqlInstance $server -ConfigName UserConnections -Value 10000
    }
}

Function Get-MaxConnections {
    foreach ($instance in $SqlInstance) {
        Get-DbaSpConfigure -SqlInstance $server -ConfigName UserConnections
    }
}

Function Test-DiskSpace {
    foreach ($server in $winservers) {
        $datadisk = (Get-DbaDefaultPath -SqlInstance $server).Data
        $disks = Get-DbaDiskSpace -SqlInstance $server -CheckForSql | Where { $_.IsSqlDisk -eq $true -and $_.Name -ne 'C:\' }
        $disks | Where-Object { [regex]::Escape($datadisk) -match [regex]::Escape($_.Name) }
    }
}

Function Restart-SqlServices {
    $scriptblock = { Get-Service MSSQLSERVER | Restart-Service -Force
        Get-Service SQLSERVERAGENT | Start-Service -ErrorAction SilentlyContinue
    }
    foreach ($server in $nonclusters) {
        Write-Warning "Restarting SQL Services on $server"
        Invoke-Command -ComputerName $server -ScriptBlock $scriptblock
    }
}

Function Join-AdminUnc {
    <#
.SYNOPSIS
Internal function. Parses a path to make it an admin UNC.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$servername,
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$filepath
    )
    if (!$filepath) { return }
    if ($filepath.StartsWith("\\")) { return $filepath }

    $servername = $servername.Split("\")[0]

    if ($filepath.length -gt 0 -and $filepath -ne [System.DbNull]::Value) {
        $newpath = Join-Path "\\$servername\" $filepath.replace(':', '$')
        return $newpath
    } else { return }
}

Function Get-Permissions ($servers) {
    if ($null -eq $servers) {
        $servers = Get-DbaRegisteredServerName -SqlInstance localhost # -Group Standard | Where { $_ -notmatch 'AD' }
    }

    foreach ($server in [dbainstance[]]$servers) {
        Clear-DbaSqlConnectionPool
        $defaults = Get-DbaDefaultPath -SqlInstance $server
        $folders = @($defaults.Data, $defaults.Log, $defaults.Backup)
        $folders = $folders | Where { $_ -notmatch 'sqlbackup' -and $_ -notmatch 'server' -and $_ -notmatch '192' }
        $folders = $folders | Select -Unique

        $instance = $server.InstanceName

        $services = Get-DbaSqlService -ComputerName $server -Silent
        $dbengine = $services | Where DisplayName -match "SQL Server \($instance\)"
        $dbaccount = $dbengine.StartName
        $agentengine = $services | Where DisplayName -match "SQL Server Agent \($instance\)"
        $agentaccount = $agentengine.StartName

        if ($dbaccount.length -lt 2) { Write-Warning "Couldn't get service information, moving on"; continue }
        #write-output $server
        foreach ($folder in $folders) {
            $remote = Join-AdminUnc -Servername $server.ComputerName -FilePath $folder
            $acl = Get-Acl $remote
            $access = @()
            foreach ($a in $acl.access) {
                [pscustomobject]@{
                    SqlInstance       = $server
                    Directory         = $folder
                    Owner             = $acl.Owner
                    IdentityReference = $a.IdentityReference
                    FileSystemRights  = $a.FileSystemRights
                    AccessControlType = $a.AccessControlType
                }
            }
        }
    }
}


function Export-LoginDetails {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline, Mandatory)]
        [string[]]$SqlInstance
    )
    process {
        foreach ($instance in $SqlInstance) {
            try { $server = Connect-DbaSqlServer -SqlInstance $instance } catch { Write-Warning $server }
            $serverroles = $dbroles = @()

            foreach ($role in $server.Roles) {
                $serverroles += [pscustomobject]@{
                    Role    = $role.name
                    Members = $role.EnumMemberNames()
                }
            }

            foreach ($db in $server.Databases) {
                foreach ($dbrole in $db.Roles) {
                    $dbroles += [pscustomobject]@{
                        Database = $db.Name
                        Role     = $dbrole.name
                        Members  = $dbrole.EnumMembers()
                    }
                }
            }

            foreach ($login in ($server | Get-DbaLogin)) {
                $serverlogins = $dbmapping = @()
                $name = $login.Name
                $srole = ($serverroles | Where Members -contains $name).Role
                $dbroles = ($dbroles | Where Members -contains $name).Role
                $usermappings = $server | Get-DbaDatabaseUser | Where Login -eq $name

                [pscustomobject]@{
                    SqlInstance      = $instance
                    Login            = $name
                    ServerRoles      = $srole
                    DatabaseMappings = $usermappings
                    DatabaseRoles    = $dbroles
                    Securables       = $server.EnumServerPermissions($name)
                }
            }
        }
    }
}
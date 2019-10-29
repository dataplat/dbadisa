$filename = $MyInvocation.MyCommand.Name.Replace(".Tests.ps1", "")
Describe 'Testing access to backup path' -Tags Storage, DISA, $filename {
	(Get-SqlInstance).ForEach{
		if (-not (Get-DbsConfigValue setup.backuppath)) {
			$backuppath = (Get-DbaDefaultPath -SqlInstance $psitem).Backup
		}
		else {
			$backuppath = Get-DbsConfigValue setup.backuppath
		}
		
		It "$psitem access to the backup path ($backuppath)" {
			Test-DbaSqlPath -SqlInstance $psitem -Path $backuppath | Should be $true
		}
	}
}
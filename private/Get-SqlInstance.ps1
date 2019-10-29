function Get-SqlInstance {
	if ($sqlinstance) {
		return $sqlinstance
	}
	else {
		return (Get-DbsConfigValue Setup.SqlInstance)
	}
}
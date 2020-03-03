function Get-ComputerName {
    if ($computername) {
        return $computername
    } else {
        return (Get-DbsConfigValue Setup.ComputerName)
    }
}
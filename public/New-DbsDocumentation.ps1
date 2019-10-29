Function New-DbsDocumentation {
    $Version = 2014
    $FilePath = "C:\temp\stig.md"
    $vulns = Get-DbsStig | Where-Object SqlVersion -eq $Version
    Set-Content -Path $FilePath -Value ""
    foreach ($vuln in $vulns) {
        $vulnid = $vuln.VulnId
        $title = $vuln.Title
        $fixtext = ($vuln.FixText).Replace('\�', '')

        Add-Content -Path $FilePath -Value "## $vulnid - $title"
        Add-Content -Path $FilePath -Value "`r`n"
        Add-Content -Path $FilePath -Value $fixtext
        Add-Content -Path $FilePath -Value "`r`n"
        Add-Content -Path $FilePath -Value "`r`n"
    }
}
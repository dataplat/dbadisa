Function Test-ExportDirectory ($Path) {
    if (-not (Test-Path -Path $Path)) {
        $null = New-Item -ItemType Directory -Path $Path
    } else {
        if ((Get-Item $Path -ErrorAction Ignore) -isnot [System.IO.DirectoryInfo]) {
            Stop-PSFFunction -Message "Path ($Path) must be a directory"
            return
        }
    }
}
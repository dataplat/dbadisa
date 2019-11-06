<img align="left" src=https://user-images.githubusercontent.com/8278033/68294422-6ea7c200-0090-11ea-851d-bbaf10dc4d96.png alt="dbadisa logo">

# dbadisa
DISA STIG automation module for SQL Server

## Install

```powershell
Install-Module dbadisa -Scope CurrentUser
```

## Examples - Install-DbsAudit

```powershell
# Detect version and create appropriate audit from DISA, output to DATA\Stig\, shutdown on failulre
Install-DbsAudit -SqlInstance sql2017, sql2016, sql2012

# Detect version and create appropriate audit from DISA, output to C:\temp, continue on failulre
Install-DbsAudit -SqlInstance sql2017 -Path C:\temp -OnFaiure Continue

## Examples - Set-DbsAcl

```powershell
# Download KB4057119 to the current directory. This works for SQL Server or any other KB.
Save-dbadisa -Name KB4057119

# Download the selected x64 files from KB4057119 to the current directory.
Get-dbadisa -Name 3118347 -Simple -Architecture x64 | Out-GridView -Passthru | Save-dbadisa

# Download KB4057119 and the x64 version of KB4057114 to C:\temp.
Save-dbadisa -Name KB4057119, 4057114 -Architecture x64 -Path C:\temp
```

## More Help

Get more help

```powershell
Get-Help Install-DbsAudit -Detailed
```
## Dependencies

- dbatools - For working with SQL
- dbachecks - For checking your work
- PSFramework - For PowerShell goodness
- Pester - Included in dbachecks
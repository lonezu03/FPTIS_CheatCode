param(
    [Parameter(Mandatory = $true)][string]$DatabaseHost,
    [Parameter(Mandatory = $true)][int]$DatabasePort,
    [Parameter(Mandatory = $true)][string]$DatabaseName,
    [Parameter(Mandatory = $true)][string]$DatabaseUser,
    [string]$OutputDirectory = ".\backups"
)

$ErrorActionPreference = "Stop"
if ([string]::IsNullOrWhiteSpace($env:PGPASSWORD)) {
    throw "Set PGPASSWORD in the current terminal before running this script."
}
if (-not (Get-Command pg_dump -ErrorAction SilentlyContinue)) {
    throw "pg_dump is not installed or is missing from PATH."
}

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Force -Path $resolvedOutput | Out-Null
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupFile = Join-Path $resolvedOutput "fittrack-$timestamp.dump"

& pg_dump `
    --host=$DatabaseHost `
    --port=$DatabasePort `
    --username=$DatabaseUser `
    --dbname=$DatabaseName `
    --format=custom `
    --no-owner `
    --no-privileges `
    --file=$backupFile

if ($LASTEXITCODE -ne 0 -or -not (Test-Path -LiteralPath $backupFile)) {
    throw "PostgreSQL backup failed."
}

& pg_restore --list $backupFile | Out-Null
if ($LASTEXITCODE -ne 0) {
    throw "The backup file was created but pg_restore could not read it."
}

Write-Output $backupFile

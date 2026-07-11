param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$diagnosticDirectory = Join-Path $projectRoot "build/test-logs"
$localizationLogPath = Join-Path $diagnosticDirectory "localization-validation.log"

New-Item -ItemType Directory -Path $diagnosticDirectory -Force | Out-Null

Write-Host ""
Write-Host "=== Export output directory safety ==="
& (Join-Path $PSScriptRoot "test_output_directory_safety.ps1")

Write-Host ""
Write-Host "=== Localization contract ==="
try {
    $localizationOutput = @(& (Join-Path $PSScriptRoot "validate_localization.ps1") 2>&1)
    foreach ($line in $localizationOutput) {
        Write-Host ([string]$line)
    }
    Set-Content -LiteralPath $localizationLogPath -Value @(
        $localizationOutput | ForEach-Object { [string]$_ }
    ) -Encoding utf8
}
catch {
    $failureText = $_ | Out-String
    $capturedOutput = @()
    if (Test-Path variable:localizationOutput) {
        $capturedOutput = @($localizationOutput | ForEach-Object { [string]$_ })
        foreach ($line in $capturedOutput) {
            Write-Host $line
        }
    }
    Set-Content -LiteralPath $localizationLogPath -Value (
        $capturedOutput + @("", $failureText)
    ) -Encoding utf8
    Write-Host $failureText
    throw
}

& (Join-Path $PSScriptRoot "run_tests.ps1") -GodotBinary $GodotBinary

Write-Host ""
Write-Host "Project verification completed successfully."

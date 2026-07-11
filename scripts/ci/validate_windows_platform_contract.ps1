Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_platform_contract.ps1")

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$contractFailures = @(Get-WindowsPlatformContractFailures `
    -ProjectPath (Join-Path $projectRoot "project.godot") `
    -ExportPresetsPath (Join-Path $projectRoot "export_presets.cfg") `
    -WorkflowPath (Join-Path $projectRoot ".github/workflows/windows-tests.yml"))

if ($contractFailures.Count -gt 0) {
    Write-Host "Windows platform contract validation failed:"
    foreach ($failure in $contractFailures) {
        Write-Host "  - $failure"
    }
    throw "Windows platform contract validation failed with $($contractFailures.Count) issue(s)."
}

Write-Host "Windows platform contract validation passed."

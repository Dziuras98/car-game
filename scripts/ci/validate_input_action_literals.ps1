Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "input_action_literal_validation.ps1")

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$failures = @(Get-InputActionLiteralFailures `
    -ProjectRoot $projectRoot `
    -ScriptsRoot (Join-Path $projectRoot "scripts") `
    -ExcludedRelativePaths @("scripts/input/game_input_actions.gd") `
    -ExcludedPathPrefixes @("scripts/tests/")
)

if ($failures.Count -gt 0) {
    Write-Host "Input action literal validation failed:"
    foreach ($failure in $failures) {
        Write-Host "  - $failure"
    }
    throw "Input action literal validation failed with $($failures.Count) issue(s)."
}

Write-Host "Input action literal validation passed."

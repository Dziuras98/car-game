Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "test_script_ownership.ps1")

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$ownershipFailures = @(Get-TestScriptOwnershipFailures `
    -ProjectRoot $projectRoot `
    -SceneTestRoot (Join-Path $projectRoot "scenes/tests") `
    -TestScriptRoot (Join-Path $projectRoot "scripts/tests") `
    -AllowedHelpers @(
        "scripts/tests/game_test_adapter.gd"
    )
)

if ($ownershipFailures.Count -gt 0) {
    Write-Output "Recursive test script ownership validation failed:"
    foreach ($failure in $ownershipFailures) {
        Write-Output "  - $failure"
    }
    throw "Recursive test script ownership validation found $($ownershipFailures.Count) issue(s)."
}

Write-Output "Recursive test script ownership validation passed."

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "test_script_ownership.ps1")

$checks = 0
$failures = [System.Collections.Generic.List[string]]::new()

function Expect-Equal {
    param(
        [AllowNull()]$Actual,
        [AllowNull()]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks += 1
    if ($Actual -ne $Expected) {
        $script:failures.Add("$Message Expected '$Expected', received '$Actual'.")
    }
}

function Expect-Contains {
    param(
        [Parameter(Mandatory = $true)][string[]]$Values,
        [Parameter(Mandatory = $true)][string]$Fragment,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks += 1
    $matched = $false
    foreach ($value in $Values) {
        if ($value.Contains($Fragment)) {
            $matched = $true
            break
        }
    }
    if (-not $matched) {
        $script:failures.Add("$Message Missing fragment: $Fragment")
    }
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$staticChecksPath = Join-Path $projectRoot "scripts/ci/run_static_checks.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-test-ownership-" + [guid]::NewGuid().ToString("N"))
$sceneRoot = Join-Path $tempRoot "scenes/tests"
$scriptRoot = Join-Path $tempRoot "scripts/tests"
$nestedSceneDirectory = Join-Path $sceneRoot "nested/deeper"
$nestedScriptDirectory = Join-Path $scriptRoot "nested/deeper"
$helperDirectory = Join-Path $scriptRoot "helpers"
$scenePath = Join-Path $nestedSceneDirectory "fixture.tscn"
$referencedScriptPath = Join-Path $nestedScriptDirectory "referenced.gd"
$orphanScriptPath = Join-Path $nestedScriptDirectory "orphan.gd"

try {
    New-Item -ItemType Directory -Path $nestedSceneDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $nestedScriptDirectory -Force | Out-Null
    New-Item -ItemType Directory -Path $helperDirectory -Force | Out-Null

    Set-Content -LiteralPath $scenePath -Value @'
[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://scripts/tests/nested/deeper/referenced.gd" id="1"]

[node name="NestedOwnershipFixture" type="Node"]
script = ExtResource("1")
'@ -Encoding utf8
    Set-Content -LiteralPath $referencedScriptPath -Value "extends Node" -Encoding utf8
    Set-Content -LiteralPath $orphanScriptPath -Value "extends Node" -Encoding utf8
    Set-Content -LiteralPath (Join-Path $nestedScriptDirectory "standalone.gd") -Value "extends SceneTree" -Encoding utf8
    Set-Content -LiteralPath (Join-Path $nestedScriptDirectory "editor_launcher.gd") -Value "extends EditorScript" -Encoding utf8
    Set-Content -LiteralPath (Join-Path $helperDirectory "allowed_helper.gd") -Value "extends RefCounted" -Encoding utf8

    $ownershipFailures = @(Get-TestScriptOwnershipFailures `
        -ProjectRoot $tempRoot `
        -SceneTestRoot $sceneRoot `
        -TestScriptRoot $scriptRoot `
        -AllowedHelpers @("scripts/tests/helpers/allowed_helper.gd")
    )
    Expect-Equal `
        -Actual $ownershipFailures.Count `
        -Expected 1 `
        -Message "Recursive ownership validation should report only the nested orphan."
    Expect-Contains `
        -Values $ownershipFailures `
        -Fragment "scripts/tests/nested/deeper/orphan.gd" `
        -Message "The nested orphan should be identified by project-relative path."

    Remove-Item -LiteralPath $orphanScriptPath -Force
    $ownershipFailures = @(Get-TestScriptOwnershipFailures `
        -ProjectRoot $tempRoot `
        -SceneTestRoot $sceneRoot `
        -TestScriptRoot $scriptRoot `
        -AllowedHelpers @("scripts/tests/helpers/allowed_helper.gd")
    )
    Expect-Equal `
        -Actual $ownershipFailures.Count `
        -Expected 0 `
        -Message "A nested scene reference should satisfy ownership for its nested script."

    Remove-Item -LiteralPath $scenePath -Force
    $ownershipFailures = @(Get-TestScriptOwnershipFailures `
        -ProjectRoot $tempRoot `
        -SceneTestRoot $sceneRoot `
        -TestScriptRoot $scriptRoot `
        -AllowedHelpers @("scripts/tests/helpers/allowed_helper.gd")
    )
    Expect-Equal `
        -Actual $ownershipFailures.Count `
        -Expected 1 `
        -Message "Removing the nested scene should make its non-standalone script orphaned."
    Expect-Contains `
        -Values $ownershipFailures `
        -Fragment "scripts/tests/nested/deeper/referenced.gd" `
        -Message "The validator should discover nested scene-script ownership changes."

    $staticChecks = Get-Content -LiteralPath $staticChecksPath -Raw
    Expect-Equal `
        -Actual $staticChecks.Contains("function Assert-TestScriptOwnership") `
        -Expected $false `
        -Message "Static checks should not retain a second ownership implementation."
    Expect-Equal `
        -Actual $staticChecks.Contains("Assert-TestScriptOwnership") `
        -Expected $false `
        -Message "Static checks should not invoke the removed shallow ownership check."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[TEST_SCRIPT_OWNERSHIP_TEST][FAIL] $failure"
    }
    throw "Test script ownership validation failed with $($failures.Count) failure(s) across $checks checks."
}

Write-Host "[TEST_SCRIPT_OWNERSHIP_TEST] Passed: $checks checks"

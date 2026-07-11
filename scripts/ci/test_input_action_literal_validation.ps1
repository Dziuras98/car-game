Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "input_action_literal_validation.ps1")

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

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-input-action-literals-" + [guid]::NewGuid().ToString("N"))
$scriptsRoot = Join-Path $tempRoot "scripts"
$runtimeRoot = Join-Path $scriptsRoot "runtime"
$inputRoot = Join-Path $scriptsRoot "input"
$testsRoot = Join-Path $scriptsRoot "tests"
$badRuntimePath = Join-Path $runtimeRoot "bad_input_consumer.gd"

try {
    New-Item -ItemType Directory -Path $runtimeRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $inputRoot -Force | Out-Null
    New-Item -ItemType Directory -Path $testsRoot -Force | Out-Null

    Set-Content -LiteralPath (Join-Path $inputRoot "game_input_actions.gd") -Value @'
extends RefCounted
const PAUSE: StringName = &"pause"
'@ -Encoding utf8
    Set-Content -LiteralPath (Join-Path $testsRoot "raw_input_fixture.gd") -Value @'
extends SceneTree
func _initialize() -> void:
    Input.action_press("accelerate")
'@ -Encoding utf8
    Set-Content -LiteralPath (Join-Path $runtimeRoot "good_input_consumer.gd") -Value @'
extends Node
func poll() -> void:
    Input.is_action_pressed(GameInputActions.PAUSE)
    Input.get_axis(GameInputActions.STEER_LEFT, GameInputActions.STEER_RIGHT)
'@ -Encoding utf8
    Set-Content -LiteralPath $badRuntimePath -Value @'
extends Node
func poll(event: InputEvent) -> void:
    Input.is_action_pressed("pause")
    event.is_action_pressed(&"handbrake")
    Input.get_axis(
        "steer-left",
        "steer-right"
    )
    InputMap.has_action("brake")
'@ -Encoding utf8

    $literalFailures = @(Get-InputActionLiteralFailures `
        -ProjectRoot $tempRoot `
        -ScriptsRoot $scriptsRoot `
        -ExcludedRelativePaths @("scripts/input/game_input_actions.gd") `
        -ExcludedPathPrefixes @("scripts/tests/")
    )

    Expect-Equal `
        -Actual $literalFailures.Count `
        -Expected 5 `
        -Message "The validator should report every raw runtime action literal and ignore exclusions."
    foreach ($expectedAction in @("pause", "handbrake", "steer-left", "steer-right", "brake")) {
        Expect-Contains `
            -Values $literalFailures `
            -Fragment "'$expectedAction'" `
            -Message "The validator should identify the raw '$expectedAction' action."
    }
    Expect-Contains `
        -Values $literalFailures `
        -Fragment "scripts/runtime/bad_input_consumer.gd:" `
        -Message "Failures should include a project-relative path and line number."

    Remove-Item -LiteralPath $badRuntimePath -Force
    $literalFailures = @(Get-InputActionLiteralFailures `
        -ProjectRoot $tempRoot `
        -ScriptsRoot $scriptsRoot `
        -ExcludedRelativePaths @("scripts/input/game_input_actions.gd") `
        -ExcludedPathPrefixes @("scripts/tests/")
    )
    Expect-Equal `
        -Actual $literalFailures.Count `
        -Expected 0 `
        -Message "Only constants and explicitly excluded fixture paths should pass."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[INPUT_ACTION_LITERAL_TEST][FAIL] $failure"
    }
    throw "Input action literal validation failed with $($failures.Count) failure(s) across $checks checks."
}

Write-Host "[INPUT_ACTION_LITERAL_TEST] Passed: $checks checks"

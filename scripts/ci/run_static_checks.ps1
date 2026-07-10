Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$runnerPath = Join-Path $projectRoot "scripts/ci/run_tests.ps1"
$exportPresetPath = Join-Path $projectRoot "export_presets.cfg"
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory = $true)][string]$Message)
    $failures.Add($Message)
}

function Read-Text {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    $path = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Add-Failure "Required file is missing: $RelativePath"
        return ""
    }
    return Get-Content -LiteralPath $path -Raw
}

function Assert-DoesNotContain {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string[]]$ForbiddenFragments
    )
    $content = Read-Text $RelativePath
    foreach ($fragment in $ForbiddenFragments) {
        if ($content.Contains($fragment)) {
            Add-Failure "$RelativePath contains forbidden fragment: $fragment"
        }
    }
}

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string[]]$RequiredFragments
    )
    $content = Read-Text $RelativePath
    foreach ($fragment in $RequiredFragments) {
        if (-not $content.Contains($fragment)) {
            Add-Failure "$RelativePath is missing required fragment: $fragment"
        }
    }
}

Assert-DoesNotContain "scripts/ui/mobile_drive_controls.gd" @(
    "Input.action_press",
    "Input.action_release"
)
Assert-DoesNotContain "scripts/game/game_manager.gd" @(
    "available_cars",
    ".has_method(",
    ".call("
)
Assert-DoesNotContain "scripts/game/race_session_controller.gd" @(
    ".has_method(",
    ".call("
)
Assert-DoesNotContain "scripts/race/lap_tracker.gd" @(
    ".has_method(",
    ".call("
)
Assert-Contains "scripts/car/car_specs.gd" @(
    "enum TransmissionType",
    "func validate() -> PackedStringArray"
)
Assert-DoesNotContain "resources/cars/nissan/370z/specs/370z_6mt_specs.tres" @(
    "acceleration =",
    "manual_transmission_enabled =",
    "automatic_transmission_enabled ="
)
Assert-DoesNotContain "resources/cars/nissan/370z/specs/370z_7at_specs.tres" @(
    "acceleration =",
    "manual_transmission_enabled =",
    "automatic_transmission_enabled ="
)
Assert-DoesNotContain "resources/cars/nissan/370z/variants/370z_6mt.tres" @(
    "mass_kg =",
    "transmission_label ="
)
Assert-DoesNotContain "resources/cars/nissan/370z/variants/370z_7at.tres" @(
    "mass_kg =",
    "transmission_label ="
)
Assert-Contains "export_presets.cfg" @(
    "name=\"Windows Desktop\"",
    "name=\"Windows Desktop Tests\""
)

$runnerContent = Read-Text "scripts/ci/run_tests.ps1"
$sceneTestDirectory = Join-Path $projectRoot "scenes/tests"
if (Test-Path -LiteralPath $sceneTestDirectory -PathType Container) {
    $excludedSceneTests = @(
        "exported_build_smoke_test.tscn"
    )
    foreach ($sceneFile in Get-ChildItem -LiteralPath $sceneTestDirectory -Filter "*.tscn" -File) {
        if ($excludedSceneTests -contains $sceneFile.Name) {
            continue
        }
        $relativePath = "scenes/tests/$($sceneFile.Name)"
        if (-not $runnerContent.Contains($relativePath)) {
            Add-Failure "Scene test is not registered in run_tests.ps1: $relativePath"
        }
    }
}

$scriptTestDirectory = Join-Path $projectRoot "scripts/tests"
if (Test-Path -LiteralPath $scriptTestDirectory -PathType Container) {
    $sceneScriptReferences = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($sceneFile in Get-ChildItem -LiteralPath $sceneTestDirectory -Filter "*.tscn" -File) {
        $sceneContent = Get-Content -LiteralPath $sceneFile.FullName -Raw
        foreach ($match in [regex]::Matches($sceneContent, 'res://(scripts/tests/[^\"\s]+\.gd)')) {
            [void]$sceneScriptReferences.Add($match.Groups[1].Value.Replace('\', '/'))
        }
    }

    $excludedScriptTests = @(
        "scripts/tests/exported_build_smoke_test.gd",
        "scripts/tests/full_program_smoke_test.gd",
        "scripts/tests/game_test_adapter.gd",
        "scripts/tests/run_full_program_smoke_test.gd"
    )
    foreach ($scriptFile in Get-ChildItem -LiteralPath $scriptTestDirectory -Filter "*.gd" -File) {
        $relativePath = "scripts/tests/$($scriptFile.Name)"
        if ($excludedScriptTests -contains $relativePath) {
            continue
        }
        if (-not $runnerContent.Contains($relativePath) -and -not $sceneScriptReferences.Contains($relativePath)) {
            Add-Failure "Test script is neither registered directly nor referenced by a registered scene: $relativePath"
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Host "Static repository checks failed:"
    foreach ($failure in $failures) {
        Write-Host "  - $failure"
    }
    throw "Static repository checks failed with $($failures.Count) issue(s)."
}

Write-Host "Static repository checks passed."

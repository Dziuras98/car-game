Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
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
    "transmission_type",
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

Assert-Contains "scripts/track/track_generation_config.gd" @(
    "class_name TrackGenerationConfig",
    "static func from_layout"
)
Assert-Contains "scripts/track/track_generated_meshes.gd" @(
    "class_name TrackGeneratedMeshes"
)
foreach ($typedBuilderPath in @(
    "scripts/track/track_layout_builder.gd",
    "scripts/track/track_surface_mesh_builder.gd",
    "scripts/track/track_collision_builder.gd",
    "scripts/track/track_marker_builder.gd",
    "scripts/track/track_barrier_builder.gd",
    "scripts/track/track_decoration_builder.gd",
    "scripts/race/generated_track.gd"
)) {
    Assert-DoesNotContain $typedBuilderPath @(
        "config: Dictionary",
        "_config: Dictionary",
        "var config: Dictionary",
        "surface_meshes: Dictionary"
    )
}
Assert-Contains "scripts/track/track_surface_mesh_builder.gd" @(
    ") -> TrackGeneratedMeshes:"
)

Assert-Contains "export_presets.cfg" @(
    'name="Windows Desktop"',
    'name="Windows Test"',
    'name="Android"',
    'platform="Android"',
    'package/unique_name="com.dziuras98.cargame"'
)
Assert-Contains "scripts/ci/export_android.sh" @(
    '--export-debug "Android"',
    "com.dziuras98.cargame"
)
Assert-Contains "scripts/ci/run_tests.ps1" @(
    "run_static_checks.ps1",
    "Get-ChildItem",
    "extends\s+SceneTree"
)

if ($failures.Count -gt 0) {
    Write-Host "Static repository checks failed:"
    foreach ($failure in $failures) {
        Write-Host "  - $failure"
    }
    throw "Static repository checks failed with $($failures.Count) issue(s)."
}

Write-Host "Static repository checks passed."

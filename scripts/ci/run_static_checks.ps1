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

function Get-ProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$FullPath)
    return [System.IO.Path]::GetRelativePath($projectRoot, $FullPath).Replace('\', '/')
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

function Assert-DoesNotMatch {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string[]]$ForbiddenPatterns
    )
    $content = Read-Text $RelativePath
    foreach ($pattern in $ForbiddenPatterns) {
        if ($content -match $pattern) {
            Add-Failure "$RelativePath matches forbidden pattern: $pattern"
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

function Assert-TestScriptOwnership {
    $referencedScripts = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    $sceneTestRoot = Join-Path $projectRoot "scenes/tests"
    foreach ($sceneFile in Get-ChildItem -LiteralPath $sceneTestRoot -Filter "*.tscn" -File) {
        $sceneContent = Get-Content -LiteralPath $sceneFile.FullName -Raw
        foreach ($match in [regex]::Matches($sceneContent, 'res://scripts/tests/([^"\r\n]+\.gd)')) {
            [void]$referencedScripts.Add("scripts/tests/$($match.Groups[1].Value)")
        }
    }

    $allowedHelpers = @(
        "scripts/tests/game_test_adapter.gd"
    )
    $testScriptRoot = Join-Path $projectRoot "scripts/tests"
    foreach ($scriptFile in Get-ChildItem -LiteralPath $testScriptRoot -Filter "*.gd" -File) {
        $relativePath = Get-ProjectRelativePath -FullPath $scriptFile.FullName
        $content = Get-Content -LiteralPath $scriptFile.FullName -Raw
        $isStandaloneTest = $content -match '(?m)^\s*extends\s+SceneTree\s*$'
        $isEditorLauncher = $content -match '(?m)^\s*extends\s+EditorScript\s*$'
        $isKnownHelper = $allowedHelpers -contains $relativePath
        $isSceneTest = $referencedScripts.Contains($relativePath)
        if (-not ($isStandaloneTest -or $isEditorLauncher -or $isKnownHelper -or $isSceneTest)) {
            Add-Failure "Test script is not discoverable, scene-referenced or an allowed helper: $relativePath"
        }
    }
}

function Assert-NoProductionTestOnlyIdentifiers {
    $scriptsRoot = Join-Path $projectRoot "scripts"
    foreach ($scriptFile in Get-ChildItem -LiteralPath $scriptsRoot -Filter "*.gd" -File -Recurse) {
        $relativePath = Get-ProjectRelativePath -FullPath $scriptFile.FullName
        if ($relativePath.StartsWith("scripts/tests/", [System.StringComparison]::OrdinalIgnoreCase)) {
            continue
        }
        $content = Get-Content -LiteralPath $scriptFile.FullName -Raw
        if ($content.Contains("_for_test")) {
            Add-Failure "Production script contains a test-only identifier suffix: $relativePath"
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
    ".call(",
    "func get_moving_opponent_count(",
    "func request_return_to_main_menu(",
    "func simulate_current_player_finish(",
    "func is_child_visible("
)
Assert-DoesNotContain "scripts/game/race_session_controller.gd" @(
    ".has_method(",
    ".call(",
    "func get_moving_opponent_count(",
    "func simulate_current_player_finish("
)
Assert-DoesNotContain "scripts/race/lap_tracker.gd" @(
    ".has_method(",
    ".call("
)
Assert-DoesNotContain "scripts/race/ai_race_driver.gd" @(
    ".has_method(",
    ".has_signal(",
    ".call("
)

Assert-Contains "scripts/car/car_specs.gd" @(
    "enum TransmissionType",
    "transmission_type",
    "func validate() -> PackedStringArray"
)
Assert-DoesNotContain "scripts/car/car_specs.gd" @(
    "var acceleration:",
    "manual_transmission_enabled",
    "automatic_transmission_enabled"
)
Assert-DoesNotContain "scripts/car/car_drive_config.gd" @(
    "DUPLICATE_SKIP_PROPERTIES",
    "manual_transmission_enabled",
    "automatic_transmission_enabled"
)
Assert-DoesNotContain "scripts/car/car_drive_config_builder.gd" @(
    '&"acceleration"',
    '&"manual_transmission_enabled"',
    '&"automatic_transmission_enabled"'
)
Assert-DoesNotContain "scripts/car/car_controller.gd" @(
    "REMOVED_LEGACY_TUNING_PROPERTIES",
    "func _set("
)
Assert-DoesNotMatch "scenes/cars/370z.tscn" @(
    '(?m)^\s*(acceleration|brake_deceleration|reverse_acceleration|coast_deceleration|handbrake_deceleration|max_forward_speed|max_reverse_speed|steering_speed|wheel_base|max_steering_angle_degrees|idle_rpm|peak_torque_rpm|redline_rpm|rev_limiter_rpm|low_rpm_torque_multiplier|mid_rpm_torque_multiplier|redline_torque_multiplier|engine_force|engine_brake_force|rpm_response|manual_transmission_enabled|automatic_transmission_enabled|gear_ratios|reverse_gear_ratio|final_drive_ratio|peak_engine_torque|wheel_radius|drivetrain_efficiency|shift_delay|automatic_upshift_rpm|automatic_downshift_rpm|automatic_kickdown_throttle|automatic_kickdown_rpm|automatic_shift_delay|torque_converter_stall_rpm|torque_converter_coupling_rpm|torque_converter_stall_torque_multiplier|vehicle_mass|drag_coefficient|frontal_area|air_density|rolling_resistance_coefficient|lateral_grip|handbrake_lateral_grip_multiplier|steering_slip_gain|slip_speed_threshold|slip_steering_lock_threshold|slip_steering_same_direction_multiplier|skid_mark_min_slip|skid_mark_interval|skid_mark_lifetime|skid_mark_width|skid_mark_length|gravity|floor_stick_force)\s*='
)
Assert-Contains "scripts/car/car_catalog.gd" @(
    "@export var models: Array[CarModelDefinition]"
)
Assert-Contains "scripts/car/car_model_definition.gd" @(
    "@export var variants: Array[CarVariantDefinition]"
)
Assert-DoesNotContain "scripts/car/car_catalog.gd" @(
    "Array[Resource]"
)
Assert-DoesNotContain "scripts/car/car_model_definition.gd" @(
    "Array[Resource]"
)
foreach ($specPath in @(
    "resources/cars/nissan/370z/specs/370z_6mt_specs.tres",
    "resources/cars/nissan/370z/specs/370z_7at_specs.tres"
)) {
    Assert-DoesNotMatch $specPath @(
        '(?m)^\s*acceleration\s*=',
        '(?m)^\s*manual_transmission_enabled\s*=',
        '(?m)^\s*automatic_transmission_enabled\s*='
    )
}
Assert-DoesNotMatch "resources/cars/nissan/370z/variants/370z_6mt.tres" @(
    '(?m)^\s*mass_kg\s*=',
    '(?m)^\s*transmission_label\s*='
)
Assert-DoesNotMatch "resources/cars/nissan/370z/variants/370z_7at.tres" @(
    '(?m)^\s*mass_kg\s*=',
    '(?m)^\s*transmission_label\s*='
)

Assert-Contains "scripts/track/track_catalog.gd" @(
    "@export var tracks: Array[TrackDefinition]",
    "@export var default_track_id",
    "catalog must define default_track_id"
)
Assert-DoesNotContain "scripts/track/track_catalog.gd" @(
    "Array[Resource]",
    "legacy_default",
    ".is_default",
    "return definitions[0]"
)
Assert-DoesNotContain "scripts/track/track_definition.gd" @(
    "is_default"
)
Assert-DoesNotMatch "resources/tracks/simple_oval_definition.tres" @(
    '(?m)^\s*is_default\s*='
)
Assert-Contains "resources/tracks/catalog.tres" @(
    'default_track_id = &"simple_oval"'
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

Assert-Contains "project.godot" @(
    "textures/vram_compression/import_etc2_astc=true"
)
Assert-Contains "export_presets.cfg" @(
    'name="Windows Desktop"',
    'name="Windows Test"',
    'name="Android"',
    'platform="Android"',
    'texture_format/etc2_astc=true',
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
Assert-Contains "scenes/tests/full_program_smoke_test.tscn" @(
    'path="res://scripts/tests/full_program_smoke_test.gd"'
)
Assert-DoesNotContain "scenes/tests/full_program_smoke_test.tscn" @(
    "full_program_smoke_test_v2.gd"
)
Assert-TestScriptOwnership
Assert-NoProductionTestOnlyIdentifiers

if ($failures.Count -gt 0) {
    $details = $failures -join [Environment]::NewLine
    Write-Output "Static repository checks failed:"
    foreach ($failure in $failures) {
        Write-Output "  - $failure"
    }
    throw "Static repository checks failed with $($failures.Count) issue(s):$([Environment]::NewLine)$details"
}

Write-Output "Static repository checks passed."

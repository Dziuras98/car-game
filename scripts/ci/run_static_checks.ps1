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


function Assert-PathDoesNotExist {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    $path = Join-Path $projectRoot $RelativePath
    if (Test-Path -LiteralPath $path) {
        Add-Failure "Obsolete repository path still exists: $RelativePath"
    }
}

function Assert-GDScriptClassName {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string]$ClassName
    )
    $content = Read-Text $RelativePath
    $pattern = '(?m)^\s*class_name\s+' + [regex]::Escape($ClassName) + '\s*$'
    if ($content -notmatch $pattern) {
        Add-Failure "$RelativePath must declare class_name $ClassName."
    }
}

function Assert-GDScriptFunctions {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string[]]$FunctionNames
    )
    $content = Read-Text $RelativePath
    foreach ($functionName in $FunctionNames) {
        $pattern = '(?m)^\s*(?:static\s+)?func\s+' + [regex]::Escape($functionName) + '\s*\('
        if ($content -notmatch $pattern) {
            Add-Failure "$RelativePath must declare function $functionName."
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

# High-level orchestration may not regain reflective fallback paths, duplicated mode literals or detailed startup sequencing.
Assert-DoesNotContain "scripts/game/game_manager.gd" @(
    "available_cars",
    ".has_method(",
    ".call(",
    "func get_moving_opponent_count(",
    "func request_return_to_main_menu(",
    "func simulate_current_player_finish(",
    "func is_child_visible(",
    '"free_drive"',
    '"race"',
    "track_catalog.get_track_by_id(",
    "_session_state.begin_start(",
    "_session_state.commit("
)
Assert-GDScriptFunctions "scripts/game/game_manager.gd" @(
    "is_supported_mode_id",
    "get_session_phase",
    "_stage_track",
    "_commit_staged_track",
    "_finalize_staged_track_commit",
    "_configure_session_start_transaction",
    "_on_menu_selection_completed",
    "_handle_session_start_failure",
    "_clear_runtime_state",
    "_reset_session_start_runtime",
    "_clear_active_session",
    "_reset_to_main_menu",
    "_return_to_main_menu",
    "_on_session_phase_changed"
)
Assert-Contains "scripts/game/game_manager.gd" @(
    "signal session_phase_changed",
    "var _session_state: GameSessionState = GameSessionState.new()",
    "var _session_start_transaction: GameSessionStartTransaction",
    "car_catalog.validate()",
    'Callable(self, "_reset_session_start_runtime")',
    'Callable(self, "_stage_track")',
    'Callable(self, "_commit_staged_track")',
    'Callable(self, "_finalize_staged_track_commit")'
)
Assert-DoesNotContain "scripts/ui/main_menu.gd" @('"free_drive"', '"race"', "str(track_option.track_id)")
Assert-Contains "scripts/ui/main_menu.gd" @(
    "signal selection_completed(mode_id: StringName, track_id: StringName, car_variant_id: StringName)",
    "var _selected_mode_id: StringName",
    "var _selected_track_id: StringName"
)

Assert-GDScriptClassName "scripts/game/game_modes.gd" "GameModes"
Assert-GDScriptFunctions "scripts/game/game_modes.gd" @("is_supported")
Assert-Contains "scripts/game/game_modes.gd" @(
    'const FREE_DRIVE: StringName = &"free_drive"',
    'const RACE: StringName = &"race"',
    "const ALL: Array[StringName]"
)

Assert-GDScriptClassName "scripts/game/game_session_state.gd" "GameSessionState"
Assert-GDScriptFunctions "scripts/game/game_session_state.gd" @(
    "is_success",
    "begin_start",
    "commit",
    "update_free_drive_car_variant",
    "reset",
    "get_phase",
    "is_free_drive",
    "is_race"
)
Assert-Contains "scripts/game/game_session_state.gd" @(
    "signal phase_changed",
    "enum Result",
    "var _mode_id: StringName",
    "var _track_id: StringName"
)
Assert-DoesNotContain "scripts/game/game_session_state.gd" @('"free_drive"', '"race"')

Assert-GDScriptClassName "scripts/game/game_session_start_transaction.gd" "GameSessionStartTransaction"
Assert-GDScriptFunctions "scripts/game/game_session_start_transaction.gd" @(
    "configure",
    "execute",
    "get_failure_message",
    "_fail"
)
Assert-Contains "scripts/game/game_session_start_transaction.gd" @(
    "_session_state.begin_start()",
    "_reset_runtime.call()",
    "_stage_track.call(selected_track)",
    "_configure_runtime.call()",
    "_spawn_player.call(selected_car_index, spawn_global_transform)",
    "_commit_track.call()",
    "_session_state.commit(",
    "_finalize_track_commit.call()"
)
Assert-DoesNotContain "scripts/game/game_session_start_transaction.gd" @(
    "return _fail(Result.UNSUPPORTED_MODE)",
    "return _fail(Result.UNAVAILABLE_CAR_VARIANT)",
    "return _fail(Result.UNAVAILABLE_TRACK)",
    "_activate_track.call(selected_track)"
)

Assert-GDScriptClassName "scripts/game/track_spawn_controller.gd" "TrackSpawnController"
Assert-GDScriptFunctions "scripts/game/track_spawn_controller.gd" @(
    "stage_track",
    "commit_staged_track",
    "finalize_track_commit",
    "rollback_track_transaction",
    "discard_staged_track",
    "spawn_track"
)
Assert-Contains "scripts/game/track_spawn_controller.gd" @(
    "var _staged_track: GeneratedTrack",
    "var _previous_track: GeneratedTrack",
    "var _has_unfinalized_commit: bool",
    "pending_track.name = PENDING_TRACK_NAME"
)

Assert-DoesNotContain "scripts/game/race_session_controller.gd" @(
    ".has_method(",
    ".call(",
    "func get_moving_opponent_count(",
    "func simulate_current_player_finish(",
    "OPPONENT_NODE_PREFIX",
    "trim_prefix(",
    "str(car.name)"
)
Assert-GDScriptFunctions "scripts/game/race_session_controller.gd" @(
    "start_race",
    "get_participants",
    "_build_participants",
    "_reset_runtime_state",
    "_abort_race_start"
)
Assert-GDScriptClassName "scripts/race/race_participant.gd" "RaceParticipant"
Assert-GDScriptFunctions "scripts/race/race_participant.gd" @(
    "create_player",
    "create_opponent",
    "is_valid",
    "get_display_label"
)
Assert-Contains "scripts/race/race_participant.gd" @("participant_id: StringName", "enum Kind")
Assert-DoesNotContain "scripts/race/lap_tracker.gd" @(".has_method(", ".call(")
Assert-DoesNotContain "scripts/race/ai_race_driver.gd" @(".has_method(", ".has_signal(", ".call(")
Assert-GDScriptFunctions "scripts/race/ai_race_driver.gd" @(
    "_update_manual_transmission",
    "_request_manual_gear",
    "_set_reverse_recovery_inputs",
    "_set_return_to_forward_inputs"
)
Assert-DoesNotContain "scripts/game/player_car_spawn_controller.gd" @("clampi(car_index")
Assert-GDScriptFunctions "scripts/game/opponent_participant_spawner.gd" @("spawn_opponents", "clear_opponents")
Assert-GDScriptFunctions "scripts/game/car_instance_factory.gd" @("has_ai_eligible_cars")
Assert-DoesNotContain "scripts/game/car_instance_factory.gd" @("automatic_variants", "source = _available_variants")

# Detailed wheel animation is model-specific; generic name scanning must not return.
Assert-DoesNotContain "scripts/car/car_visual_controller.gd" @(
    "legacy_detailed",
    "_collect_legacy_detailed_wheel_nodes",
    '"wheel" in normalized_name',
    '"tire" in normalized_name',
    '"tyre" in normalized_name',
    '"rim" in normalized_name'
)
Assert-GDScriptClassName "scripts/car/standard_370z_visual_controller.gd" "Standard370ZVisualController"
Assert-GDScriptClassName "scripts/car/nismo_370z_visual_controller.gd" "Nismo370ZVisualController"
Assert-Contains "scenes/cars/370z_nismo_visuals.tscn" @("res://scripts/car/nismo_370z_visual_controller.gd")
Assert-Contains "scenes/cars/370z_nismo_ai_visuals.tscn" @("res://scripts/car/nismo_370z_visual_controller.gd")

# Vehicle configuration remains resource-driven and ground-contact processing remains allocation-aware.
Assert-GDScriptFunctions "scripts/car/car_specs.gd" @("validate")
Assert-Contains "scripts/car/car_specs.gd" @("enum TransmissionType", "transmission_type")
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
    "func _set(",
    "func _apply_car_specs("
)
Assert-GDScriptFunctions "scripts/car/car_controller.gd" @(
    "is_manual_transmission",
    "get_forward_gear_count",
    "is_shift_in_progress",
    "request_external_gear_up",
    "request_external_gear_down",
    "clear_external_gear_requests"
)
Assert-GDScriptFunctions "scripts/car/car_input.gd" @(
    "request_external_gear_up",
    "request_external_gear_down",
    "clear_external_gear_requests"
)
Assert-Contains "scripts/car/car_chassis_controller.gd" @(
    "var _probe_local_positions: Array[Vector3]",
    "for wheel_index: int in range(mini(_probe_local_positions.size(), state.wheel_states.size()))",
    "state.wheel_states[wheel_index].set_contact(",
    "state.update_contact_aggregates()",
    "suspension_acceleration_vector"
)
Assert-DoesNotContain "scripts/car/car_chassis_controller.gd" @(
    "var normals: Array[Vector3]",
    "var grip_values: Array[float]"
)
Assert-DoesNotMatch "scenes/cars/370z.tscn" @(
    '(?m)^\s*(acceleration|brake_deceleration|reverse_acceleration|coast_deceleration|handbrake_deceleration|max_forward_speed|max_reverse_speed|steering_speed|wheel_base|max_steering_angle_degrees|idle_rpm|peak_torque_rpm|redline_rpm|rev_limiter_rpm|low_rpm_torque_multiplier|mid_rpm_torque_multiplier|redline_torque_multiplier|engine_force|engine_brake_force|rpm_response|manual_transmission_enabled|automatic_transmission_enabled|gear_ratios|reverse_gear_ratio|final_drive_ratio|peak_engine_torque|wheel_radius|drivetrain_efficiency|shift_delay|automatic_upshift_rpm|automatic_downshift_rpm|automatic_kickdown_throttle|automatic_kickdown_rpm|automatic_shift_delay|torque_converter_stall_rpm|torque_converter_coupling_rpm|torque_converter_stall_torque_multiplier|vehicle_mass|drag_coefficient|frontal_area|air_density|rolling_resistance_coefficient|lateral_grip|handbrake_lateral_grip_multiplier|steering_slip_gain|slip_speed_threshold|slip_steering_lock_threshold|slip_steering_same_direction_multiplier|skid_mark_min_slip|skid_mark_interval|skid_mark_lifetime|skid_mark_width|skid_mark_length|gravity|floor_stick_force)\s*='
)
Assert-DoesNotContain "scripts/car/car_variant_definition.gd" @(
    "var transmission_label:",
    "var mass_kg:",
    "func get_mass_kg("
)
Assert-GDScriptFunctions "scripts/car/car_catalog.gd" @("validate")
Assert-GDScriptFunctions "scripts/car/car_model_definition.gd" @("validate")
Assert-GDScriptFunctions "scripts/car/car_variant_definition.gd" @("validate", "is_ai_eligible_for_race")
Assert-DoesNotContain "scripts/car/car_catalog.gd" @("Array[Resource]")
Assert-DoesNotContain "scripts/car/car_model_definition.gd" @("Array[Resource]")
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
foreach ($variantPath in @(
    "resources/cars/nissan/370z/variants/370z_6mt.tres",
    "resources/cars/nissan/370z/variants/370z_7at.tres",
    "resources/cars/nissan/370z_nismo/variants/370z_nismo_6mt.tres",
    "resources/cars/nissan/370z_nismo/variants/370z_nismo_7at.tres"
)) {
    Assert-DoesNotMatch $variantPath @(
        '(?m)^\s*mass_kg\s*=',
        '(?m)^\s*transmission_label\s*='
    )
    Assert-Contains $variantPath @("ai_eligible = true")
}

# Track ownership remains typed and explicit.
Assert-GDScriptFunctions "scripts/track/track_catalog.gd" @("validate")
Assert-Contains "scripts/track/track_catalog.gd" @("@export var default_track_id")
Assert-DoesNotContain "scripts/track/track_catalog.gd" @(
    "Array[Resource]",
    "legacy_default",
    ".is_default",
    "return definitions[0]"
)
Assert-DoesNotContain "scripts/track/track_definition.gd" @("is_default")
Assert-DoesNotMatch "resources/tracks/simple_oval_definition.tres" @('(?m)^\s*is_default\s*=')
Assert-Contains "resources/tracks/catalog.tres" @('default_track_id = &"simple_oval"')
Assert-GDScriptClassName "scripts/track/track_generation_config.gd" "TrackGenerationConfig"
Assert-GDScriptFunctions "scripts/track/track_generation_config.gd" @("from_layout")
Assert-GDScriptClassName "scripts/track/track_generated_meshes.gd" "TrackGeneratedMeshes"
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

# Historical reports, duplicate source drops and superseded prototype assets stay removed.
foreach ($obsoletePath in @(
    "third_party_sources",
    "docs/test_reports",
    "scenes/cars/player_car.tscn",
    "scenes/cars/test_car.tscn",
    "docs/370z_power_torque_curve.svg",
    "docs/manual_car_power_torque_curve.svg",
    "scripts/tests/legacy_controller_property_access_test.gd",
    ".github/workflows/repository-audit-bundle.yml"
)) {
    Assert-PathDoesNotExist $obsoletePath
}
Assert-DoesNotContain "export_presets.cfg" @("third_party_sources/*")

# CI policy checks focus on immutable dependencies and authoritative entrypoints.
Assert-Contains "scripts/ci/verify_project.ps1" @("validate_localization.ps1", "run_tests.ps1")
Assert-Contains "scripts/ci/run_tests.ps1" @("run_static_checks.ps1", "Get-ChildItem", "extends\s+SceneTree")
Assert-DoesNotMatch ".github/workflows/windows-tests.yml" @('uses:\s+actions/(checkout|cache|upload-artifact)@v\d+')
Assert-Contains ".github/workflows/windows-tests.yml" @(
    "actions/checkout@9c091bb21b7c1c1d1991bb908d89e4e9dddfe3e0",
    "actions/upload-artifact@043fb46d1a93c77aae656e7c1c64a875d1fc6a0a",
    "actions/cache@55cc8345863c7cc4c66a329aec7e433d2d1c52a9",
    "fetch-depth: 0",
    "persist-credentials: false",
    "Get-FileHash -LiteralPath `$archivePath -Algorithm SHA512",
    "github.event_name != 'pull_request'",
    "Upload diagnostics"
)
Assert-Contains ".github/dependabot.yml" @("package-ecosystem: github-actions", "interval: weekly")
Assert-Contains "scenes/tests/full_program_smoke_test.tscn" @('path="res://scripts/tests/full_program_smoke_test.gd"')
Assert-DoesNotContain "scenes/tests/full_program_smoke_test.tscn" @("full_program_smoke_test_v2.gd")
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

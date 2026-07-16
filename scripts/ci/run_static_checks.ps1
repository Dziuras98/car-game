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

function Assert-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string[]]$Fragments
    )
    $content = Read-Text $RelativePath
    foreach ($fragment in $Fragments) {
        if (-not $content.Contains($fragment)) {
            Add-Failure "$RelativePath is missing required fragment: $fragment"
        }
    }
}

function Assert-DoesNotContain {
    param(
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][string[]]$Fragments
    )
    $content = Read-Text $RelativePath
    foreach ($fragment in $Fragments) {
        if ($content.Contains($fragment)) {
            Add-Failure "$RelativePath contains removed functionality: $fragment"
        }
    }
}

Assert-Contains "resources/tracks/catalog.tres" @(
    'infinite_grid_definition.tres',
    'default_track_id = &"infinite_grid"'
)
Assert-DoesNotContain "resources/tracks/catalog.tres" @(
    'simple_oval_definition.tres',
    'tor_poznan_definition.tres',
    'short_desert_track_definition.tres',
    'high_speed_ring_definition.tres'
)

Assert-Contains "scenes/main.tscn" @(
    'res://scenes/tracks/infinite_grid.tscn',
    'grid_path = NodePath("InfiniteGrid")',
    'res://scenes/ui/main_menu.tscn'
)
Assert-DoesNotContain "scenes/main.tscn" @(
    'mode_filtered_main_menu.tscn',
    'TrackContainer',
    'Minimap',
    'race_hud'
)

Assert-Contains "scripts/game/game_manager.gd" @(
    'func is_ready_for_input()',
    '_menu.car_selected.connect(_on_car_selected)',
    'func get_active_track() -> GeneratedTrack:',
    'var _grid: InfiniteGridTrack'
)
Assert-DoesNotContain "scripts/game/game_manager.gd" @(
    'RaceSessionController',
    'RaceHud',
    'GameSessionState',
    'GameSessionStartTransaction',
    'TrackCatalog',
    'opponent_count',
    'race_lap_count',
    '_start_race',
    'Minimap'
)

Assert-Contains "scripts/ui/main_menu.gd" @(
    'signal car_selected(car_variant_id: StringName)',
    'const INFINITE_GRID_ID: StringName = &"infinite_grid"',
    'func _show_car_step()'
)
Assert-DoesNotContain "scripts/ui/main_menu.gd" @(
    'GameModes.RACE',
    'tr("Wyścig")',
    'tr("Wybierz tryb")',
    'tr("Wybierz tor")',
    'CarPreviewRenderer'
)

Assert-Contains "scripts/game/game_modes.gd" @(
    'const ALL: Array[StringName] = [FREE_DRIVE]',
    'return mode_id == FREE_DRIVE'
)
Assert-DoesNotContain "scripts/game/game_modes.gd" @(
    '&"race"'
)

Assert-DoesNotContain "scripts/game/car_spawner.gd" @(
    'OpponentParticipantSpawner.new()',
    'OpponentSpawnLayout.new()',
    'OpponentPaintRandomizer.new()',
    'spawn_opponents(_opponent_count)'
)
Assert-DoesNotContain "scripts/game/car_instance_factory.gd" @(
    '_ai_eligible_variants',
    'get_ai_car_scene()'
)

Assert-Contains "scripts/race/ai_race_driver.gd" @(
    'func is_configured() -> bool:',
    'return false',
    'set_physics_process(false)'
)
Assert-DoesNotContain "scripts/race/ai_race_driver.gd" @(
    'func _physics_process(',
    '_update_stuck_detection',
    '_refresh_points',
    'target_speed_kmh',
    'lookahead_points'
)

Assert-Contains "scripts/game/race_session_controller.gd" @(
    'push_error("Race mode has been removed.")',
    'func start_race(',
    'return false'
)
Assert-DoesNotContain "scripts/game/race_session_controller.gd" @(
    'RaceManager.new()',
    'LapTracker.new()',
    '.spawn_opponents(',
    'update_positions()'
)

Assert-Contains "scripts/track/infinite_grid_track.gd" @(
    'class_name InfiniteGridTrack',
    'WorldBoundaryShape3D',
    'func has_committed_generation() -> bool:'
)

if ($failures.Count -gt 0) {
    Write-Host "Static checks failed:" -ForegroundColor Red
    foreach ($failure in $failures) {
        Write-Host " - $failure" -ForegroundColor Red
    }
    throw "$($failures.Count) static contract check(s) failed."
}

Write-Host "Static checks passed: free drive only, infinite grid only, no active race or AI runtime."

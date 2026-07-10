param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path

if (-not (Test-Path -LiteralPath $GodotBinary -PathType Leaf)) {
    throw "Godot binary was not found: $GodotBinary"
}

function Invoke-GodotCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$CommandArguments
    )

    Write-Host ""
    Write-Host "=== $Name ==="
    Write-Host "Godot arguments: $($CommandArguments -join ' ')"

    & $GodotBinary @CommandArguments
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode."
    }
}

Invoke-GodotCommand -Name "Import project resources" -CommandArguments @(
    "--headless",
    "--path", $projectRoot,
    "--import"
)

$scriptTests = @(
    "scripts/tests/car_controller_runtime_config_test.gd"
)

foreach ($testScript in $scriptTests) {
    Invoke-GodotCommand -Name "Script test: $testScript" -CommandArguments @(
        "--headless",
        "--path", $projectRoot,
        "--script", $testScript
    )
}

$sceneTests = @(
    "scenes/tests/car_catalog_validation_test.tscn",
    "scenes/tests/car_specs_runtime_reconfiguration_test.tscn",
    "scenes/tests/car_powertrain_controller_test.tscn",
    "scenes/tests/car_chassis_motion_test.tscn",
    "scenes/tests/full_program_smoke_test.tscn"
)

foreach ($testScene in $sceneTests) {
    Invoke-GodotCommand -Name "Scene test: $testScene" -CommandArguments @(
        "--headless",
        "--path", $projectRoot,
        $testScene
    )
}

Write-Host ""
Write-Host "All Godot tests passed."

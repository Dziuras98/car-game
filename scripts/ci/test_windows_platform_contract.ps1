Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "windows_platform_contract.ps1")

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
    foreach ($value in $Values) {
        if ($value.Contains($Fragment)) {
            return
        }
    }
    $script:failures.Add("$Message Missing fragment: $Fragment")
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-windows-platform-" + [guid]::NewGuid().ToString("N"))
$projectPath = Join-Path $tempRoot "project.godot"
$exportPresetsPath = Join-Path $tempRoot "export_presets.cfg"
$workflowDirectory = Join-Path $tempRoot ".github/workflows"
$workflowPath = Join-Path $workflowDirectory "windows-tests.yml"

$validProject = @'
config_version=5

[rendering]

rendering_device/driver.windows="d3d12"
'@

$validExportPresets = @'
[preset.0]

name="Windows Desktop"
platform="Windows Desktop"
runnable=true
custom_features=""
export_path="build/windows/car-game.exe"

[preset.0.options]

binary_format/architecture="x86_64"
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false

[preset.1]

name="Windows Test"
platform="Windows Desktop"
runnable=false
custom_features="export_smoke_test"
export_path="build/windows-test/car-game-test.exe"

[preset.1.options]

binary_format/architecture="x86_64"
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
'@

$validWorkflow = @'
name: Windows tests

env:
  GODOT_ARCHIVE: Godot_v4.7-stable_win64.exe.zip
  GODOT_EXECUTABLE: Godot_v4.7-stable_win64_console.exe

jobs:
  tests:
    runs-on: windows-2025
    steps:
      - shell: pwsh
        run: ./scripts/ci/verify_project.ps1 -GodotBinary $env:GODOT_BIN
      - shell: pwsh
        run: |
          $releaseSource = "windows_release_x86_64.exe"
          $debugSource = "windows_debug_x86_64.exe"
      - shell: pwsh
        run: ./scripts/ci/export_windows.ps1 -GodotBinary $env:GODOT_BIN
'@

function Write-ValidFixture {
    New-Item -ItemType Directory -Path $workflowDirectory -Force | Out-Null
    Set-Content -LiteralPath $projectPath -Value $validProject -Encoding utf8
    Set-Content -LiteralPath $exportPresetsPath -Value $validExportPresets -Encoding utf8
    Set-Content -LiteralPath $workflowPath -Value $validWorkflow -Encoding utf8
}

function Get-FixtureFailures {
    return @(Get-WindowsPlatformContractFailures `
        -ProjectPath $projectPath `
        -ExportPresetsPath $exportPresetsPath `
        -WorkflowPath $workflowPath)
}

try {
    Write-ValidFixture
    $contractFailures = @(Get-FixtureFailures)
    Expect-Equal `
        -Actual $contractFailures.Count `
        -Expected 0 `
        -Message "A complete Windows-only fixture should pass."

    Set-Content -LiteralPath $projectPath -Value ($validProject -replace 'd3d12', 'opengl3') -Encoding utf8
    $contractFailures = @(Get-FixtureFailures)
    Expect-Contains `
        -Values $contractFailures `
        -Fragment "D3D12" `
        -Message "The validator should reject a non-D3D12 Windows driver."

    Write-ValidFixture
    Add-Content -LiteralPath $exportPresetsPath -Value @'

[preset.2]
name="Linux/X11"
platform="Linux/BSD"
runnable=false
custom_features=""
export_path="build/linux/car-game.x86_64"

[preset.2.options]
binary_format/architecture="x86_64"
texture_format/s3tc_bptc=true
texture_format/etc2_astc=false
'@ -Encoding utf8
    $contractFailures = @(Get-FixtureFailures)
    Expect-Contains `
        -Values $contractFailures `
        -Fragment "exactly two export presets" `
        -Message "The validator should reject an additional platform preset."
    Expect-Contains `
        -Values $contractFailures `
        -Fragment "Unexpected export preset 'Linux/X11'" `
        -Message "The validator should name an unexpected platform preset."

    Write-ValidFixture
    Set-Content -LiteralPath $exportPresetsPath -Value ($validExportPresets -replace 'binary_format/architecture="x86_64"', 'binary_format/architecture="arm64"') -Encoding utf8
    $contractFailures = @(Get-FixtureFailures)
    Expect-Contains `
        -Values $contractFailures `
        -Fragment "binary_format/architecture='x86_64'" `
        -Message "The validator should reject non-x86_64 Windows exports."

    Write-ValidFixture
    Set-Content -LiteralPath $workflowPath -Value ($validWorkflow -replace 'runs-on: windows-2025', 'runs-on: ubuntu-24.04') -Encoding utf8
    $contractFailures = @(Get-FixtureFailures)
    Expect-Contains `
        -Values $contractFailures `
        -Fragment "Every workflow job must use windows-2025" `
        -Message "The validator should reject a non-Windows workflow runner."

    Write-ValidFixture
    Set-Content -LiteralPath $workflowPath -Value ($validWorkflow -replace '\./scripts/ci/export_windows\.ps1', './scripts/ci/export_other.ps1') -Encoding utf8
    $contractFailures = @(Get-FixtureFailures)
    Expect-Contains `
        -Values $contractFailures `
        -Fragment "Windows export entrypoint" `
        -Message "The validator should require the canonical Windows export script."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[WINDOWS_PLATFORM_CONTRACT_TEST][FAIL] $failure"
    }
    throw "Windows platform contract validation failed with $($failures.Count) failure(s) across $checks checks."
}

Write-Host "[WINDOWS_PLATFORM_CONTRACT_TEST] Passed: $checks checks"

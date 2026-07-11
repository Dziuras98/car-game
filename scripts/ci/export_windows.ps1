param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary,

    [string]$OutputDirectory = "",
    [string]$TestOutputDirectory = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$presetPath = Join-Path $projectRoot "export_presets.cfg"
. (Join-Path $PSScriptRoot "output_directory_safety.ps1")
. (Join-Path $PSScriptRoot "godot_runtime_log_validation.ps1")

if (-not (Test-Path -LiteralPath $GodotBinary -PathType Leaf)) {
    throw "Godot binary was not found: $GodotBinary"
}
if (-not (Test-Path -LiteralPath $presetPath -PathType Leaf)) {
    throw "Windows export preset was not found: $presetPath"
}

function Resolve-OutputPath {
    param(
        [string]$ConfiguredPath,
        [string]$DefaultRelativePath
    )

    if ([string]::IsNullOrWhiteSpace($ConfiguredPath)) {
        return [System.IO.Path]::GetFullPath((Join-Path $projectRoot $DefaultRelativePath))
    }
    if (-not [System.IO.Path]::IsPathRooted($ConfiguredPath)) {
        $ConfiguredPath = Join-Path $projectRoot $ConfiguredPath
    }
    return [System.IO.Path]::GetFullPath($ConfiguredPath)
}

function Assert-ExportFiles {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [Parameter(Mandatory = $true)][string]$PackPath,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if (-not (Test-Path -LiteralPath $ExecutablePath -PathType Leaf)) {
        throw "$Label executable was not created: $ExecutablePath"
    }
    if ((Get-Item -LiteralPath $ExecutablePath).Length -le 0) {
        throw "$Label executable is empty: $ExecutablePath"
    }
    if (-not (Test-Path -LiteralPath $PackPath -PathType Leaf)) {
        throw "$Label data pack was not created: $PackPath"
    }
}

function Invoke-MainSceneReadinessCheck {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [Parameter(Mandatory = $true)][string]$MarkerPath,
        [string[]]$AdditionalArguments = @()
    )

    $normalStartupMarker = "[NORMAL_STARTUP_SMOKE] Main scene ready"
    $normalStartupMarkerEnvName = "CAR_GAME_NORMAL_STARTUP_MARKER_PATH"
    Remove-Item -LiteralPath $MarkerPath -Force -ErrorAction SilentlyContinue

    $arguments = @(
        "--headless",
        "--log-file",
        ('"' + $LogPath + '"')
    ) + $AdditionalArguments

    $previousMarkerPath = [Environment]::GetEnvironmentVariable(
        $normalStartupMarkerEnvName,
        [EnvironmentVariableTarget]::Process
    )
    [Environment]::SetEnvironmentVariable(
        $normalStartupMarkerEnvName,
        $MarkerPath,
        [EnvironmentVariableTarget]::Process
    )
    try {
        $process = Start-Process `
            -FilePath $ExecutablePath `
            -ArgumentList $arguments `
            -WorkingDirectory $WorkingDirectory `
            -PassThru
    } finally {
        [Environment]::SetEnvironmentVariable(
            $normalStartupMarkerEnvName,
            $previousMarkerPath,
            [EnvironmentVariableTarget]::Process
        )
    }

    $completed = $process.WaitForExit(30000)
    if (-not $completed) {
        $process.Kill($true)
        throw "Packaged startup did not complete its readiness handshake within 30 seconds."
    }
    if ($process.ExitCode -ne 0) {
        if (Test-Path -LiteralPath $LogPath -PathType Leaf) {
            Get-Content -LiteralPath $LogPath | Write-Host
        }
        throw "Packaged startup failed with exit code $($process.ExitCode)."
    }
    if (-not (Test-Path -LiteralPath $MarkerPath -PathType Leaf)) {
        throw "Packaged startup exited successfully but did not create its readiness marker file."
    }

    $markerContent = Get-Content -LiteralPath $MarkerPath -Raw
    if (-not $markerContent.Contains($normalStartupMarker)) {
        throw "Packaged startup marker did not contain the expected readiness text."
    }
    if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        throw "Packaged startup log was not created: $LogPath"
    }

    $logContent = Get-Content -LiteralPath $LogPath -Raw
    Get-Content -LiteralPath $LogPath | Write-Host
    if (-not $logContent.Contains($normalStartupMarker)) {
        throw "Packaged startup log did not contain the expected readiness text."
    }

    Assert-GodotRuntimeLogFile -Path $LogPath -Label "Packaged startup"
    Remove-Item -LiteralPath $MarkerPath -Force
}

$productionOutputPath = Resolve-OutputPath -ConfiguredPath $OutputDirectory -DefaultRelativePath "build/windows"
$testOutputPath = Resolve-OutputPath -ConfiguredPath $TestOutputDirectory -DefaultRelativePath "build/windows-test"
$productionOutputPath = Assert-SafeExportOutputPath `
    -Path $productionOutputPath `
    -ProjectRoot $projectRoot `
    -Label "Production Windows"
$testOutputPath = Assert-SafeExportOutputPath `
    -Path $testOutputPath `
    -ProjectRoot $projectRoot `
    -Label "Windows test"
Assert-IndependentExportOutputPaths `
    -FirstPath $productionOutputPath `
    -FirstLabel "Production Windows" `
    -SecondPath $testOutputPath `
    -SecondLabel "Windows test"
Reset-SafeExportOutputDirectory `
    -Path $productionOutputPath `
    -ProjectRoot $projectRoot `
    -Label "Production Windows"
Reset-SafeExportOutputDirectory `
    -Path $testOutputPath `
    -ProjectRoot $projectRoot `
    -Label "Windows test"

$productionExecutable = Join-Path $productionOutputPath "car-game.exe"
$productionPack = Join-Path $productionOutputPath "car-game.pck"
$normalStartupLog = Join-Path $productionOutputPath "normal-startup-smoke.log"
$normalStartupMarker = Join-Path $productionOutputPath "normal-startup-ready.marker"
$productionSmokeArgumentLog = Join-Path $productionOutputPath "production-smoke-argument.log"
$productionSmokeArgumentMarker = Join-Path $productionOutputPath "production-smoke-argument.marker"

Write-Host ""
Write-Host "=== Export production Windows release ==="
& $GodotBinary --headless --path $projectRoot --export-release "Windows Desktop" $productionExecutable
if ($LASTEXITCODE -ne 0) {
    throw "Production Windows export failed with exit code $LASTEXITCODE."
}
Assert-ExportFiles -ExecutablePath $productionExecutable -PackPath $productionPack -Label "Production Windows"

Write-Host ""
Write-Host "=== Validate production startup ==="
Invoke-MainSceneReadinessCheck `
    -ExecutablePath $productionExecutable `
    -WorkingDirectory $productionOutputPath `
    -LogPath $normalStartupLog `
    -MarkerPath $normalStartupMarker

Write-Host ""
Write-Host "=== Validate production build ignores private smoke argument ==="
Invoke-MainSceneReadinessCheck `
    -ExecutablePath $productionExecutable `
    -WorkingDirectory $productionOutputPath `
    -LogPath $productionSmokeArgumentLog `
    -MarkerPath $productionSmokeArgumentMarker `
    -AdditionalArguments @("--", "--export-smoke-test")

$testExecutable = Join-Path $testOutputPath "car-game-test.exe"
$testPack = Join-Path $testOutputPath "car-game-test.pck"
$smokeLog = Join-Path $testOutputPath "exported-build-smoke.log"

Write-Host ""
Write-Host "=== Export packaged regression build ==="
& $GodotBinary --headless --path $projectRoot --export-release "Windows Test" $testExecutable
if ($LASTEXITCODE -ne 0) {
    throw "Windows test export failed with exit code $LASTEXITCODE."
}
Assert-ExportFiles -ExecutablePath $testExecutable -PackPath $testPack -Label "Windows test"

Write-Host ""
Write-Host "=== Run packaged regression build ==="
$smokeArguments = @(
    "--headless",
    "--log-file",
    ('"' + $smokeLog + '"'),
    "--",
    "--export-smoke-test"
)
$smokeProcess = Start-Process `
    -FilePath $testExecutable `
    -ArgumentList $smokeArguments `
    -WorkingDirectory $testOutputPath `
    -PassThru

$smokeCompleted = $smokeProcess.WaitForExit(90000)
if (-not $smokeCompleted) {
    $smokeProcess.Kill($true)
    throw "Exported build smoke test exceeded the 90-second timeout."
}
if ($smokeProcess.ExitCode -ne 0) {
    if (Test-Path -LiteralPath $smokeLog -PathType Leaf) {
        Get-Content -LiteralPath $smokeLog | Write-Host
    }
    throw "Exported build smoke test failed with exit code $($smokeProcess.ExitCode)."
}
if (-not (Test-Path -LiteralPath $smokeLog -PathType Leaf)) {
    throw "Exported build smoke log was not created: $smokeLog"
}

$smokeLogContent = Get-Content -LiteralPath $smokeLog -Raw
Get-Content -LiteralPath $smokeLog | Write-Host
if (-not $smokeLogContent.Contains("[EXPORTED_BUILD_SMOKE_TEST] Passed:")) {
    throw "Exported build exited successfully but did not write the expected smoke-test success marker."
}
Assert-GodotRuntimeLogFile -Path $smokeLog -Label "Exported build smoke test"

Write-Host ""
Write-Host "Production and packaged regression Windows exports passed."
Write-Host "Production artifact directory: $productionOutputPath"
Write-Host "Test artifact directory: $testOutputPath"

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
. (Join-Path $PSScriptRoot "production_pack_content.ps1")
. (Join-Path $PSScriptRoot "export_version.ps1")

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

function Get-LogContentIfAvailable {
    param([Parameter(Mandatory = $true)][string]$LogPath)

    if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        return ""
    }
    return Get-Content -LiteralPath $LogPath -Raw
}

function Invoke-WindowedMainSceneReadinessCheck {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [string[]]$AdditionalArguments = @()
    )

    $readyMarker = "[GAME_READY] Main scene initialized"
    Remove-Item -LiteralPath $LogPath -Force -ErrorAction SilentlyContinue
    $arguments = @(
        "--audio-driver",
        "Dummy",
        "--log-file",
        ('"' + $LogPath + '"')
    ) + $AdditionalArguments

    $process = Start-Process `
        -FilePath $ExecutablePath `
        -ArgumentList $arguments `
        -WorkingDirectory $WorkingDirectory `
        -PassThru

    $deadline = [DateTime]::UtcNow.AddSeconds(30)
    $windowSeen = $false
    while (-not $process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
        $process.Refresh()
        if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
            $windowSeen = $true
            break
        }
        Start-Sleep -Milliseconds 200
    }

    if ($process.HasExited) {
        $logContent = Get-LogContentIfAvailable -LogPath $LogPath
        if (-not [string]::IsNullOrEmpty($logContent)) {
            $logContent | Write-Host
        }
        throw "Windowed packaged startup exited before creating a native window with code $($process.ExitCode)."
    }
    if (-not $windowSeen) {
        $process.Kill($true)
        $process.WaitForExit()
        throw "Windowed packaged startup did not create a native application window within 30 seconds."
    }

    Start-Sleep -Milliseconds 1500
    $process.Refresh()
    if ($process.HasExited) {
        $logContent = Get-LogContentIfAvailable -LogPath $LogPath
        if (-not [string]::IsNullOrEmpty($logContent)) {
            $logContent | Write-Host
        }
        throw "Windowed packaged startup exited unexpectedly after creating its window with code $($process.ExitCode)."
    }

    if (-not $process.CloseMainWindow()) {
        $process.Kill($true)
        $process.WaitForExit()
        throw "Windowed packaged startup created a window but did not accept a normal close request."
    }
    if (-not $process.WaitForExit(10000)) {
        $process.Kill($true)
        $process.WaitForExit()
        throw "Windowed packaged startup did not terminate after a normal window-close request."
    }
    if ($process.ExitCode -ne 0) {
        $logContent = Get-LogContentIfAvailable -LogPath $LogPath
        if (-not [string]::IsNullOrEmpty($logContent)) {
            $logContent | Write-Host
        }
        throw "Windowed packaged startup closed with exit code $($process.ExitCode)."
    }

    if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        throw "Windowed packaged startup log was not created: $LogPath"
    }
    $finalLogContent = Get-Content -LiteralPath $LogPath -Raw
    Get-Content -LiteralPath $LogPath | Write-Host
    if (-not $finalLogContent.Contains($readyMarker)) {
        throw "Windowed packaged startup log did not contain the expected readiness text."
    }
    Assert-GodotRuntimeLogFile -Path $LogPath -Label "Windowed packaged startup"
}

function Invoke-WindowedSelfTerminatingSmokeTest {
    param(
        [Parameter(Mandatory = $true)][string]$ExecutablePath,
        [Parameter(Mandatory = $true)][string]$WorkingDirectory,
        [Parameter(Mandatory = $true)][string]$LogPath,
        [Parameter(Mandatory = $true)][string]$ExpectedMarker,
        [Parameter(Mandatory = $true)][string]$Label,
        [string[]]$AdditionalArguments = @(),
        [int]$TimeoutSeconds = 30
    )

    Remove-Item -LiteralPath $LogPath -Force -ErrorAction SilentlyContinue
    $arguments = @(
        "--audio-driver",
        "Dummy",
        "--log-file",
        ('"' + $LogPath + '"')
    ) + $AdditionalArguments
    $process = Start-Process `
        -FilePath $ExecutablePath `
        -ArgumentList $arguments `
        -WorkingDirectory $WorkingDirectory `
        -PassThru

    $deadline = [DateTime]::UtcNow.AddSeconds($TimeoutSeconds)
    $windowSeen = $false
    while (-not $process.HasExited -and [DateTime]::UtcNow -lt $deadline) {
        $process.Refresh()
        if ($process.MainWindowHandle -ne [IntPtr]::Zero) {
            $windowSeen = $true
        }
        Start-Sleep -Milliseconds 50
    }

    if (-not $process.HasExited) {
        $process.Kill($true)
        $process.WaitForExit()
        throw "$Label exceeded the $TimeoutSeconds-second timeout."
    }
    if ($process.ExitCode -ne 0) {
        $logContent = Get-LogContentIfAvailable -LogPath $LogPath
        if (-not [string]::IsNullOrEmpty($logContent)) {
            $logContent | Write-Host
        }
        throw "$Label failed with exit code $($process.ExitCode)."
    }
    if (-not $windowSeen) {
        throw "$Label completed without creating a native application window."
    }
    if (-not (Test-Path -LiteralPath $LogPath -PathType Leaf)) {
        throw "$Label log was not created: $LogPath"
    }

    $logContent = Get-Content -LiteralPath $LogPath -Raw
    Get-Content -LiteralPath $LogPath | Write-Host
    if (-not $logContent.Contains($ExpectedMarker)) {
        throw "$Label exited successfully but did not write the expected success marker."
    }
    Assert-GodotRuntimeLogFile -Path $LogPath -Label $Label
}

$originalPresetContent = Get-Content -LiteralPath $presetPath -Raw
$versionInfo = Get-WindowsExportVersionInfo -ProjectRoot $projectRoot
Write-Host "Export source revision: $($versionInfo.Revision)"
Write-Host "Production product version: $($versionInfo.ProductVersion)"
Write-Host "Windows file version: $($versionInfo.FileVersion)"
Set-WindowsExportPresetVersions -PresetPath $presetPath -VersionInfo $versionInfo

try {
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
    $productionSmokeArgumentLog = Join-Path $productionOutputPath "production-smoke-argument.log"

    Write-Host ""
    Write-Host "=== Export production Windows release ==="
    & $GodotBinary --headless --path $projectRoot --export-release "Windows Desktop" $productionExecutable
    if ($LASTEXITCODE -ne 0) {
        throw "Production Windows export failed with exit code $LASTEXITCODE."
    }
    Assert-ExportFiles -ExecutablePath $productionExecutable -PackPath $productionPack -Label "Production Windows"
    Assert-ProductionPackContent -PackPath $productionPack

    Write-Host ""
    Write-Host "=== Validate windowed production startup ==="
    Invoke-WindowedMainSceneReadinessCheck `
        -ExecutablePath $productionExecutable `
        -WorkingDirectory $productionOutputPath `
        -LogPath $normalStartupLog

    Write-Host ""
    Write-Host "=== Validate production build ignores private smoke argument ==="
    Invoke-WindowedMainSceneReadinessCheck `
        -ExecutablePath $productionExecutable `
        -WorkingDirectory $productionOutputPath `
        -LogPath $productionSmokeArgumentLog `
        -AdditionalArguments @("--", "--export-smoke-test")

    $testExecutable = Join-Path $testOutputPath "car-game-test.exe"
    $testPack = Join-Path $testOutputPath "car-game-test.pck"
    $smokeLog = Join-Path $testOutputPath "exported-build-smoke.log"
    $liveAudioSmokeLog = Join-Path $testOutputPath "live-audio-smoke.log"

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
    Write-Host "=== Run windowed live procedural-audio smoke test ==="
    Invoke-WindowedSelfTerminatingSmokeTest `
        -ExecutablePath $testExecutable `
        -WorkingDirectory $testOutputPath `
        -LogPath $liveAudioSmokeLog `
        -ExpectedMarker "[LIVE_AUDIO_SMOKE_TEST] Passed:" `
        -Label "Windowed live audio smoke test" `
        -AdditionalArguments @("--", "--live-audio-smoke-test")

    Write-Host ""
    Write-Host "Production and packaged regression Windows exports passed."
    Write-Host "Production artifact directory: $productionOutputPath"
    Write-Host "Test artifact directory: $testOutputPath"
}
finally {
    [System.IO.File]::WriteAllText(
        $presetPath,
        $originalPresetContent,
        [System.Text.UTF8Encoding]::new($false)
    )
}

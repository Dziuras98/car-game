param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary,

    [string]$OutputDirectory = ""
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$presetPath = Join-Path $projectRoot "export_presets.cfg"

if (-not (Test-Path -LiteralPath $GodotBinary -PathType Leaf)) {
    throw "Godot binary was not found: $GodotBinary"
}
if (-not (Test-Path -LiteralPath $presetPath -PathType Leaf)) {
    throw "Windows export preset was not found: $presetPath"
}

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot "build/windows"
} elseif (-not [System.IO.Path]::IsPathRooted($OutputDirectory)) {
    $OutputDirectory = Join-Path $projectRoot $OutputDirectory
}

$outputPath = [System.IO.Path]::GetFullPath($OutputDirectory)
New-Item -ItemType Directory -Path $outputPath -Force | Out-Null
Get-ChildItem -LiteralPath $outputPath -Force | Remove-Item -Recurse -Force

$executablePath = Join-Path $outputPath "car-game.exe"
$packPath = Join-Path $outputPath "car-game.pck"
$normalStartupLogPath = Join-Path $outputPath "normal-startup-smoke.log"
$normalStartupMarkerPath = Join-Path $outputPath "normal-startup-ready.marker"
$smokeLogPath = Join-Path $outputPath "exported-build-smoke.log"

Write-Host ""
Write-Host "=== Export Windows release ==="
Write-Host "Output: $executablePath"

& $GodotBinary `
    --headless `
    --path $projectRoot `
    --export-release "Windows Desktop" $executablePath
$exportExitCode = $LASTEXITCODE

if ($exportExitCode -ne 0) {
    throw "Windows release export failed with exit code $exportExitCode."
}
if (-not (Test-Path -LiteralPath $executablePath -PathType Leaf)) {
    throw "Windows release executable was not created: $executablePath"
}
if ((Get-Item -LiteralPath $executablePath).Length -le 0) {
    throw "Windows release executable is empty: $executablePath"
}
if (-not (Test-Path -LiteralPath $packPath -PathType Leaf)) {
    throw "Windows release data pack was not created: $packPath"
}

Write-Host ""
Write-Host "=== Run normal packaged startup smoke test ==="

$normalStartupMarker = "[NORMAL_STARTUP_SMOKE] Main scene ready"
$normalStartupMarkerEnvName = "CAR_GAME_NORMAL_STARTUP_MARKER_PATH"
Remove-Item -LiteralPath $normalStartupMarkerPath -Force -ErrorAction SilentlyContinue

$normalStartupArguments = @(
    "--headless",
    "--log-file",
    ('"' + $normalStartupLogPath + '"')
)
$previousMarkerPath = [Environment]::GetEnvironmentVariable(
    $normalStartupMarkerEnvName,
    [EnvironmentVariableTarget]::Process
)
[Environment]::SetEnvironmentVariable(
    $normalStartupMarkerEnvName,
    $normalStartupMarkerPath,
    [EnvironmentVariableTarget]::Process
)
try {
    $normalStartupProcess = Start-Process `
        -FilePath $executablePath `
        -ArgumentList $normalStartupArguments `
        -WorkingDirectory $outputPath `
        -PassThru
} finally {
    [Environment]::SetEnvironmentVariable(
        $normalStartupMarkerEnvName,
        $previousMarkerPath,
        [EnvironmentVariableTarget]::Process
    )
}

$normalStartupCompleted = $normalStartupProcess.WaitForExit(30000)
if (-not $normalStartupCompleted) {
    $normalStartupProcess.Kill($true)
    if (Test-Path -LiteralPath $normalStartupLogPath -PathType Leaf) {
        Get-Content -LiteralPath $normalStartupLogPath | Write-Host
    }
    throw "Normal packaged startup did not complete its readiness handshake within 30 seconds."
}
if ($normalStartupProcess.ExitCode -ne 0) {
    if (Test-Path -LiteralPath $normalStartupLogPath -PathType Leaf) {
        Get-Content -LiteralPath $normalStartupLogPath | Write-Host
    }
    throw "Normal packaged startup failed with exit code $($normalStartupProcess.ExitCode)."
}
if (-not (Test-Path -LiteralPath $normalStartupMarkerPath -PathType Leaf)) {
    if (Test-Path -LiteralPath $normalStartupLogPath -PathType Leaf) {
        Get-Content -LiteralPath $normalStartupLogPath | Write-Host
    }
    throw "Normal packaged startup exited successfully but did not create its readiness marker file."
}

$normalStartupMarkerContent = Get-Content -LiteralPath $normalStartupMarkerPath -Raw
if (-not $normalStartupMarkerContent.Contains($normalStartupMarker)) {
    throw "Normal packaged startup marker file did not contain the expected readiness marker."
}
if (-not (Test-Path -LiteralPath $normalStartupLogPath -PathType Leaf)) {
    throw "Normal packaged startup log was not created: $normalStartupLogPath"
}

$normalStartupLog = Get-Content -LiteralPath $normalStartupLogPath -Raw
Get-Content -LiteralPath $normalStartupLogPath | Write-Host
if (-not $normalStartupLog.Contains($normalStartupMarker)) {
    throw "Normal packaged startup log did not contain the expected readiness marker."
}

Remove-Item -LiteralPath $normalStartupMarkerPath -Force
Write-Host "Normal packaged startup reached the main scene without user arguments."

Write-Host ""
Write-Host "=== Run exported build smoke test ==="

$smokeArguments = @(
    "--headless",
    "--log-file",
    ('"' + $smokeLogPath + '"'),
    "--",
    "--export-smoke-test"
)
$smokeProcess = Start-Process `
    -FilePath $executablePath `
    -ArgumentList $smokeArguments `
    -WorkingDirectory $outputPath `
    -PassThru

$completed = $smokeProcess.WaitForExit(90000)
if (-not $completed) {
    $smokeProcess.Kill($true)
    throw "Exported build smoke test exceeded the 90-second timeout."
}
if ($smokeProcess.ExitCode -ne 0) {
    if (Test-Path -LiteralPath $smokeLogPath -PathType Leaf) {
        Get-Content -LiteralPath $smokeLogPath | Write-Host
    }
    throw "Exported build smoke test failed with exit code $($smokeProcess.ExitCode)."
}
if (-not (Test-Path -LiteralPath $smokeLogPath -PathType Leaf)) {
    throw "Exported build smoke log was not created: $smokeLogPath"
}

$smokeLog = Get-Content -LiteralPath $smokeLogPath -Raw
Get-Content -LiteralPath $smokeLogPath | Write-Host
if (-not $smokeLog.Contains("[EXPORTED_BUILD_SMOKE_TEST] Passed:")) {
    throw "Exported build exited successfully but did not write the expected smoke-test success marker."
}

Write-Host ""
Write-Host "Windows release export and packaged startup smoke tests passed."
Write-Host "Artifact directory: $outputPath"
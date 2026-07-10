param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$testLogDirectory = Join-Path $projectRoot "build/test-logs"

if (-not (Test-Path -LiteralPath $GodotBinary -PathType Leaf)) {
    throw "Godot binary was not found: $GodotBinary"
}

Remove-Item -LiteralPath $testLogDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $testLogDirectory -Force | Out-Null

function Get-GodotRuntimeErrorLines {
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$OutputLines
    )

    $errorPatterns = @(
        '^\s*SCRIPT ERROR:',
        '^\s*ERROR:',
        '^\s*E\s+\d+:\d{2}:\d{2}(?::\d+)?\s+'
    )

    $matches = [System.Collections.Generic.List[string]]::new()
    foreach ($lineValue in $OutputLines) {
        $line = [string]$lineValue
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $normalizedLine = [regex]::Replace($line, "`e\[[0-9;]*[A-Za-z]", "")
        foreach ($pattern in $errorPatterns) {
            if ($normalizedLine -match $pattern) {
                $matches.Add($normalizedLine.Trim())
                break
            }
        }
    }

    return @($matches | Select-Object -Unique)
}

function Assert-RuntimeErrorDetector {
    $probeLines = @(
        "Godot Engine v4.7.stable",
        "E 0:00:09:109 _generate_sample: Invalid access to property or key",
        "SCRIPT ERROR: Invalid access to property or key",
        "ERROR: Failed loading resource"
    )

    $detectedLines = @(Get-GodotRuntimeErrorLines -OutputLines $probeLines)
    if ($detectedLines.Count -ne 3) {
        throw "Godot runtime-error detector self-check failed. Expected 3 matches, found $($detectedLines.Count)."
    }
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

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $GodotBinary
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $CommandArguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $standardOutput = ""
    $standardError = ""
    $exitCode = -1
    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo

    try {
        if (-not $process.Start()) {
            throw "$Name could not start Godot."
        }

        $standardOutputTask = $process.StandardOutput.ReadToEndAsync()
        $standardErrorTask = $process.StandardError.ReadToEndAsync()
        $process.WaitForExit()

        $standardOutput = $standardOutputTask.GetAwaiter().GetResult()
        $standardError = $standardErrorTask.GetAwaiter().GetResult()
        $exitCode = $process.ExitCode
    }
    finally {
        $process.Dispose()
    }

    if (-not [string]::IsNullOrWhiteSpace($standardOutput)) {
        Write-Host $standardOutput.TrimEnd()
    }
    if (-not [string]::IsNullOrWhiteSpace($standardError)) {
        Write-Host $standardError.TrimEnd()
    }

    $safeLogName = (($Name -replace '[^A-Za-z0-9._-]+', '-') -replace '^-|-$', '')
    $logPath = Join-Path $testLogDirectory "$safeLogName.log"
    $logContent = @(
        "Command: $GodotBinary $($CommandArguments -join ' ')"
        "Exit code: $exitCode"
        ""
        "--- stdout ---"
        $standardOutput
        "--- stderr ---"
        $standardError
    ) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($logPath, $logContent, [System.Text.UTF8Encoding]::new($false))

    $combinedOutputLines = @()
    if ($null -ne $standardOutput) {
        $combinedOutputLines += @($standardOutput -split "\r?\n")
    }
    if ($null -ne $standardError) {
        $combinedOutputLines += @($standardError -split "\r?\n")
    }

    $runtimeErrorLines = @(Get-GodotRuntimeErrorLines -OutputLines $combinedOutputLines)
    if ($runtimeErrorLines.Count -gt 0) {
        Write-Host ""
        Write-Host "Godot emitted runtime errors during '$Name':"
        foreach ($runtimeErrorLine in $runtimeErrorLines) {
            Write-Host "  $runtimeErrorLine"
        }
        Write-Host "Diagnostic log: $logPath"
    }

    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode. Diagnostic log: $logPath"
    }
    if ($runtimeErrorLines.Count -gt 0) {
        throw "$Name emitted $($runtimeErrorLines.Count) Godot runtime error(s) despite exit code 0. Diagnostic log: $logPath"
    }
}

Assert-RuntimeErrorDetector

Invoke-GodotCommand -Name "Import project resources" -CommandArguments @(
    "--headless",
    "--path", $projectRoot,
    "--import"
)

$scriptTests = @(
    "scripts/tests/startup_router_test.gd",
    "scripts/tests/car_controller_runtime_config_test.gd",
    "scripts/tests/speedometer_car_binding_test.gd",
    "scripts/tests/tire_squeal_audio_binding_test.gd",
    "scripts/tests/legacy_controller_property_access_test.gd"
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
    "scenes/tests/track_layout_builder_test.tscn",
    "scenes/tests/track_layout_resource_test.tscn",
    "scenes/tests/lap_tracker_checkpoint_test.tscn",
    "scenes/tests/performance_regression_test.tscn",
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
Write-Host "All Godot tests passed without runtime errors."

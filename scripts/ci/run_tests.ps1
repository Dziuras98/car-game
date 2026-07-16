param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$testLogDirectory = Join-Path $projectRoot "build/test-logs"
$junitReportPath = Join-Path $testLogDirectory "junit.xml"
$testResults = [System.Collections.Generic.List[object]]::new()
. (Join-Path $PSScriptRoot "junit_report.ps1")
. (Join-Path $PSScriptRoot "godot_runtime_log_validation.ps1")

if (-not (Test-Path -LiteralPath $GodotBinary -PathType Leaf)) {
    throw "Godot binary was not found: $GodotBinary"
}

New-Item -ItemType Directory -Path $testLogDirectory -Force | Out-Null

function Invoke-RecordedCheck {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ClassName,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )
    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $output = @(& $Action)
        $stopwatch.Stop()
        [void]$script:testResults.Add((New-JUnitTestResult `
            -Name $Name `
            -ClassName $ClassName `
            -DurationSeconds $stopwatch.Elapsed.TotalSeconds `
            -Status "passed" `
            -Output (($output | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
        ))
        return $output
    }
    catch {
        $stopwatch.Stop()
        [void]$script:testResults.Add((New-JUnitTestResult `
            -Name $Name `
            -ClassName $ClassName `
            -DurationSeconds $stopwatch.Elapsed.TotalSeconds `
            -Status "failed" `
            -Message (($_ | Out-String).Trim())
        ))
        throw
    }
}

function Invoke-GodotCommand {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string[]]$Arguments,
        [int]$TimeoutSeconds = 180
    )

    Write-Host ""
    Write-Host "=== $Name ==="
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $GodotBinary
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    foreach ($argument in $Arguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw "$Name could not start Godot."
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        try { $process.Kill($true) } catch {}
        $process.WaitForExit()
        throw "$Name exceeded its $TimeoutSeconds-second timeout."
    }

    $outputLines = @()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    if (-not [string]::IsNullOrEmpty($stdout)) { $outputLines += @($stdout -split "`r?`n") }
    if (-not [string]::IsNullOrEmpty($stderr)) { $outputLines += @($stderr -split "`r?`n") }
    foreach ($line in $outputLines) { Write-Host ([string]$line) }

    $safeName = (($Name -replace '[^A-Za-z0-9._-]+', '-') -replace '^-|-$', '')
    $logPath = Join-Path $testLogDirectory "$safeName.log"
    Set-Content -LiteralPath $logPath -Value $outputLines -Encoding utf8

    if ($process.ExitCode -ne 0) {
        throw "$Name failed with exit code $($process.ExitCode). Log: $logPath"
    }
    Assert-GodotRuntimeLogContent `
        -OutputLines $outputLines `
        -Label $Name `
        -DiagnosticPath $logPath
    return $outputLines
}

try {
    $null = Invoke-RecordedCheck `
        -Name "Static free-drive contracts" `
        -ClassName "repository.static" `
        -Action { & (Join-Path $PSScriptRoot "run_static_checks.ps1") }

    $null = Invoke-RecordedCheck `
        -Name "Import project resources" `
        -ClassName "godot.import" `
        -Action {
            Invoke-GodotCommand -Name "Import project resources" -TimeoutSeconds 300 -Arguments @(
                "--headless", "--path", $projectRoot, "--import"
            )
        }

    $scriptTests = @(
        "scripts/tests/discovery/nested_script_discovery_test.gd",
        "scripts/tests/infinite_grid_track_test.gd",
        "scripts/tests/free_drive_smoke_test.gd"
    )
    foreach ($testScript in $scriptTests) {
        $fullPath = Join-Path $projectRoot $testScript
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            throw "Required script test is missing: $testScript"
        }
        $null = Invoke-RecordedCheck `
            -Name $testScript `
            -ClassName "godot.script" `
            -Action {
                Invoke-GodotCommand -Name "Script test: $testScript" -Arguments @(
                    "--headless", "--path", $projectRoot, "--script", $testScript
                )
            }
    }

    $sceneTests = @(
        "scenes/tests/discovery/nested_scene_discovery_test.tscn",
        "scenes/tests/infinite_grid_track_test.tscn"
    )
    foreach ($testScene in $sceneTests) {
        $fullPath = Join-Path $projectRoot $testScene
        if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
            throw "Required scene test is missing: $testScene"
        }
        $null = Invoke-RecordedCheck `
            -Name $testScene `
            -ClassName "godot.scene" `
            -Action {
                Invoke-GodotCommand -Name "Scene test: $testScene" -Arguments @(
                    "--headless", "--path", $projectRoot, $testScene
                )
            }
    }
}
finally {
    Write-JUnitReport `
        -Results @($testResults) `
        -Path $junitReportPath `
        -SuiteName "car-game free-drive verification"
    Write-Host "JUnit report: $junitReportPath"
}

Write-Host "Free-drive verification completed successfully."

param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$testLogDirectory = Join-Path $projectRoot "build/test-logs"
$currentCommandPath = Join-Path $testLogDirectory "current-command.log"
$junitReportPath = Join-Path $testLogDirectory "junit.xml"
$requiredNestedScriptTest = "scripts/tests/discovery/nested_script_discovery_test.gd"
$requiredNestedSceneTest = "scenes/tests/discovery/nested_scene_discovery_test.tscn"
$allowedWarningPatternsByTestPath = @{
    "scripts/tests/audit_high_priority_contract_test.gd" = @(
        '^WARNING: PlayerCarController rejected invalid CarSpecs; keeping the active runtime configuration\.$'
    )
    "scenes/tests/atomic_track_rebuild_test.tscn" = @(
        '^WARNING: GeneratedTrack surface generation failed; keeping the previous generated content\.$'
    )
    "scenes/tests/track_selection_runtime_test.tscn" = @(
        '^WARNING: Track definition invalid_generated_track did not produce valid generated content; keeping the current track\.$'
    )
}
$testResults = [System.Collections.Generic.List[object]]::new()
. (Join-Path $PSScriptRoot "godot_runtime_log_validation.ps1")
. (Join-Path $PSScriptRoot "junit_report.ps1")

if (-not (Test-Path -LiteralPath $GodotBinary -PathType Leaf)) {
    throw "Godot binary was not found: $GodotBinary"
}

New-Item -ItemType Directory -Path $testLogDirectory -Force | Out-Null
Get-ChildItem -LiteralPath $testLogDirectory -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "localization-validation.log" } |
    Remove-Item -Force -ErrorAction SilentlyContinue

function Invoke-RecordedCheck {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ClassName,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $capturedOutput = @(& $Action)
        $stopwatch.Stop()
        [void]$script:testResults.Add((New-JUnitTestResult `
            -Name $Name `
            -ClassName $ClassName `
            -DurationSeconds $stopwatch.Elapsed.TotalSeconds `
            -Status "passed" `
            -Output (($capturedOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
        ))
        return $capturedOutput
    }
    catch {
        $stopwatch.Stop()
        $failureText = ($_ | Out-String).Trim()
        [void]$script:testResults.Add((New-JUnitTestResult `
            -Name $Name `
            -ClassName $ClassName `
            -DurationSeconds $stopwatch.Elapsed.TotalSeconds `
            -Status "failed" `
            -Message $failureText
        ))
        throw
    }
}

function Invoke-StaticRepositoryChecks {
    $staticLogPath = Join-Path $testLogDirectory "static-checks.log"
    try {
        $staticOutput = @(& (Join-Path $PSScriptRoot "run_static_checks.ps1") 2>&1)
        foreach ($line in $staticOutput) {
            Write-Host ([string]$line)
        }
        Set-Content -LiteralPath $staticLogPath -Value @(
            $staticOutput | ForEach-Object { [string]$_ }
        ) -Encoding utf8
        return $staticOutput
    }
    catch {
        $failureText = $_ | Out-String
        $capturedOutput = @()
        if (Test-Path variable:staticOutput) {
            $capturedOutput = @($staticOutput | ForEach-Object { [string]$_ })
            foreach ($line in $capturedOutput) {
                Write-Host $line
            }
        }
        Set-Content -LiteralPath $staticLogPath -Value (
            $capturedOutput + @("", $failureText)
        ) -Encoding utf8
        throw
    }
}

function Get-AllowedWarningPatternsForTestPath {
    param([Parameter(Mandatory = $true)][string]$TestPath)

    if (-not $allowedWarningPatternsByTestPath.ContainsKey($TestPath)) {
        return @()
    }
    return @($allowedWarningPatternsByTestPath[$TestPath])
}

function Invoke-GodotCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$CommandArguments,

        [int]$TimeoutSeconds = 180,

        [AllowEmptyCollection()]
        [string[]]$AllowedWarningPatterns = @()
    )

    Write-Host ""
    Write-Host "=== $Name ==="
    Write-Host "Godot arguments: $($CommandArguments -join ' ')"
    Write-Host "Timeout: $TimeoutSeconds second(s)"
    Set-Content -LiteralPath $currentCommandPath -Value @(
        "Name: $Name"
        "Started: $([DateTimeOffset]::UtcNow.ToString('O'))"
        "Timeout seconds: $TimeoutSeconds"
        "Command: $GodotBinary $($CommandArguments -join ' ')"
    ) -Encoding utf8

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $GodotBinary
    $startInfo.UseShellExecute = $false
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    $startInfo.CreateNoWindow = $true
    foreach ($argument in $CommandArguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    $started = $process.Start()
    if (-not $started) {
        throw "$Name could not start Godot."
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $completed = $process.WaitForExit($TimeoutSeconds * 1000)
    $timedOut = -not $completed
    if ($timedOut) {
        try {
            $process.Kill($true)
        }
        catch {
            Write-Host "Failed to kill timed-out Godot process: $($_.Exception.Message)"
        }
        $process.WaitForExit()
    }

    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = if ($timedOut) { -1 } else { $process.ExitCode }
    $outputLines = @()
    if (-not [string]::IsNullOrEmpty($stdout)) {
        $outputLines += @($stdout -split "`r?`n")
    }
    if (-not [string]::IsNullOrEmpty($stderr)) {
        $outputLines += @($stderr -split "`r?`n")
    }

    foreach ($outputLine in $outputLines) {
        Write-Host ([string]$outputLine)
    }

    $safeLogName = (($Name -replace '[^A-Za-z0-9._-]+', '-') -replace '^-|-$', '')
    $logPath = Join-Path $testLogDirectory "$safeLogName.log"
    $logContent = @(
        "Command: $GodotBinary $($CommandArguments -join ' ')"
        "Exit code: $exitCode"
        "Timed out: $timedOut"
        "Timeout seconds: $TimeoutSeconds"
        ""
        "--- combined stdout/stderr ---"
    ) + @($outputLines | ForEach-Object { [string]$_ })
    Set-Content -LiteralPath $logPath -Value $logContent -Encoding utf8

    if ($timedOut) {
        throw "$Name exceeded its $TimeoutSeconds-second timeout. Diagnostic log: $logPath"
    }
    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode. Diagnostic log: $logPath"
    }

    Assert-GodotRuntimeLogContent `
        -OutputLines $outputLines `
        -Label $Name `
        -DiagnosticPath $logPath `
        -AllowedWarningPatterns $AllowedWarningPatterns

    return @($outputLines)
}

function Get-ProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$FullPath)
    return [System.IO.Path]::GetRelativePath($projectRoot, $FullPath).Replace('\', '/')
}

$verificationFailed = $false
try {
    Write-Host ""
    Write-Host "=== Static repository checks ==="
    $null = Invoke-RecordedCheck `
        -Name "Static repository checks" `
        -ClassName "repository.static" `
        -Action { Invoke-StaticRepositoryChecks }

    $null = Invoke-RecordedCheck `
        -Name "Import project resources" `
        -ClassName "godot.import" `
        -Action {
            Invoke-GodotCommand -Name "Import project resources" -TimeoutSeconds 300 -CommandArguments @(
                "--headless",
                "--path", $projectRoot,
                "--import"
            )
        }

    $excludedScriptTests = @(
        "scripts/tests/exported_build_smoke_test.gd",
        "scripts/tests/full_program_smoke_test.gd",
        "scripts/tests/game_test_adapter.gd",
        "scripts/tests/run_full_program_smoke_test.gd"
    )
    $scriptTests = @(Invoke-RecordedCheck `
        -Name "Discover standalone script tests" `
        -ClassName "repository.discovery" `
        -Action {
            $discoveredTests = @(
                Get-ChildItem -LiteralPath (Join-Path $projectRoot "scripts/tests") -Filter "*.gd" -File -Recurse |
                    ForEach-Object {
                        $relativePath = Get-ProjectRelativePath -FullPath $_.FullName
                        $content = Get-Content -LiteralPath $_.FullName -Raw
                        if (
                            $excludedScriptTests -notcontains $relativePath -and
                            $content -match '(?m)^\s*extends\s+SceneTree\s*$'
                        ) {
                            $relativePath
                        }
                    } |
                    Sort-Object
            )

            if ($discoveredTests.Count -eq 0) {
                throw "No standalone SceneTree tests were discovered in scripts/tests."
            }
            if ($discoveredTests -notcontains $requiredNestedScriptTest) {
                throw "Recursive script-test discovery did not include required fixture: $requiredNestedScriptTest"
            }
            return $discoveredTests
        }
    )

    foreach ($testScript in $scriptTests) {
        $allowedWarningPatterns = @(Get-AllowedWarningPatternsForTestPath -TestPath $testScript)
        $null = Invoke-RecordedCheck `
            -Name $testScript `
            -ClassName "godot.script" `
            -Action {
                Invoke-GodotCommand `
                    -Name "Script test: $testScript" `
                    -TimeoutSeconds 120 `
                    -AllowedWarningPatterns $allowedWarningPatterns `
                    -CommandArguments @(
                        "--headless",
                        "--path", $projectRoot,
                        "--script", $testScript
                    )
            }
    }

    $excludedSceneTests = @(
        "scenes/tests/exported_build_smoke_test.tscn"
    )
    $sceneTests = @(Invoke-RecordedCheck `
        -Name "Discover scene tests" `
        -ClassName "repository.discovery" `
        -Action {
            $discoveredTests = @(
                Get-ChildItem -LiteralPath (Join-Path $projectRoot "scenes/tests") -Filter "*.tscn" -File -Recurse |
                    ForEach-Object {
                        $relativePath = Get-ProjectRelativePath -FullPath $_.FullName
                        if ($excludedSceneTests -notcontains $relativePath) {
                            $relativePath
                        }
                    } |
                    Sort-Object
            )

            if ($discoveredTests.Count -eq 0) {
                throw "No scene tests were discovered in scenes/tests."
            }
            if ($discoveredTests -notcontains $requiredNestedSceneTest) {
                throw "Recursive scene-test discovery did not include required fixture: $requiredNestedSceneTest"
            }
            return $discoveredTests
        }
    )

    foreach ($testScene in $sceneTests) {
        $allowedWarningPatterns = @(Get-AllowedWarningPatternsForTestPath -TestPath $testScene)
        $sceneTimeoutSeconds = if ($testScene -eq "scenes/tests/full_program_smoke_test.tscn") {
            240
        }
        else {
            180
        }
        $null = Invoke-RecordedCheck `
            -Name $testScene `
            -ClassName "godot.scene" `
            -Action {
                Invoke-GodotCommand `
                    -Name "Scene test: $testScene" `
                    -TimeoutSeconds $sceneTimeoutSeconds `
                    -AllowedWarningPatterns $allowedWarningPatterns `
                    -CommandArguments @(
                        "--headless",
                        "--path", $projectRoot,
                        $testScene
                    )
            }
    }
}
catch {
    $verificationFailed = $true
    throw
}
finally {
    try {
        Write-JUnitReport `
            -Results @($testResults) `
            -Path $junitReportPath `
            -SuiteName "car-game Windows verification"
        Write-Host "JUnit report: $junitReportPath"
    }
    catch {
        Write-Host "Failed to write JUnit report: $($_.Exception.Message)"
        if (-not $verificationFailed) {
            throw
        }
    }
}

Remove-Item -LiteralPath $currentCommandPath -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "All discovered Godot tests passed without runtime errors or unexpected warnings."
Write-Host "Standalone script tests: $($scriptTests.Count)"
Write-Host "Scene tests: $($sceneTests.Count)"
Write-Host "JUnit test cases: $($testResults.Count)"

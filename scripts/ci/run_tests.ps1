param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$testLogDirectory = Join-Path $projectRoot "build/test-logs"
$currentCommandPath = Join-Path $testLogDirectory "current-command.log"
$requiredNestedScriptTest = "scripts/tests/discovery/nested_script_discovery_test.gd"
$requiredNestedSceneTest = "scenes/tests/discovery/nested_scene_discovery_test.tscn"
. (Join-Path $PSScriptRoot "godot_runtime_log_validation.ps1")

if (-not (Test-Path -LiteralPath $GodotBinary -PathType Leaf)) {
    throw "Godot binary was not found: $GodotBinary"
}

New-Item -ItemType Directory -Path $testLogDirectory -Force | Out-Null
Get-ChildItem -LiteralPath $testLogDirectory -File -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne "localization-validation.log" } |
    Remove-Item -Force -ErrorAction SilentlyContinue

Write-Host ""
Write-Host "=== Static repository checks ==="
$staticLogPath = Join-Path $testLogDirectory "static-checks.log"
try {
    $staticOutput = @(& (Join-Path $PSScriptRoot "run_static_checks.ps1") 2>&1)
    foreach ($line in $staticOutput) {
        Write-Host ([string]$line)
    }
    Set-Content -LiteralPath $staticLogPath -Value @($staticOutput | ForEach-Object { [string]$_ }) -Encoding utf8
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
    Set-Content -LiteralPath $staticLogPath -Value ($capturedOutput + @("", $failureText)) -Encoding utf8
    throw
}

function Invoke-GodotCommand {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string[]]$CommandArguments,

        [int]$TimeoutSeconds = 180
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
        -DiagnosticPath $logPath
}

function Get-ProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$FullPath)
    return [System.IO.Path]::GetRelativePath($projectRoot, $FullPath).Replace('\', '/')
}

Invoke-GodotCommand -Name "Import project resources" -TimeoutSeconds 300 -CommandArguments @(
    "--headless",
    "--path", $projectRoot,
    "--import"
)

$excludedScriptTests = @(
    "scripts/tests/exported_build_smoke_test.gd",
    "scripts/tests/full_program_smoke_test.gd",
    "scripts/tests/game_test_adapter.gd",
    "scripts/tests/run_full_program_smoke_test.gd"
)
$scriptTests = @(
    Get-ChildItem -LiteralPath (Join-Path $projectRoot "scripts/tests") -Filter "*.gd" -File -Recurse |
        ForEach-Object {
            $relativePath = Get-ProjectRelativePath -FullPath $_.FullName
            $content = Get-Content -LiteralPath $_.FullName -Raw
            if ($excludedScriptTests -notcontains $relativePath -and $content -match '(?m)^\s*extends\s+SceneTree\s*$') {
                $relativePath
            }
        } |
        Sort-Object
)

if ($scriptTests.Count -eq 0) {
    throw "No standalone SceneTree tests were discovered in scripts/tests."
}
if ($scriptTests -notcontains $requiredNestedScriptTest) {
    throw "Recursive script-test discovery did not include required fixture: $requiredNestedScriptTest"
}

foreach ($testScript in $scriptTests) {
    Invoke-GodotCommand -Name "Script test: $testScript" -TimeoutSeconds 120 -CommandArguments @(
        "--headless",
        "--path", $projectRoot,
        "--script", $testScript
    )
}

$excludedSceneTests = @(
    "scenes/tests/exported_build_smoke_test.tscn"
)
$sceneTests = @(
    Get-ChildItem -LiteralPath (Join-Path $projectRoot "scenes/tests") -Filter "*.tscn" -File -Recurse |
        ForEach-Object {
            $relativePath = Get-ProjectRelativePath -FullPath $_.FullName
            if ($excludedSceneTests -notcontains $relativePath) {
                $relativePath
            }
        } |
        Sort-Object
)

if ($sceneTests.Count -eq 0) {
    throw "No scene tests were discovered in scenes/tests."
}
if ($sceneTests -notcontains $requiredNestedSceneTest) {
    throw "Recursive scene-test discovery did not include required fixture: $requiredNestedSceneTest"
}

foreach ($testScene in $sceneTests) {
    Invoke-GodotCommand -Name "Scene test: $testScene" -TimeoutSeconds 180 -CommandArguments @(
        "--headless",
        "--path", $projectRoot,
        $testScene
    )
}

Remove-Item -LiteralPath $currentCommandPath -Force -ErrorAction SilentlyContinue
Write-Host ""
Write-Host "All discovered Godot tests passed without runtime errors."
Write-Host "Standalone script tests: $($scriptTests.Count)"
Write-Host "Scene tests: $($sceneTests.Count)"

param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$testLogDirectory = Join-Path $projectRoot "build/test-logs"
$currentCommandPath = Join-Path $testLogDirectory "current-command.log"

if (-not (Test-Path -LiteralPath $GodotBinary -PathType Leaf)) {
    throw "Godot binary was not found: $GodotBinary"
}

Remove-Item -LiteralPath $testLogDirectory -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Path $testLogDirectory -Force | Out-Null

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

    $detectedRuntimeErrors = [System.Collections.Generic.List[string]]::new()
    foreach ($lineValue in $OutputLines) {
        $line = [string]$lineValue
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $normalizedLine = [regex]::Replace($line, "`e\[[0-9;]*[A-Za-z]", "")
        foreach ($pattern in $errorPatterns) {
            if ($normalizedLine -match $pattern) {
                $detectedRuntimeErrors.Add($normalizedLine.Trim())
                break
            }
        }
    }

    return @($detectedRuntimeErrors | Select-Object -Unique)
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

    $selfCheckPath = Join-Path $testLogDirectory "runtime-error-detector-self-check.log"
    $selfCheckContent = @("Detected expected probe lines:") + @($detectedLines)
    Set-Content -LiteralPath $selfCheckPath -Value $selfCheckContent -Encoding utf8
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

    $runtimeErrorLines = @(Get-GodotRuntimeErrorLines -OutputLines $outputLines)
    if ($runtimeErrorLines.Count -gt 0) {
        Write-Host ""
        Write-Host "Godot emitted runtime errors during '$Name':"
        foreach ($runtimeErrorLine in $runtimeErrorLines) {
            Write-Host "  $runtimeErrorLine"
        }
        Write-Host "Diagnostic log: $logPath"
    }

    if ($timedOut) {
        throw "$Name exceeded its $TimeoutSeconds-second timeout. Diagnostic log: $logPath"
    }
    if ($exitCode -ne 0) {
        throw "$Name failed with exit code $exitCode. Diagnostic log: $logPath"
    }
    if ($runtimeErrorLines.Count -gt 0) {
        throw "$Name emitted $($runtimeErrorLines.Count) Godot runtime error(s) despite exit code 0. Diagnostic log: $logPath"
    }
}

function Get-ProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$FullPath)
    return [System.IO.Path]::GetRelativePath($projectRoot, $FullPath).Replace('\', '/')
}

Assert-RuntimeErrorDetector

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
    Get-ChildItem -LiteralPath (Join-Path $projectRoot "scripts/tests") -Filter "*.gd" -File |
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
    Get-ChildItem -LiteralPath (Join-Path $projectRoot "scenes/tests") -Filter "*.tscn" -File |
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

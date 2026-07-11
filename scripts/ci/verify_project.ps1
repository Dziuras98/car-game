param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$diagnosticDirectory = Join-Path $projectRoot "build/test-logs"
$localizationLogPath = Join-Path $diagnosticDirectory "localization-validation.log"
$preflightReportPath = Join-Path $projectRoot "build/verification-preflight-junit.xml"
$junitReportPath = Join-Path $diagnosticDirectory "junit.xml"
$mergedReportPath = Join-Path $diagnosticDirectory "junit.merged.xml"
$preflightResults = [System.Collections.Generic.List[object]]::new()
. (Join-Path $PSScriptRoot "junit_report.ps1")

New-Item -ItemType Directory -Path $diagnosticDirectory -Force | Out-Null
Remove-Item -LiteralPath $preflightReportPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $junitReportPath -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $mergedReportPath -Force -ErrorAction SilentlyContinue

function Invoke-RecordedPreflightCheck {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
    $capturedOutput = @()
    try {
        $capturedOutput = @(& $Action 2>&1)
        $stopwatch.Stop()
        foreach ($line in $capturedOutput) {
            Write-Host ([string]$line)
        }
        [void]$script:preflightResults.Add((New-JUnitTestResult `
            -Name $Name `
            -ClassName "repository.preflight" `
            -DurationSeconds $stopwatch.Elapsed.TotalSeconds `
            -Status "passed" `
            -Output (($capturedOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
        ))
        return $capturedOutput
    }
    catch {
        $stopwatch.Stop()
        foreach ($line in $capturedOutput) {
            Write-Host ([string]$line)
        }
        $failureText = ($_ | Out-String).Trim()
        [void]$script:preflightResults.Add((New-JUnitTestResult `
            -Name $Name `
            -ClassName "repository.preflight" `
            -DurationSeconds $stopwatch.Elapsed.TotalSeconds `
            -Status "failed" `
            -Message $failureText `
            -Output (($capturedOutput | ForEach-Object { [string]$_ }) -join [Environment]::NewLine)
        ))
        throw
    }
}

function Invoke-LocalizationContract {
    try {
        $localizationOutput = @(& (Join-Path $PSScriptRoot "validate_localization.ps1") 2>&1)
        Set-Content -LiteralPath $localizationLogPath -Value @(
            $localizationOutput | ForEach-Object { [string]$_ }
        ) -Encoding utf8
        return $localizationOutput
    }
    catch {
        $failureText = $_ | Out-String
        $capturedOutput = @()
        if (Test-Path variable:localizationOutput) {
            $capturedOutput = @($localizationOutput | ForEach-Object { [string]$_ })
        }
        Set-Content -LiteralPath $localizationLogPath -Value (
            $capturedOutput + @("", $failureText)
        ) -Encoding utf8
        throw
    }
}

$verificationFailed = $false
try {
    Write-Host ""
    Write-Host "=== Export output directory safety ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Export output directory safety" `
        -Action { & (Join-Path $PSScriptRoot "test_output_directory_safety.ps1") }

    Write-Host ""
    Write-Host "=== Public repository safety validator regression ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Public repository safety validator regression" `
        -Action { & (Join-Path $PSScriptRoot "test_public_repository_safety.ps1") }

    Write-Host ""
    Write-Host "=== Public repository current snapshot ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Public repository current snapshot" `
        -Action { & (Join-Path $PSScriptRoot "validate_public_repository_safety.ps1") }

    Write-Host ""
    Write-Host "=== Git history safety validator regression ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Git history safety validator regression" `
        -Action { & (Join-Path $PSScriptRoot "test_git_history_safety.ps1") }

    Write-Host ""
    Write-Host "=== Complete Git history safety ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Complete Git history safety" `
        -Action { & (Join-Path $PSScriptRoot "validate_git_history_safety.ps1") }

    Write-Host ""
    Write-Host "=== Windows platform contract regression ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Windows platform contract regression" `
        -Action { & (Join-Path $PSScriptRoot "test_windows_platform_contract.ps1") }

    Write-Host ""
    Write-Host "=== Windows-only platform contract ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Windows-only platform contract" `
        -Action { & (Join-Path $PSScriptRoot "validate_windows_platform_contract.ps1") }

    Write-Host ""
    Write-Host "=== Godot runtime log validation ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Godot runtime log validation" `
        -Action { & (Join-Path $PSScriptRoot "test_godot_runtime_log_validation.ps1") }

    Write-Host ""
    Write-Host "=== JUnit report serialization ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "JUnit report serialization" `
        -Action { & (Join-Path $PSScriptRoot "test_junit_report.ps1") }

    Write-Host ""
    Write-Host "=== JUnit job summary rendering ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "JUnit job summary rendering" `
        -Action { & (Join-Path $PSScriptRoot "test_junit_step_summary.ps1") }

    Write-Host ""
    Write-Host "=== Test script ownership regression ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Test script ownership regression" `
        -Action { & (Join-Path $PSScriptRoot "test_test_script_ownership.ps1") }

    Write-Host ""
    Write-Host "=== Recursive test script ownership ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Recursive test script ownership" `
        -Action { & (Join-Path $PSScriptRoot "validate_test_script_ownership.ps1") }

    Write-Host ""
    Write-Host "=== Input action literal validation regression ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Input action literal validation regression" `
        -Action { & (Join-Path $PSScriptRoot "test_input_action_literal_validation.ps1") }

    Write-Host ""
    Write-Host "=== Input action contract ownership ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Input action contract ownership" `
        -Action { & (Join-Path $PSScriptRoot "validate_input_action_literals.ps1") }

    Write-Host ""
    Write-Host "=== Localization contract ==="
    $null = Invoke-RecordedPreflightCheck `
        -Name "Localization contract" `
        -Action { Invoke-LocalizationContract }

    Write-JUnitReport `
        -Results @($preflightResults) `
        -Path $preflightReportPath `
        -SuiteName "car-game verification preflight"

    & (Join-Path $PSScriptRoot "run_tests.ps1") -GodotBinary $GodotBinary
}
catch {
    $verificationFailed = $true
    throw
}
finally {
    try {
        Write-JUnitReport `
            -Results @($preflightResults) `
            -Path $preflightReportPath `
            -SuiteName "car-game verification preflight"

        $sourceReports = @($preflightReportPath)
        if (Test-Path -LiteralPath $junitReportPath -PathType Leaf) {
            $sourceReports += $junitReportPath
        }

        Merge-JUnitReports `
            -SourcePaths $sourceReports `
            -Path $mergedReportPath `
            -SuiteName "car-game complete Windows verification"
        Move-Item -LiteralPath $mergedReportPath -Destination $junitReportPath -Force
        Remove-Item -LiteralPath $preflightReportPath -Force -ErrorAction SilentlyContinue
        Write-Host "Complete JUnit report: $junitReportPath"
    }
    catch {
        Write-Host "Failed to finalize complete JUnit report: $($_.Exception.Message)"
        if (-not $verificationFailed) {
            throw
        }
    }
}

Write-Host ""
Write-Host "Project verification completed successfully."

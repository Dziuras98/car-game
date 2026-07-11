Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "junit_report.ps1")

$checks = 0
$failures = [System.Collections.Generic.List[string]]::new()

function Expect-True {
    param(
        [Parameter(Mandatory = $true)][bool]$Condition,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks += 1
    if (-not $Condition) {
        $script:failures.Add($Message)
    }
}

function Expect-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][string]$Fragment,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks += 1
    if (-not $Content.Contains($Fragment)) {
        $script:failures.Add("$Message Missing fragment: $Fragment")
    }
}

function Expect-Throws {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks += 1
    try {
        & $Action
        $script:failures.Add("$Message No exception was thrown.")
    }
    catch {
    }
}

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$workflowPath = Join-Path $projectRoot ".github/workflows/windows-tests.yml"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-junit-summary-" + [guid]::NewGuid().ToString("N"))
$reportPath = Join-Path $tempRoot "junit.xml"
$summaryPath = Join-Path $tempRoot "summary.md"
$missingSummaryPath = Join-Path $tempRoot "missing-summary.md"
$emptyReportPath = Join-Path $tempRoot "empty.xml"
$emptySummaryPath = Join-Path $tempRoot "empty-summary.md"

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    $results = @(
        New-JUnitTestResult `
            -Name "Static checks" `
            -ClassName "repository.static" `
            -DurationSeconds 0.125 `
            -Status "passed"
        New-JUnitTestResult `
            -Name "Localization" `
            -ClassName "repository.preflight" `
            -DurationSeconds 0.25 `
            -Status "passed"
        New-JUnitTestResult `
            -Name "Scene | smoke" `
            -ClassName "godot.scene" `
            -DurationSeconds 1.5 `
            -Status "failed" `
            -Message "line 1`nline | 2"
    )
    Write-JUnitReport -Results $results -Path $reportPath -SuiteName "summary fixture"

    & (Join-Path $PSScriptRoot "write_junit_step_summary.ps1") `
        -ReportPath $reportPath `
        -SummaryPath $summaryPath

    $summary = Get-Content -LiteralPath $summaryPath -Raw
    Expect-Contains -Content $summary -Fragment "## Windows verification" -Message "The summary should contain its heading."
    Expect-Contains -Content $summary -Fragment "| Failed | 3 | 1 | 1.875 s |" -Message "The summary should contain invariant totals."
    Expect-Contains -Content $summary -Fragment "Scene \| smoke" -Message "Pipe characters in test names should be escaped."
    Expect-Contains -Content $summary -Fragment "line 1<br>line \| 2" -Message "Failure messages should normalize line breaks and pipe characters."

    $missingReportPath = Join-Path $tempRoot "missing.xml"
    Expect-Throws `
        -Action {
            & (Join-Path $PSScriptRoot "write_junit_step_summary.ps1") `
                -ReportPath $missingReportPath `
                -SummaryPath $missingSummaryPath
        } `
        -Message "A missing report should fail summary publication."
    $missingSummary = Get-Content -LiteralPath $missingSummaryPath -Raw
    Expect-Contains -Content $missingSummary -Fragment "Report unavailable" -Message "A missing report should still produce a diagnostic summary."

    Write-JUnitReport -Results @() -Path $emptyReportPath -SuiteName "empty"
    Expect-Throws `
        -Action {
            & (Join-Path $PSScriptRoot "write_junit_step_summary.ps1") `
                -ReportPath $emptyReportPath `
                -SummaryPath $emptySummaryPath
        } `
        -Message "An empty report should fail summary publication."
    $emptySummary = Get-Content -LiteralPath $emptySummaryPath -Raw
    Expect-Contains -Content $emptySummary -Fragment "No test cases were recorded." -Message "An empty report should explain the invalid state."

    Expect-True -Condition (Test-Path -LiteralPath $workflowPath -PathType Leaf) -Message "The Windows workflow should exist."
    $workflow = Get-Content -LiteralPath $workflowPath -Raw
    foreach ($requiredFragment in @(
        "- name: Publish verification summary",
        "if: always()",
        "./scripts/ci/write_junit_step_summary.ps1",
        '$env:GITHUB_STEP_SUMMARY'
    )) {
        Expect-Contains `
            -Content $workflow `
            -Fragment $requiredFragment `
            -Message "The Windows workflow should retain JUnit summary publication."
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[JUNIT_STEP_SUMMARY_TEST][FAIL] $failure"
    }
    throw "JUnit step-summary test failed with $($failures.Count) failure(s) across $checks checks."
}

Write-Host "[JUNIT_STEP_SUMMARY_TEST] Passed: $checks checks"

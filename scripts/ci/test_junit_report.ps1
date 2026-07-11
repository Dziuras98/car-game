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

function Expect-Equal {
    param(
        [AllowNull()]$Actual,
        [AllowNull()]$Expected,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks += 1
    if ($Actual -ne $Expected) {
        $script:failures.Add("$Message Expected '$Expected', received '$Actual'.")
    }
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-junit-report-" + [guid]::NewGuid().ToString("N"))
$reportPath = Join-Path $tempRoot "nested/results.xml"
$emptyReportPath = Join-Path $tempRoot "empty.xml"

try {
    $results = @(
        New-JUnitTestResult `
            -Name "Import <project>" `
            -ClassName "ci.import" `
            -DurationSeconds 0.125 `
            -Status "passed" `
            -Output "clean & ready"
        New-JUnitTestResult `
            -Name "Scene test" `
            -ClassName "godot.scene" `
            -DurationSeconds 1.5 `
            -Status "failed" `
            -Message "ERROR: bad <resource>" `
            -Output ("before" + [char]1 + "after")
    )

    Write-JUnitReport -Results $results -Path $reportPath -SuiteName "car-game & Windows"

    Expect-True `
        -Condition (Test-Path -LiteralPath $reportPath -PathType Leaf) `
        -Message "The JUnit writer should create parent directories and the report file."
    Expect-True `
        -Condition ((Get-Item -LiteralPath $reportPath).Length -gt 0) `
        -Message "The generated JUnit report should not be empty."

    [xml]$document = Get-Content -LiteralPath $reportPath -Raw
    Expect-Equal -Actual $document.testsuites.name -Expected "car-game & Windows" -Message "Suite names should round-trip through XML escaping."
    Expect-Equal -Actual $document.testsuites.tests -Expected "2" -Message "The root test count should match the result list."
    Expect-Equal -Actual $document.testsuites.failures -Expected "1" -Message "The root failure count should match failed results."
    Expect-Equal -Actual $document.testsuites.testsuite.time -Expected "1.625000" -Message "The suite duration should use invariant decimal formatting."

    $testCases = @($document.testsuites.testsuite.testcase)
    Expect-Equal -Actual $testCases.Count -Expected 2 -Message "The report should contain one testcase element per result."
    Expect-Equal -Actual $testCases[0].name -Expected "Import <project>" -Message "Test names should round-trip through XML escaping."
    Expect-Equal -Actual $testCases[0].'system-out' -Expected "clean & ready" -Message "Successful output should be preserved."
    Expect-Equal -Actual $testCases[1].failure.message -Expected "ERROR: bad <resource>" -Message "Failure messages should be preserved."
    Expect-Equal -Actual $testCases[1].'system-out' -Expected "beforeafter" -Message "Invalid XML control characters should be removed."

    $bytes = [System.IO.File]::ReadAllBytes($reportPath)
    $hasUtf8Bom = $bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF
    Expect-True -Condition (-not $hasUtf8Bom) -Message "The JUnit report should use UTF-8 without a byte-order mark."

    Write-JUnitReport -Results @() -Path $emptyReportPath -SuiteName "empty"
    [xml]$emptyDocument = Get-Content -LiteralPath $emptyReportPath -Raw
    Expect-Equal -Actual $emptyDocument.testsuites.tests -Expected "0" -Message "An empty result list should produce a valid zero-test report."
    Expect-Equal -Actual $emptyDocument.testsuites.failures -Expected "0" -Message "An empty result list should report zero failures."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[JUNIT_REPORT_TEST][FAIL] $failure"
    }
    throw "JUnit report test failed with $($failures.Count) failure(s) across $checks checks."
}

Write-Host "[JUNIT_REPORT_TEST] Passed: $checks checks"

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "output_directory_safety.ps1")

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

function Expect-Throws {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [Parameter(Mandatory = $true)][string]$ExpectedFragment,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks += 1
    try {
        & $Action
        $script:failures.Add("$Message (no exception was thrown)")
    }
    catch {
        if (-not $_.Exception.Message.Contains($ExpectedFragment)) {
            $script:failures.Add("$Message (unexpected exception: $($_.Exception.Message))")
        }
    }
}

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-output-safety-" + [guid]::NewGuid().ToString("N"))
$testProjectRoot = Join-Path $tempRoot "project"
$buildRoot = Join-Path $testProjectRoot "build"

try {
    New-Item -ItemType Directory -Path $buildRoot -Force | Out-Null

    $productionPath = Join-Path $buildRoot "windows"
    $testPath = Join-Path $buildRoot "windows-test"
    $resolvedProductionPath = Assert-SafeExportOutputPath `
        -Path $productionPath `
        -ProjectRoot $testProjectRoot `
        -Label "Production"
    Expect-True `
        -Condition ($resolvedProductionPath -eq [System.IO.Path]::GetFullPath($productionPath)) `
        -Message "A normal production output directory under build should be accepted."

    Assert-IndependentExportOutputPaths `
        -FirstPath $productionPath `
        -FirstLabel "Production" `
        -SecondPath $testPath `
        -SecondLabel "Test"
    Expect-True -Condition $true -Message "Sibling production and test output directories should be accepted."

    Expect-Throws `
        -Action { Assert-SafeExportOutputPath -Path $testProjectRoot -ProjectRoot $testProjectRoot -Label "Production" } `
        -ExpectedFragment "must be a descendant" `
        -Message "The repository root must be rejected as an output directory."
    Expect-Throws `
        -Action { Assert-SafeExportOutputPath -Path $buildRoot -ProjectRoot $testProjectRoot -Label "Production" } `
        -ExpectedFragment "must be a descendant" `
        -Message "The build root must be rejected as an output directory."
    Expect-Throws `
        -Action { Assert-SafeExportOutputPath -Path (Join-Path $testProjectRoot "build-output") -ProjectRoot $testProjectRoot -Label "Production" } `
        -ExpectedFragment "must be a descendant" `
        -Message "A sibling path with a build-like prefix must be rejected."
    Expect-Throws `
        -Action {
            Assert-IndependentExportOutputPaths `
                -FirstPath $productionPath `
                -FirstLabel "Production" `
                -SecondPath $productionPath `
                -SecondLabel "Test"
        } `
        -ExpectedFragment "must be different" `
        -Message "Identical production and test output directories must be rejected."
    Expect-Throws `
        -Action {
            Assert-IndependentExportOutputPaths `
                -FirstPath $productionPath `
                -FirstLabel "Production" `
                -SecondPath (Join-Path $productionPath "nested") `
                -SecondLabel "Test"
        } `
        -ExpectedFragment "cannot contain one another" `
        -Message "Nested production and test output directories must be rejected."

    $fileOutputPath = Join-Path $buildRoot "existing-file"
    Set-Content -LiteralPath $fileOutputPath -Value "not a directory" -Encoding utf8
    Expect-Throws `
        -Action { Assert-SafeExportOutputPath -Path $fileOutputPath -ProjectRoot $testProjectRoot -Label "Production" } `
        -ExpectedFragment "is not a directory" `
        -Message "An existing file must be rejected as an output directory."

    New-Item -ItemType Directory -Path $productionPath -Force | Out-Null
    $staleArtifact = Join-Path $productionPath "stale.txt"
    $outsideSentinel = Join-Path $testProjectRoot "keep.txt"
    Set-Content -LiteralPath $staleArtifact -Value "remove" -Encoding utf8
    Set-Content -LiteralPath $outsideSentinel -Value "keep" -Encoding utf8

    Reset-SafeExportOutputDirectory `
        -Path $productionPath `
        -ProjectRoot $testProjectRoot `
        -Label "Production"
    Expect-True `
        -Condition (-not (Test-Path -LiteralPath $staleArtifact)) `
        -Message "Reset should remove stale contents from the validated output directory."
    Expect-True `
        -Condition (Test-Path -LiteralPath $outsideSentinel -PathType Leaf) `
        -Message "Reset must not remove files outside the validated output directory."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[OUTPUT_DIRECTORY_SAFETY_TEST][FAIL] $failure"
    }
    throw "Output directory safety test failed with $($failures.Count) failure(s) across $checks checks."
}

Write-Host "[OUTPUT_DIRECTORY_SAFETY_TEST] Passed: $checks checks"

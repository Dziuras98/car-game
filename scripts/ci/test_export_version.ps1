Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "export_version.ps1")

$checks = 0
$failures = [System.Collections.Generic.List[string]]::new()

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

function Expect-Contains {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Fragment,
        [Parameter(Mandatory = $true)][string]$Message
    )
    $script:checks += 1
    if (-not $Value.Contains($Fragment)) {
        $script:failures.Add("$Message Missing fragment: $Fragment")
    }
}

$previousSha = $env:GITHUB_SHA
$previousRefType = $env:GITHUB_REF_TYPE
$previousRefName = $env:GITHUB_REF_NAME
$previousRunNumber = $env:GITHUB_RUN_NUMBER
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-export-version-" + [guid]::NewGuid().ToString("N"))
$presetPath = Join-Path $tempRoot "export_presets.cfg"

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $env:GITHUB_SHA = "1234567890abcdef1234567890abcdef12345678"
    $env:GITHUB_REF_TYPE = "branch"
    $env:GITHUB_REF_NAME = "master"
    $env:GITHUB_RUN_NUMBER = "42"

    $branchVersion = Get-WindowsExportVersionInfo -ProjectRoot $tempRoot
    Expect-Equal -Actual $branchVersion.Revision -Expected $env:GITHUB_SHA -Message "Branch export should retain the full source revision."
    Expect-Equal -Actual $branchVersion.ProductVersion -Expected "0.1.0-1234567" -Message "Branch export should include the short revision."
    Expect-Equal -Actual $branchVersion.TestProductVersion -Expected "0.1.0-1234567-test" -Message "Test export should retain the source revision."
    Expect-Equal -Actual $branchVersion.FileVersion -Expected "0.1.0.42" -Message "Branch file version should use the workflow run number."

    $env:GITHUB_REF_TYPE = "tag"
    $env:GITHUB_REF_NAME = "v2.3.4"
    $tagVersion = Get-WindowsExportVersionInfo -ProjectRoot $tempRoot
    Expect-Equal -Actual $tagVersion.ProductVersion -Expected "2.3.4" -Message "Tagged export should use semantic product versioning."
    Expect-Equal -Actual $tagVersion.TestProductVersion -Expected "2.3.4-test" -Message "Tagged test export should preserve the semantic version."
    Expect-Equal -Actual $tagVersion.FileVersion -Expected "2.3.4.42" -Message "Tagged file version should remain numeric."

    Set-Content -LiteralPath $presetPath -Encoding utf8 -Value @'
[preset.0.options]
application/file_version="0.1.0.0"
application/product_version="0.1.0"

[preset.1.options]
application/file_version="0.1.0.0"
application/product_version="0.1.0-test"
'@
    Set-WindowsExportPresetVersions -PresetPath $presetPath -VersionInfo $tagVersion
    $updatedContent = Get-Content -LiteralPath $presetPath -Raw
    Expect-Equal -Actual ([regex]::Matches($updatedContent, 'application/file_version="2\.3\.4\.42"').Count) -Expected 2 -Message "Both presets should receive the derived numeric file version."
    Expect-Contains -Value $updatedContent -Fragment 'application/product_version="2.3.4"' -Message "Production preset should receive the derived product version."
    Expect-Contains -Value $updatedContent -Fragment 'application/product_version="2.3.4-test"' -Message "Test preset should receive the derived test product version."
}
finally {
    $env:GITHUB_SHA = $previousSha
    $env:GITHUB_REF_TYPE = $previousRefType
    $env:GITHUB_REF_NAME = $previousRefName
    $env:GITHUB_RUN_NUMBER = $previousRunNumber
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[EXPORT_VERSION_TEST][FAIL] $failure"
    }
    throw "Export version regression failed with $($failures.Count) failure(s) across $checks checks."
}

Write-Host "[EXPORT_VERSION_TEST] Passed: $checks checks"

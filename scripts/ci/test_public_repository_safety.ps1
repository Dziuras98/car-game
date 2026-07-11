Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$validatorPath = Join-Path $PSScriptRoot "validate_public_repository_safety.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-public-safety-" + [guid]::NewGuid().ToString("N"))
$checks = 0
$failures = [System.Collections.Generic.List[string]]::new()

function Expect-Pass {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    $script:checks += 1
    try {
        & $Action | Out-Null
    }
    catch {
        $script:failures.Add("$Name unexpectedly failed: $($_.Exception.Message)")
    }
}

function Expect-Failure {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][scriptblock]$Action
    )

    $script:checks += 1
    try {
        & $Action | Out-Null
        $script:failures.Add("$Name unexpectedly passed.")
    }
    catch {
        return
    }
}

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    New-Item -ItemType Directory -Path (Join-Path $tempRoot "scripts") -Force | Out-Null
    Set-Content -LiteralPath (Join-Path $tempRoot "README.md") -Value "Safe public repository fixture." -Encoding utf8
    Set-Content -LiteralPath (Join-Path $tempRoot ".env.example") -Value "EXAMPLE_VALUE=replace-me" -Encoding utf8

    Expect-Pass -Name "safe repository" -Action {
        & $validatorPath -ProjectRoot $tempRoot
    }

    Set-Content -LiteralPath (Join-Path $tempRoot ".env") -Value "SECRET=value" -Encoding utf8
    Expect-Failure -Name "environment file" -Action {
        & $validatorPath -ProjectRoot $tempRoot
    }
    Remove-Item -LiteralPath (Join-Path $tempRoot ".env") -Force

    Set-Content -LiteralPath (Join-Path $tempRoot "private.pem") -Value "not-even-a-real-key" -Encoding utf8
    Expect-Failure -Name "private key file extension" -Action {
        & $validatorPath -ProjectRoot $tempRoot
    }
    Remove-Item -LiteralPath (Join-Path $tempRoot "private.pem") -Force

    Set-Content -LiteralPath (Join-Path $tempRoot "scripts/example.gd") -Value @(
        "extends Node",
        'const LOCAL_PATH = "C:\Users\Example\private\file.txt"'
    ) -Encoding utf8
    Expect-Failure -Name "local Windows profile path" -Action {
        & $validatorPath -ProjectRoot $tempRoot
    }
    Remove-Item -LiteralPath (Join-Path $tempRoot "scripts/example.gd") -Force

    Set-Content -LiteralPath (Join-Path $tempRoot "scripts/example.gd") -Value @(
        "extends Node",
        'const KEY = "-----BEGIN PRIVATE KEY-----"'
    ) -Encoding utf8
    Expect-Failure -Name "private key marker" -Action {
        & $validatorPath -ProjectRoot $tempRoot
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[PUBLIC_REPOSITORY_SAFETY_TEST][FAIL] $failure"
    }
    throw "Public repository safety validator test failed with $($failures.Count) issue(s)."
}

Write-Host "Public repository safety validator test passed: $checks checks."

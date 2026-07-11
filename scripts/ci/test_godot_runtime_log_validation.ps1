Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "godot_runtime_log_validation.ps1")

$checks = 0
$failures = [System.Collections.Generic.List[string]]::new()

function Expect-NoThrow {
    param(
        [Parameter(Mandatory = $true)][scriptblock]$Action,
        [Parameter(Mandatory = $true)][string]$Message
    )

    $script:checks += 1
    try {
        & $Action
    }
    catch {
        $script:failures.Add("$Message (unexpected exception: $($_.Exception.Message))")
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

$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-runtime-log-validation-" + [guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

    $cleanLog = Join-Path $tempRoot "clean.log"
    Set-Content -LiteralPath $cleanLog -Value @(
        "Godot Engine v4.7.stable",
        "[NORMAL_STARTUP_SMOKE] Main scene ready",
        "The word ERROR appears in ordinary prose and is not an engine error prefix."
    ) -Encoding utf8
    Expect-NoThrow `
        -Action { Assert-GodotRuntimeLogFile -Path $cleanLog -Label "Clean packaged startup" } `
        -Message "A clean Godot log should be accepted."

    $scriptErrorLog = Join-Path $tempRoot "script-error.log"
    Set-Content -LiteralPath $scriptErrorLog -Value @(
        "Godot Engine v4.7.stable",
        "SCRIPT ERROR: Invalid access to property or key",
        "[NORMAL_STARTUP_SMOKE] Main scene ready"
    ) -Encoding utf8
    Expect-Throws `
        -Action { Assert-GodotRuntimeLogFile -Path $scriptErrorLog -Label "Script-error startup" } `
        -ExpectedFragment "1 Godot runtime error" `
        -Message "A SCRIPT ERROR line must fail validation even when a success marker is present."

    $engineErrorLog = Join-Path $tempRoot "engine-error.log"
    Set-Content -LiteralPath $engineErrorLog -Value "ERROR: Failed loading resource" -Encoding utf8
    Expect-Throws `
        -Action { Assert-GodotRuntimeLogFile -Path $engineErrorLog -Label "Engine-error startup" } `
        -ExpectedFragment "1 Godot runtime error" `
        -Message "An ERROR line must fail validation."

    $timestampErrorLog = Join-Path $tempRoot "timestamp-error.log"
    Set-Content -LiteralPath $timestampErrorLog -Value "E 0:00:09:109 _generate_sample: Invalid access to property or key" -Encoding utf8
    Expect-Throws `
        -Action { Assert-GodotRuntimeLogFile -Path $timestampErrorLog -Label "Timestamp-error startup" } `
        -ExpectedFragment "1 Godot runtime error" `
        -Message "A timestamped Godot E line must fail validation."

    $ansiErrorLog = Join-Path $tempRoot "ansi-error.log"
    $escape = [string][char]27
    Set-Content -LiteralPath $ansiErrorLog -Value ("${escape}[31mERROR: Colored engine failure${escape}[0m") -Encoding utf8
    Expect-Throws `
        -Action { Assert-GodotRuntimeLogFile -Path $ansiErrorLog -Label "ANSI-error startup" } `
        -ExpectedFragment "1 Godot runtime error" `
        -Message "ANSI color sequences must not hide an engine error."

    $duplicateErrorLog = Join-Path $tempRoot "duplicate-error.log"
    Set-Content -LiteralPath $duplicateErrorLog -Value @(
        "ERROR: Repeated failure",
        "ERROR: Repeated failure"
    ) -Encoding utf8
    Expect-Throws `
        -Action { Assert-GodotRuntimeLogFile -Path $duplicateErrorLog -Label "Duplicate-error startup" } `
        -ExpectedFragment "1 Godot runtime error" `
        -Message "Duplicate engine errors should be reported once."

    $missingLog = Join-Path $tempRoot "missing.log"
    Expect-Throws `
        -Action { Assert-GodotRuntimeLogFile -Path $missingLog -Label "Missing packaged startup" } `
        -ExpectedFragment "log was not created" `
        -Message "A missing runtime log must fail validation."
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[GODOT_RUNTIME_LOG_VALIDATION_TEST][FAIL] $failure"
    }
    throw "Godot runtime log validation test failed with $($failures.Count) failure(s) across $checks checks."
}

Write-Host "[GODOT_RUNTIME_LOG_VALIDATION_TEST] Passed: $checks checks"

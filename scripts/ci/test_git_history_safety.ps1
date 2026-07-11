Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$validatorPath = Join-Path $PSScriptRoot "validate_git_history_safety.ps1"
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("car-game-git-history-safety-" + [guid]::NewGuid().ToString("N"))
$safeRepository = Join-Path $tempRoot "safe"
$unsafeRepository = Join-Path $tempRoot "unsafe"
$checks = 0
$failures = [System.Collections.Generic.List[string]]::new()

function Invoke-Git {
    param(
        [Parameter(Mandatory = $true)][string]$RepositoryPath,
        [Parameter(Mandatory = $true)][string[]]$Arguments
    )

    $output = @(& git -C $RepositoryPath @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
}

function Initialize-TestRepository {
    param([Parameter(Mandatory = $true)][string]$RepositoryPath)

    New-Item -ItemType Directory -Path $RepositoryPath -Force | Out-Null
    Invoke-Git -RepositoryPath $RepositoryPath -Arguments @("init", "-b", "master")
    Invoke-Git -RepositoryPath $RepositoryPath -Arguments @("config", "user.name", "History Safety Test")
    Invoke-Git -RepositoryPath $RepositoryPath -Arguments @("config", "user.email", "history-safety@example.invalid")
    Set-Content -LiteralPath (Join-Path $RepositoryPath "README.md") -Value "Safe history fixture." -Encoding utf8
    Invoke-Git -RepositoryPath $RepositoryPath -Arguments @("add", "README.md")
    Invoke-Git -RepositoryPath $RepositoryPath -Arguments @("commit", "-m", "Add safe fixture")
}

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

    Initialize-TestRepository -RepositoryPath $safeRepository
    Expect-Pass -Name "safe complete history" -Action {
        & $validatorPath -ProjectRoot $safeRepository
    }

    Initialize-TestRepository -RepositoryPath $unsafeRepository
    Set-Content -LiteralPath (Join-Path $unsafeRepository "old-secret.txt") -Value "-----BEGIN PRIVATE KEY-----" -Encoding utf8
    Invoke-Git -RepositoryPath $unsafeRepository -Arguments @("add", "old-secret.txt")
    Invoke-Git -RepositoryPath $unsafeRepository -Arguments @("commit", "-m", "Add historical secret fixture")
    Remove-Item -LiteralPath (Join-Path $unsafeRepository "old-secret.txt") -Force
    Invoke-Git -RepositoryPath $unsafeRepository -Arguments @("add", "-A")
    Invoke-Git -RepositoryPath $unsafeRepository -Arguments @("commit", "-m", "Remove historical secret fixture")

    if (Test-Path -LiteralPath (Join-Path $unsafeRepository "old-secret.txt")) {
        throw "Unsafe fixture was not removed from the current work tree."
    }
    Expect-Failure -Name "secret deleted from current tree but retained in history" -Action {
        & $validatorPath -ProjectRoot $unsafeRepository
    }
}
finally {
    Remove-Item -LiteralPath $tempRoot -Recurse -Force -ErrorAction SilentlyContinue
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[GIT_HISTORY_SAFETY_TEST][FAIL] $failure"
    }
    throw "Git history safety validator test failed with $($failures.Count) issue(s)."
}

Write-Host "Git history safety validator test passed: $checks checks."

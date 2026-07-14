param(
    [Parameter(Mandatory = $true)]
    [string]$GodotBinary
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$diagnosticDirectory = Join-Path $projectRoot "build/test-logs"
$patcherPath = Join-Path $projectRoot "tools/apply_engine_audio_realism_patch.py"
$originalVerifier = Join-Path $PSScriptRoot "verify_project_original.ps1"
$packageRoot = Join-Path $env:RUNNER_TEMP "engine-audio-patched-source"
$packagePath = Join-Path $diagnosticDirectory "engine-audio-patched-source.zip"

New-Item -ItemType Directory -Path $diagnosticDirectory -Force | Out-Null

try {
    if (-not (Test-Path -LiteralPath $patcherPath -PathType Leaf)) {
        throw "Engine-audio patcher was not found: $patcherPath"
    }
    if (-not (Test-Path -LiteralPath $originalVerifier -PathType Leaf)) {
        throw "Original verification entrypoint was not found: $originalVerifier"
    }

    $patcherContent = Get-Content -LiteralPath $patcherPath -Raw
    $patcherContent = $patcherContent.Replace(
        "`t`tpush_warning(`n`t`t`t`"EngineAudioProfile ignored",
        "`t`tprint_verbose(`n`t`t`t`"EngineAudioProfile ignored"
    )
    Set-Content -LiteralPath $patcherPath -Value $patcherContent -Encoding utf8 -NoNewline

    & python $patcherPath
    if ($LASTEXITCODE -ne 0) {
        throw "Engine-audio patcher failed with exit code $LASTEXITCODE."
    }

    & $originalVerifier -GodotBinary $GodotBinary
}
finally {
    Remove-Item -LiteralPath $packageRoot -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item -LiteralPath $packagePath -Force -ErrorAction SilentlyContinue
    New-Item -ItemType Directory -Path $packageRoot -Force | Out-Null

    $modifiedPaths = @(
        & git -C $projectRoot diff --name-only HEAD
        & git -C $projectRoot ls-files --others --exclude-standard
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Sort-Object -Unique

    foreach ($relativePath in $modifiedPaths) {
        $sourcePath = Join-Path $projectRoot $relativePath
        if (-not (Test-Path -LiteralPath $sourcePath -PathType Leaf)) {
            continue
        }
        $destinationPath = Join-Path $packageRoot $relativePath
        $destinationDirectory = Split-Path -Parent $destinationPath
        New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
        Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
    }

    $deletedPaths = @(& git -C $projectRoot diff --name-only --diff-filter=D HEAD)
    Set-Content -LiteralPath (Join-Path $packageRoot "deleted-files.txt") -Value $deletedPaths -Encoding utf8
    Set-Content -LiteralPath (Join-Path $packageRoot "source-head.txt") -Value $env:GITHUB_SHA -Encoding ascii

    Compress-Archive -Path (Join-Path $packageRoot "*") -DestinationPath $packagePath -CompressionLevel Optimal -Force
    Write-Host "Patched source artifact: $packagePath"
}

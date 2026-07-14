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
$preprocessorPath = Join-Path $env:RUNNER_TEMP "prepare-engine-audio-patcher.py"

New-Item -ItemType Directory -Path $diagnosticDirectory -Force | Out-Null

try {
    if (-not (Test-Path -LiteralPath $patcherPath -PathType Leaf)) {
        throw "Engine-audio patcher was not found: $patcherPath"
    }
    if (-not (Test-Path -LiteralPath $originalVerifier -PathType Leaf)) {
        throw "Original verification entrypoint was not found: $originalVerifier"
    }

    @'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text(encoding="utf-8")
text = text.replace(
    '\t\tpush_warning(\n\t\t\t"EngineAudioProfile ignored',
    '\t\tprint_verbose(\n\t\t\t"EngineAudioProfile ignored',
)
old = '''    replace_all(path, "pulse *= ignition_gate * startup_gate * shutdown_gate * running_gate", "pulse *= ignition_gate * startup_gate", minimum=1)
'''
new = '''    content = read(path)
    direct_gate = "pulse *= ignition_gate * startup_gate * shutdown_gate * running_gate"
    if direct_gate in content:
        write(path, content.replace(direct_gate, "pulse *= ignition_gate * startup_gate", 1))
    elif " * combustion_gate" in content:
        write(path, content.replace(" * combustion_gate", " * ignition_gate * startup_gate"))
    else:
        raise RuntimeError(f"{path}: no supported combustion-state gate was found")
'''
if old not in text:
    raise RuntimeError("Could not locate backend combustion-gate patch block")
text = text.replace(old, new, 1)
path.write_text(text, encoding="utf-8", newline="\n")
'@ | Set-Content -LiteralPath $preprocessorPath -Encoding utf8

    & python $preprocessorPath $patcherPath
    if ($LASTEXITCODE -ne 0) {
        throw "Engine-audio patch preprocessor failed with exit code $LASTEXITCODE."
    }

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

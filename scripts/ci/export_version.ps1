Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-SourceRevision {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_SHA)) {
        return $env:GITHUB_SHA.Trim().ToLowerInvariant()
    }
    try {
        $revision = (& git -C $ProjectRoot rev-parse HEAD 2>$null | Select-Object -First 1)
        if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($revision)) {
            return ([string]$revision).Trim().ToLowerInvariant()
        }
    }
    catch {
    }
    return "unknown"
}

function Get-WindowsExportVersionInfo {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot
    )

    $revision = Get-SourceRevision -ProjectRoot $ProjectRoot
    $shortRevision = if ($revision -match '^[0-9a-f]{7,}$') { $revision.Substring(0, 7) } else { "unknown" }
    $tagName = if ($env:GITHUB_REF_TYPE -eq "tag") { [string]$env:GITHUB_REF_NAME } else { "" }

    $major = 0
    $minor = 1
    $patch = 0
    $productVersion = "0.1.0-$shortRevision"
    if ($tagName -match '^v?(?<major>\d+)\.(?<minor>\d+)\.(?<patch>\d+)(?:[-+].*)?$') {
        $major = [int]$Matches["major"]
        $minor = [int]$Matches["minor"]
        $patch = [int]$Matches["patch"]
        $productVersion = "$major.$minor.$patch"
    }

    $buildNumber = 1
    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_RUN_NUMBER)) {
        $parsedBuild = 0
        if ([int]::TryParse($env:GITHUB_RUN_NUMBER, [ref]$parsedBuild)) {
            $buildNumber = [Math]::Max(1, $parsedBuild % 65536)
        }
    }
    $fileVersion = "$major.$minor.$patch.$buildNumber"

    return [pscustomobject]@{
        Revision = $revision
        ShortRevision = $shortRevision
        FileVersion = $fileVersion
        ProductVersion = $productVersion
        TestProductVersion = "$productVersion-test"
    }
}

function Set-WindowsExportPresetVersions {
    param(
        [Parameter(Mandatory = $true)][string]$PresetPath,
        [Parameter(Mandatory = $true)]$VersionInfo
    )

    if (-not (Test-Path -LiteralPath $PresetPath -PathType Leaf)) {
        throw "Export preset file was not found: $PresetPath"
    }

    $lines = [System.Collections.Generic.List[string]]::new()
    foreach ($line in Get-Content -LiteralPath $PresetPath) {
        [void]$lines.Add([string]$line)
    }

    $fileVersionUpdates = 0
    $productVersionUpdates = 0
    for ($index = 0; $index -lt $lines.Count; $index += 1) {
        if ($lines[$index] -match '^application/file_version=') {
            $lines[$index] = 'application/file_version="' + $VersionInfo.FileVersion + '"'
            $fileVersionUpdates += 1
            continue
        }
        if ($lines[$index] -match '^application/product_version=') {
            $nextVersion = if ($productVersionUpdates -eq 0) {
                $VersionInfo.ProductVersion
            }
            else {
                $VersionInfo.TestProductVersion
            }
            $lines[$index] = 'application/product_version="' + $nextVersion + '"'
            $productVersionUpdates += 1
        }
    }

    if ($fileVersionUpdates -ne 2) {
        throw "Expected two Windows file-version fields; updated $fileVersionUpdates."
    }
    if ($productVersionUpdates -ne 2) {
        throw "Expected two Windows product-version fields; updated $productVersionUpdates."
    }

    Set-Content -LiteralPath $PresetPath -Value $lines -Encoding utf8
}

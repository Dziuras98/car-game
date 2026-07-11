Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:RequiredProductionPackMarkers = @(
    "scenes/startup.tscn"
    "resources/cars/catalog.tres"
)
$script:ForbiddenProductionPackPathPrefixes = @(
    "scripts/tests/"
    "scenes/tests/"
    "scripts/ci/"
    "docs/"
)

function Get-ProductionPackContentFailures {
    param(
        [Parameter(Mandatory = $true)][string]$PackPath
    )

    $failures = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $PackPath -PathType Leaf)) {
        $failures.Add("Production pack was not found: $PackPath")
        return @($failures)
    }
    if ((Get-Item -LiteralPath $PackPath).Length -le 0) {
        $failures.Add("Production pack is empty: $PackPath")
        return @($failures)
    }

    $bytes = [System.IO.File]::ReadAllBytes($PackPath)
    $packText = [System.Text.Encoding]::GetEncoding(28591).GetString($bytes)

    foreach ($requiredMarker in $script:RequiredProductionPackMarkers) {
        if ($packText.IndexOf($requiredMarker, [System.StringComparison]::OrdinalIgnoreCase) -lt 0) {
            $failures.Add("Production pack does not expose the required path marker: $requiredMarker")
        }
    }

    foreach ($forbiddenPrefix in $script:ForbiddenProductionPackPathPrefixes) {
        if ($packText.IndexOf($forbiddenPrefix, [System.StringComparison]::OrdinalIgnoreCase) -ge 0) {
            $failures.Add("Production pack contains excluded repository content: $forbiddenPrefix")
        }
    }

    return @($failures)
}

function Assert-ProductionPackContent {
    param(
        [Parameter(Mandatory = $true)][string]$PackPath
    )

    $failures = @(Get-ProductionPackContentFailures -PackPath $PackPath)
    if ($failures.Count -gt 0) {
        $details = $failures -join [Environment]::NewLine
        throw "Production pack content validation failed with $($failures.Count) issue(s):$([Environment]::NewLine)$details"
    }

    Write-Output "Production pack content validation passed: $PackPath"
}

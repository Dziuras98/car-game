Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:GodotRuntimeErrorPatterns = @(
    '^\s*SCRIPT ERROR:',
    '^\s*ERROR:',
    '^\s*E\s+\d+:\d{2}:\d{2}(?::\d+)?\s+'
)

function Get-GodotRuntimeErrorLines {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$OutputLines
    )

    $detectedRuntimeErrors = [System.Collections.Generic.List[string]]::new()
    $escapeSequencePattern = [regex]::Escape([string][char]27) + '\[[0-9;]*[A-Za-z]'

    foreach ($lineValue in $OutputLines) {
        $line = [string]$lineValue
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $normalizedLine = [regex]::Replace($line, $escapeSequencePattern, "")
        foreach ($pattern in $script:GodotRuntimeErrorPatterns) {
            if ($normalizedLine -match $pattern) {
                $detectedRuntimeErrors.Add($normalizedLine.Trim())
                break
            }
        }
    }

    return @($detectedRuntimeErrors | Select-Object -Unique)
}

function Assert-GodotRuntimeLogContent {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$OutputLines,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [string]$DiagnosticPath = ""
    )

    $runtimeErrorLines = @(Get-GodotRuntimeErrorLines -OutputLines $OutputLines)
    if ($runtimeErrorLines.Count -eq 0) {
        return
    }

    Write-Host ""
    Write-Host "Godot emitted runtime errors during '$Label':"
    foreach ($runtimeErrorLine in $runtimeErrorLines) {
        Write-Host "  $runtimeErrorLine"
    }

    $diagnosticSuffix = ""
    if (-not [string]::IsNullOrWhiteSpace($DiagnosticPath)) {
        Write-Host "Diagnostic log: $DiagnosticPath"
        $diagnosticSuffix = " Diagnostic log: $DiagnosticPath"
    }

    throw "$Label emitted $($runtimeErrorLines.Count) Godot runtime error(s) despite exit code 0.$diagnosticSuffix"
}

function Assert-GodotRuntimeLogFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label log was not created: $Path"
    }

    $outputLines = @(Get-Content -LiteralPath $Path)
    Assert-GodotRuntimeLogContent `
        -OutputLines $outputLines `
        -Label $Label `
        -DiagnosticPath $Path
}

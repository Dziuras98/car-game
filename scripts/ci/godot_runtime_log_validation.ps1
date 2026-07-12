Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:GodotRuntimeErrorPatterns = @(
    '^\s*SCRIPT ERROR:',
    '^\s*ERROR:',
    '^\s*E\s+\d+:\d{2}:\d{2}(?::\d+)?\s+'
)
$script:GodotRuntimeWarningPatterns = @(
    '^\s*WARNING:',
    '^\s*W\s+\d+:\d{2}:\d{2}(?::\d+)?\s+'
)

function Get-GodotRuntimeLinesMatchingPatterns {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$OutputLines,

        [Parameter(Mandatory = $true)]
        [string[]]$Patterns
    )

    $detectedLines = [System.Collections.Generic.List[string]]::new()
    $escapeSequencePattern = [regex]::Escape([string][char]27) + '\[[0-9;]*[A-Za-z]'

    foreach ($lineValue in $OutputLines) {
        $line = [string]$lineValue
        if ([string]::IsNullOrWhiteSpace($line)) {
            continue
        }

        $normalizedLine = [regex]::Replace($line, $escapeSequencePattern, "")
        foreach ($pattern in $Patterns) {
            if ($normalizedLine -match $pattern) {
                $detectedLines.Add($normalizedLine.Trim())
                break
            }
        }
    }

    return @($detectedLines | Select-Object -Unique)
}

function Get-GodotRuntimeErrorLines {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$OutputLines
    )

    return @(Get-GodotRuntimeLinesMatchingPatterns `
        -OutputLines $OutputLines `
        -Patterns $script:GodotRuntimeErrorPatterns)
}

function Get-GodotRuntimeWarningLines {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$OutputLines
    )

    return @(Get-GodotRuntimeLinesMatchingPatterns `
        -OutputLines $OutputLines `
        -Patterns $script:GodotRuntimeWarningPatterns)
}

function Test-GodotRuntimeWarningAllowed {
    param(
        [Parameter(Mandatory = $true)]
        [string]$WarningLine,

        [AllowEmptyCollection()]
        [string[]]$AllowedWarningPatterns = @()
    )

    foreach ($pattern in $AllowedWarningPatterns) {
        if ($WarningLine -match $pattern) {
            return $true
        }
    }
    return $false
}

function Assert-GodotRuntimeLogContent {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$OutputLines,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [string]$DiagnosticPath = "",

        [AllowEmptyCollection()]
        [string[]]$AllowedWarningPatterns = @()
    )

    $runtimeErrorLines = @(Get-GodotRuntimeErrorLines -OutputLines $OutputLines)
    $runtimeWarningLines = @(Get-GodotRuntimeWarningLines -OutputLines $OutputLines)
    $unexpectedWarningLines = @(
        $runtimeWarningLines | Where-Object {
            -not (Test-GodotRuntimeWarningAllowed `
                -WarningLine $_ `
                -AllowedWarningPatterns $AllowedWarningPatterns)
        }
    )
    if ($runtimeErrorLines.Count -eq 0 -and $unexpectedWarningLines.Count -eq 0) {
        return
    }

    Write-Host ""
    if ($runtimeErrorLines.Count -gt 0) {
        Write-Host "Godot emitted runtime errors during '$Label':"
        foreach ($runtimeErrorLine in $runtimeErrorLines) {
            Write-Host "  $runtimeErrorLine"
        }
    }
    if ($unexpectedWarningLines.Count -gt 0) {
        Write-Host "Godot emitted unexpected runtime warnings during '$Label':"
        foreach ($runtimeWarningLine in $unexpectedWarningLines) {
            Write-Host "  $runtimeWarningLine"
        }
    }

    $diagnosticSuffix = ""
    if (-not [string]::IsNullOrWhiteSpace($DiagnosticPath)) {
        Write-Host "Diagnostic log: $DiagnosticPath"
        $diagnosticSuffix = " Diagnostic log: $DiagnosticPath"
    }

    if ($runtimeErrorLines.Count -gt 0 -and $unexpectedWarningLines.Count -gt 0) {
        throw "$Label emitted $($runtimeErrorLines.Count) Godot runtime error(s) and $($unexpectedWarningLines.Count) unexpected warning(s) despite exit code 0.$diagnosticSuffix"
    }
    if ($runtimeErrorLines.Count -gt 0) {
        throw "$Label emitted $($runtimeErrorLines.Count) Godot runtime error(s) despite exit code 0.$diagnosticSuffix"
    }
    throw "$Label emitted $($unexpectedWarningLines.Count) unexpected Godot runtime warning(s) despite exit code 0.$diagnosticSuffix"
}

function Assert-GodotRuntimeLogFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Label,

        [AllowEmptyCollection()]
        [string[]]$AllowedWarningPatterns = @()
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "$Label log was not created: $Path"
    }

    $outputLines = @(Get-Content -LiteralPath $Path)
    Assert-GodotRuntimeLogContent `
        -OutputLines $outputLines `
        -Label $Label `
        -DiagnosticPath $Path `
        -AllowedWarningPatterns $AllowedWarningPatterns
}

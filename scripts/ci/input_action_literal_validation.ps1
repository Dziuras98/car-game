Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-ProjectRelativePath {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$FullPath
    )

    return [System.IO.Path]::GetRelativePath($ProjectRoot, $FullPath).Replace('\', '/')
}

function Get-LineNumberFromIndex {
    param(
        [Parameter(Mandatory = $true)][string]$Content,
        [Parameter(Mandatory = $true)][int]$Index
    )

    if ($Index -le 0) {
        return 1
    }
    return ([regex]::Matches($Content.Substring(0, $Index), "`n")).Count + 1
}

function Get-InputActionLiteralFailures {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$ScriptsRoot,
        [string[]]$ExcludedRelativePaths = @(),
        [string[]]$ExcludedPathPrefixes = @()
    )

    $resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
    $resolvedScriptsRoot = (Resolve-Path -LiteralPath $ScriptsRoot).Path
    $excludedPathSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($excludedPath in $ExcludedRelativePaths) {
        [void]$excludedPathSet.Add($excludedPath.Replace('\', '/'))
    }

    $normalizedPrefixes = @(
        $ExcludedPathPrefixes | ForEach-Object { $_.Replace('\', '/') }
    )
    $failures = [System.Collections.Generic.List[string]]::new()
    $reportedMatches = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

    $singleActionPattern = [regex]::new(
        '(?s)\b(?:Input|InputMap|[A-Za-z_][A-Za-z0-9_]*)\s*\.\s*(?:is_action(?:_just)?_(?:pressed|released)|is_action|get_action_(?:strength|raw_strength)|action_(?:press|release)|has_action|action_[A-Za-z0-9_]+)\s*\(\s*&?"(?<action>[^"\r\n]+)"',
        [System.Text.RegularExpressions.RegexOptions]::Compiled
    )
    $multiActionPattern = [regex]::new(
        '(?s)\bInput\s*\.\s*(?:get_axis|get_vector)\s*\((?<arguments>[^)]*)\)',
        [System.Text.RegularExpressions.RegexOptions]::Compiled
    )
    $literalPattern = [regex]::new('&?"(?<action>[^"\r\n]+)"')

    foreach ($scriptFile in Get-ChildItem -LiteralPath $resolvedScriptsRoot -Filter "*.gd" -File -Recurse) {
        $relativePath = Get-ProjectRelativePath -ProjectRoot $resolvedProjectRoot -FullPath $scriptFile.FullName
        if ($excludedPathSet.Contains($relativePath)) {
            continue
        }

        $isExcludedPrefix = $false
        foreach ($prefix in $normalizedPrefixes) {
            if ($relativePath.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
                $isExcludedPrefix = $true
                break
            }
        }
        if ($isExcludedPrefix) {
            continue
        }

        $content = Get-Content -LiteralPath $scriptFile.FullName -Raw
        foreach ($match in $singleActionPattern.Matches($content)) {
            $actionName = $match.Groups['action'].Value
            $lineNumber = Get-LineNumberFromIndex -Content $content -Index $match.Index
            $key = "$relativePath`:$lineNumber`:$actionName"
            if ($reportedMatches.Add($key)) {
                $failures.Add("Raw input action literal '$actionName' is forbidden outside GameInputActions: $relativePath`:$lineNumber")
            }
        }

        foreach ($callMatch in $multiActionPattern.Matches($content)) {
            $argumentsGroup = $callMatch.Groups['arguments']
            foreach ($literalMatch in $literalPattern.Matches($argumentsGroup.Value)) {
                $actionName = $literalMatch.Groups['action'].Value
                $absoluteIndex = $argumentsGroup.Index + $literalMatch.Index
                $lineNumber = Get-LineNumberFromIndex -Content $content -Index $absoluteIndex
                $key = "$relativePath`:$lineNumber`:$actionName"
                if ($reportedMatches.Add($key)) {
                    $failures.Add("Raw input action literal '$actionName' is forbidden outside GameInputActions: $relativePath`:$lineNumber")
                }
            }
        }
    }

    return @($failures)
}

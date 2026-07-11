Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
$failures = [System.Collections.Generic.List[string]]::new()

function Add-Failure {
    param([Parameter(Mandatory = $true)][string]$Message)
    $failures.Add($Message)
}

function Get-ProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$FullPath)
    return [System.IO.Path]::GetRelativePath($projectRoot, $FullPath).Replace('\', '/')
}

function Convert-EscapedString {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Context
    )
    try {
        return [System.Text.RegularExpressions.Regex]::Unescape($Value)
    }
    catch {
        Add-Failure "Invalid escaped string in ${Context}: $Value"
        return $Value
    }
}

function Add-PoEntry {
    param(
        [Parameter(Mandatory = $true)]$Entries,
        [AllowNull()][string]$MessageId,
        [AllowNull()][string]$Translation,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )
    if ([string]::IsNullOrEmpty($MessageId)) {
        return
    }
    if ($Entries.ContainsKey($MessageId)) {
        Add-Failure "Duplicate msgid '$MessageId' in $RelativePath"
        return
    }
    $Entries.Add($MessageId, [string]$Translation)
}

function Read-PoCatalog {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $entries = [System.Collections.Generic.Dictionary[string, string]]::new(
        [System.StringComparer]::Ordinal
    )
    $fullPath = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Failure "Translation catalog is missing: $RelativePath"
        return [pscustomobject]@{ Entries = $entries }
    }

    $currentId = $null
    $currentTranslation = $null
    $activeField = $null
    $lines = @((Get-Content -LiteralPath $fullPath -Encoding UTF8)) + @('')

    foreach ($line in $lines) {
        if ($line -match '^msgid\s+"(?<value>(?:\\.|[^"])*)"\s*$') {
            Add-PoEntry -Entries $entries -MessageId $currentId -Translation $currentTranslation -RelativePath $RelativePath
            $currentId = Convert-EscapedString -Value $Matches.value -Context $RelativePath
            $currentTranslation = ''
            $activeField = 'msgid'
            continue
        }
        if ($line -match '^msgstr\s+"(?<value>(?:\\.|[^"])*)"\s*$') {
            if ($null -eq $currentId) {
                Add-Failure "msgstr appears before msgid in $RelativePath"
                continue
            }
            $currentTranslation = Convert-EscapedString -Value $Matches.value -Context $RelativePath
            $activeField = 'msgstr'
            continue
        }
        if ($line -match '^"(?<value>(?:\\.|[^"])*)"\s*$') {
            $fragment = Convert-EscapedString -Value $Matches.value -Context $RelativePath
            if ($activeField -eq 'msgid') {
                $currentId += $fragment
            }
            elseif ($activeField -eq 'msgstr') {
                $currentTranslation += $fragment
            }
            else {
                Add-Failure "Detached quoted string in $RelativePath"
            }
            continue
        }
        if ([string]::IsNullOrWhiteSpace($line)) {
            Add-PoEntry -Entries $entries -MessageId $currentId -Translation $currentTranslation -RelativePath $RelativePath
            $currentId = $null
            $currentTranslation = $null
            $activeField = $null
            continue
        }
        if ($line.StartsWith('#')) {
            continue
        }
        Add-Failure "Unsupported PO syntax in ${RelativePath}: $line"
    }

    return [pscustomobject]@{ Entries = $entries }
}

function Get-FormatTokens {
    param([Parameter(Mandatory = $true)][string]$Value)
    $tokens = [System.Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($Value, '%(?:\d+\$)?[-+0-9.]*[A-Za-z]')) {
        $tokens.Add($match.Value)
    }
    return $tokens.ToArray()
}

function Test-SequencesEqual {
    param(
        [Parameter(Mandatory = $true)][string[]]$Left,
        [Parameter(Mandatory = $true)][string[]]$Right
    )
    if ($Left.Count -ne $Right.Count) {
        return $false
    }
    for ($index = 0; $index -lt $Left.Count; $index += 1) {
        if (-not [string]::Equals($Left[$index], $Right[$index], [System.StringComparison]::Ordinal)) {
            return $false
        }
    }
    return $true
}

function Test-IsNonTranslatableUiToken {
    param([Parameter(Mandatory = $true)][string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $true
    }
    if ($Value -in @('◀', '▶', 'km/h', 'RPM', 'N', 'G-', 'G+')) {
        return $true
    }
    if ($Value -match '^\d+$') {
        return $true
    }
    $withoutFormatTokens = [regex]::Replace($Value, '%(?:\d+\$)?[-+0-9.]*[A-Za-z]', '')
    return -not [regex]::IsMatch($withoutFormatTokens, '\p{L}')
}

$projectFile = Join-Path $projectRoot 'project.godot'
if (-not (Test-Path -LiteralPath $projectFile -PathType Leaf)) {
    throw 'project.godot is missing'
}

$projectContent = Get-Content -LiteralPath $projectFile -Raw -Encoding UTF8
$translationSetting = [regex]::Match(
    $projectContent,
    '(?m)^locale/translations=PackedStringArray\((?<paths>[^\r\n]*)\)\s*$'
)
$fallbackSetting = [regex]::Match(
    $projectContent,
    '(?m)^locale/fallback="(?<locale>[^"]+)"\s*$'
)

$catalogResourcePaths = [System.Collections.Generic.List[string]]::new()
if (-not $translationSetting.Success) {
    Add-Failure 'project.godot does not define internationalization/locale/translations'
}
else {
    foreach ($pathMatch in [regex]::Matches($translationSetting.Groups['paths'].Value, '"(?<path>res://translations/[^"]+\.po)"')) {
        $catalogResourcePaths.Add($pathMatch.Groups['path'].Value)
    }
}
if ($catalogResourcePaths.Count -lt 2) {
    Add-Failure 'At least two translation catalogs must be configured'
}
if (-not $fallbackSetting.Success) {
    Add-Failure 'project.godot does not define internationalization/locale/fallback'
}

$seenCatalogPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$catalogs = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
foreach ($resourcePath in $catalogResourcePaths) {
    if (-not $seenCatalogPaths.Add($resourcePath)) {
        Add-Failure "Translation catalog is configured more than once: $resourcePath"
        continue
    }
    $relativePath = $resourcePath.Substring('res://'.Length)
    $catalogResult = Read-PoCatalog -RelativePath $relativePath
    $catalogs.Add($resourcePath, $catalogResult.Entries)
}

$baseCatalogPath = if ($catalogResourcePaths.Count -gt 0) { $catalogResourcePaths[0] } else { '' }
$baseCatalog = if ($catalogs.ContainsKey($baseCatalogPath)) { $catalogs[$baseCatalogPath] } else { $null }
if ($null -ne $baseCatalog) {
    foreach ($entry in $baseCatalog.GetEnumerator()) {
        if ([string]::IsNullOrWhiteSpace($entry.Value)) {
            Add-Failure "Empty translation for '$($entry.Key)' in $baseCatalogPath"
        }
    }

    foreach ($catalogPath in $catalogs.Keys) {
        $catalog = $catalogs[$catalogPath]
        foreach ($key in $baseCatalog.Keys) {
            if (-not $catalog.ContainsKey($key)) {
                Add-Failure "Catalog $catalogPath is missing key '$key'"
                continue
            }
            if ([string]::IsNullOrWhiteSpace($catalog[$key])) {
                Add-Failure "Empty translation for '$key' in $catalogPath"
            }
            $sourceTokens = @(Get-FormatTokens -Value $key)
            $translatedTokens = @(Get-FormatTokens -Value $catalog[$key])
            if (-not (Test-SequencesEqual -Left $sourceTokens -Right $translatedTokens)) {
                Add-Failure "Format placeholders differ for '$key' in $catalogPath"
            }
        }
        foreach ($key in $catalog.Keys) {
            if (-not $baseCatalog.ContainsKey($key)) {
                Add-Failure "Catalog $catalogPath contains key absent from $baseCatalogPath: '$key'"
            }
        }
    }

    $sourceFiles = Get-ChildItem -LiteralPath (Join-Path $projectRoot 'scripts') -Filter '*.gd' -File -Recurse
    foreach ($sourceFile in $sourceFiles) {
        $relativePath = Get-ProjectRelativePath -FullPath $sourceFile.FullName
        $sourceContent = Get-Content -LiteralPath $sourceFile.FullName -Raw -Encoding UTF8
        foreach ($match in [regex]::Matches($sourceContent, '(?<![A-Za-z0-9_])tr\(\s*&?"(?<key>(?:\\.|[^"])*)"\s*\)')) {
            $key = Convert-EscapedString -Value $match.Groups['key'].Value -Context $relativePath
            if (-not $baseCatalog.ContainsKey($key)) {
                Add-Failure "Uncatalogued tr() key '$key' in $relativePath"
            }
        }
    }

    $uiSceneRoot = Join-Path $projectRoot 'scenes/ui'
    foreach ($sceneFile in Get-ChildItem -LiteralPath $uiSceneRoot -Filter '*.tscn' -File -Recurse) {
        $relativePath = Get-ProjectRelativePath -FullPath $sceneFile.FullName
        $sceneContent = Get-Content -LiteralPath $sceneFile.FullName -Raw -Encoding UTF8
        foreach ($match in [regex]::Matches($sceneContent, '(?m)^\s*text\s*=\s*"(?<value>(?:\\.|[^"])*)"\s*$')) {
            $value = Convert-EscapedString -Value $match.Groups['value'].Value -Context $relativePath
            if (-not (Test-IsNonTranslatableUiToken -Value $value) -and -not $baseCatalog.ContainsKey($value)) {
                Add-Failure "Uncatalogued UI scene text '$value' in $relativePath"
            }
        }
    }

    foreach ($scriptRoot in @('scripts/ui', 'scripts/game', 'scripts/race')) {
        $fullScriptRoot = Join-Path $projectRoot $scriptRoot
        foreach ($scriptFile in Get-ChildItem -LiteralPath $fullScriptRoot -Filter '*.gd' -File -Recurse) {
            $relativePath = Get-ProjectRelativePath -FullPath $scriptFile.FullName
            $scriptContent = Get-Content -LiteralPath $scriptFile.FullName -Raw -Encoding UTF8
            foreach ($match in [regex]::Matches($scriptContent, '(?m)(?:\.text|\btext)\s*=\s*"(?<value>(?:\\.|[^"])*)"')) {
                $value = Convert-EscapedString -Value $match.Groups['value'].Value -Context $relativePath
                if (-not (Test-IsNonTranslatableUiToken -Value $value)) {
                    Add-Failure "Literal UI text assignment must use tr(): '$value' in $relativePath"
                }
            }
        }
    }
}

if ($failures.Count -gt 0) {
    Write-Output 'Localization validation failed:'
    foreach ($failure in $failures) {
        Write-Output "  - $failure"
    }
    throw "Localization validation failed with $($failures.Count) issue(s)."
}

Write-Output "Localization validation passed for $($catalogResourcePaths.Count) catalogs and $($baseCatalog.Count) keys."

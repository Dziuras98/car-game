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

function Read-PoCatalog {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $entries = [System.Collections.Generic.Dictionary[string, string]]::new(
        [System.StringComparer]::Ordinal
    )
    $fullPath = Join-Path $projectRoot $RelativePath
    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        Add-Failure "Translation catalog is missing: $RelativePath"
        return [pscustomobject]@{ Locale = ''; Entries = $entries }
    }

    $content = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
    $localeMatch = [regex]::Match(
        $content,
        '(?m)^"Language:\s*(?<locale>[^\\"]+)\\n"\s*$'
    )
    $locale = if ($localeMatch.Success) { $localeMatch.Groups['locale'].Value.Trim() } else { '' }
    if ([string]::IsNullOrWhiteSpace($locale)) {
        Add-Failure "Catalog does not declare a Language header: $RelativePath"
    }

    $declaredIds = [regex]::Matches($content, '(?m)^msgid\s+"(?<id>(?:\\.|[^"])*)"\s*$')
    foreach ($match in [regex]::Matches(
        $content,
        '(?ms)^msgid\s+"(?<id>(?:\\.|[^"])*)"\s*\r?\nmsgstr\s+"(?<translation>(?:\\.|[^"])*)"\s*(?=\r?\n\r?\n|\z)'
    )) {
        $messageId = Convert-EscapedString -Value $match.Groups['id'].Value -Context $RelativePath
        if ([string]::IsNullOrEmpty($messageId)) {
            continue
        }
        $translation = Convert-EscapedString -Value $match.Groups['translation'].Value -Context $RelativePath
        if ($entries.ContainsKey($messageId)) {
            Add-Failure "Duplicate msgid '$messageId' in $RelativePath"
            continue
        }
        $entries.Add($messageId, $translation)
    }

    $nonHeaderIdCount = @(
        $declaredIds |
            Where-Object { -not [string]::IsNullOrEmpty($_.Groups['id'].Value) }
    ).Count
    if ($entries.Count -ne $nonHeaderIdCount) {
        Add-Failure "Catalog contains unsupported or malformed PO entries: $RelativePath"
    }

    return [pscustomobject]@{ Locale = $locale; Entries = $entries }
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
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Left,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][string[]]$Right
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

function Assert-CataloguedValue {
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Context,
        [Parameter(Mandatory = $true)]$BaseCatalog
    )
    if (-not (Test-IsNonTranslatableUiToken -Value $Value) -and -not $BaseCatalog.ContainsKey($Value)) {
        Add-Failure "Uncatalogued UI text '$Value' in $Context"
    }
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
$fallbackLocale = if ($fallbackSetting.Success) { $fallbackSetting.Groups['locale'].Value } else { '' }
if ([string]::IsNullOrWhiteSpace($fallbackLocale)) {
    Add-Failure 'project.godot does not define internationalization/locale/fallback'
}

$seenCatalogPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$localePaths = [System.Collections.Generic.Dictionary[string, string]]::new([System.StringComparer]::Ordinal)
$catalogs = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::Ordinal)
foreach ($resourcePath in $catalogResourcePaths) {
    if (-not $seenCatalogPaths.Add($resourcePath)) {
        Add-Failure "Translation catalog is configured more than once: $resourcePath"
        continue
    }
    $relativePath = $resourcePath.Substring('res://'.Length)
    $catalogResult = Read-PoCatalog -RelativePath $relativePath
    if (-not [string]::IsNullOrWhiteSpace($catalogResult.Locale)) {
        if ($localePaths.ContainsKey($catalogResult.Locale)) {
            Add-Failure "Locale '$($catalogResult.Locale)' is declared by both $($localePaths[$catalogResult.Locale]) and $resourcePath"
        }
        else {
            $localePaths.Add($catalogResult.Locale, $resourcePath)
        }
    }
    $catalogs.Add($resourcePath, $catalogResult.Entries)
}
if (-not [string]::IsNullOrWhiteSpace($fallbackLocale) -and -not $localePaths.ContainsKey($fallbackLocale)) {
    Add-Failure "Fallback locale '$fallbackLocale' has no configured catalog"
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
                Add-Failure "Catalog $catalogPath contains key absent from ${baseCatalogPath}: '$key'"
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
            Assert-CataloguedValue -Value $value -Context $relativePath -BaseCatalog $baseCatalog
        }
    }

    $localizedResourceFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'resources/tracks') -Filter '*_definition.tres' -File) {
        $localizedResourceFiles.Add($file)
    }
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $projectRoot 'resources/cars') -Filter '*.tres' -File -Recurse) {
        if ((Get-ProjectRelativePath -FullPath $file.FullName) -match '/variants/') {
            $localizedResourceFiles.Add($file)
        }
    }
    foreach ($resourceFile in $localizedResourceFiles) {
        $relativePath = Get-ProjectRelativePath -FullPath $resourceFile.FullName
        $resourceContent = Get-Content -LiteralPath $resourceFile.FullName -Raw -Encoding UTF8
        foreach ($match in [regex]::Matches($resourceContent, '(?m)^\s*display_name\s*=\s*"(?<value>(?:\\.|[^"])*)"\s*$')) {
            $value = Convert-EscapedString -Value $match.Groups['value'].Value -Context $relativePath
            Assert-CataloguedValue -Value $value -Context $relativePath -BaseCatalog $baseCatalog
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

$baseKeyCount = if ($null -eq $baseCatalog) { 0 } else { $baseCatalog.Count }
Write-Output "Localization validation passed for $($catalogResourcePaths.Count) catalogs and $baseKeyCount keys."

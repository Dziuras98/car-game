Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Read-IniLikeSections {
    param(
        [Parameter(Mandatory = $true)][string]$Path
    )

    $sections = [ordered]@{}
    $currentSection = $null
    $lineNumber = 0

    foreach ($line in Get-Content -LiteralPath $Path) {
        $lineNumber += 1
        $trimmed = $line.Trim()
        if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith(";") -or $trimmed.StartsWith("#")) {
            continue
        }

        if ($trimmed -match '^\[(?<name>[^\]]+)\]$') {
            $currentSection = $Matches["name"]
            if ($sections.Contains($currentSection)) {
                throw "Duplicate section '$currentSection' in $Path at line $lineNumber."
            }
            $sections[$currentSection] = [ordered]@{}
            continue
        }

        if ($null -eq $currentSection) {
            continue
        }

        if ($trimmed -match '^(?<key>[^=]+?)\s*=\s*(?<value>.*)$') {
            $key = $Matches["key"].Trim()
            $sections[$currentSection][$key] = $Matches["value"].Trim()
        }
    }

    return $sections
}

function ConvertFrom-IniLikeValue {
    param(
        [AllowNull()][string]$Value
    )

    if ($null -eq $Value) {
        return $null
    }
    if ($Value.Length -ge 2 -and $Value.StartsWith('"') -and $Value.EndsWith('"')) {
        return $Value.Substring(1, $Value.Length - 2)
    }
    return $Value
}

function Get-SectionValue {
    param(
        [Parameter(Mandatory = $true)][System.Collections.IDictionary]$Section,
        [Parameter(Mandatory = $true)][string]$Key
    )

    if (-not $Section.Contains($Key)) {
        return $null
    }
    return ConvertFrom-IniLikeValue -Value ([string]$Section[$Key])
}

function Get-WindowsPlatformContractFailures {
    param(
        [Parameter(Mandatory = $true)][string]$ProjectPath,
        [Parameter(Mandatory = $true)][string]$ExportPresetsPath,
        [Parameter(Mandatory = $true)][string]$WorkflowPath
    )

    $failures = [System.Collections.Generic.List[string]]::new()
    foreach ($requiredPath in @($ProjectPath, $ExportPresetsPath, $WorkflowPath)) {
        if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
            $failures.Add("Required Windows platform contract file is missing: $requiredPath")
        }
    }
    if ($failures.Count -gt 0) {
        return @($failures)
    }

    try {
        $projectSections = Read-IniLikeSections -Path $ProjectPath
        if (-not $projectSections.Contains("rendering")) {
            $failures.Add("project.godot must define a [rendering] section.")
        }
        else {
            $driver = Get-SectionValue -Section $projectSections["rendering"] -Key "rendering_device/driver.windows"
            if ($driver -ne "d3d12") {
                $failures.Add("project.godot must use the Windows D3D12 rendering driver; received '$driver'.")
            }
        }
    }
    catch {
        $failures.Add("project.godot could not be parsed: $($_.Exception.Message)")
    }

    try {
        $exportSections = Read-IniLikeSections -Path $ExportPresetsPath
        $presetSectionNames = @(
            $exportSections.Keys |
                Where-Object { [string]$_ -match '^preset\.\d+$' } |
                Sort-Object { [int](([string]$_) -replace '^preset\.', '') }
        )
        if ($presetSectionNames.Count -ne 2) {
            $failures.Add("export_presets.cfg must define exactly two export presets; found $($presetSectionNames.Count).")
        }

        $expectedPresets = @{
            "Windows Desktop" = @{
                export_path = "build/windows/car-game.exe"
                runnable = "true"
                custom_features = ""
            }
            "Windows Test" = @{
                export_path = "build/windows-test/car-game-test.exe"
                runnable = "false"
                custom_features = "export_smoke_test"
            }
        }
        $seenPresetNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

        foreach ($sectionName in $presetSectionNames) {
            $preset = $exportSections[$sectionName]
            $presetName = Get-SectionValue -Section $preset -Key "name"
            if ([string]::IsNullOrWhiteSpace($presetName)) {
                $failures.Add("$sectionName must define a non-empty preset name.")
                continue
            }
            if (-not $seenPresetNames.Add($presetName)) {
                $failures.Add("export_presets.cfg contains duplicate preset name '$presetName'.")
            }
            if (-not $expectedPresets.ContainsKey($presetName)) {
                $failures.Add("Unexpected export preset '$presetName'; only Windows Desktop and Windows Test are allowed.")
                continue
            }

            $platform = Get-SectionValue -Section $preset -Key "platform"
            if ($platform -ne "Windows Desktop") {
                $failures.Add("Preset '$presetName' must target Windows Desktop; received '$platform'.")
            }

            $expected = $expectedPresets[$presetName]
            foreach ($key in @("export_path", "runnable", "custom_features")) {
                $actualValue = Get-SectionValue -Section $preset -Key $key
                $expectedValue = [string]$expected[$key]
                if ($actualValue -ne $expectedValue) {
                    $failures.Add("Preset '$presetName' must set $key='$expectedValue'; received '$actualValue'.")
                }
            }

            $optionsSectionName = "$sectionName.options"
            if (-not $exportSections.Contains($optionsSectionName)) {
                $failures.Add("Preset '$presetName' is missing options section [$optionsSectionName].")
                continue
            }
            $options = $exportSections[$optionsSectionName]
            $requiredOptions = @{
                "binary_format/architecture" = "x86_64"
                "texture_format/s3tc_bptc" = "true"
                "texture_format/etc2_astc" = "false"
            }
            foreach ($key in $requiredOptions.Keys) {
                $actualValue = Get-SectionValue -Section $options -Key $key
                $expectedValue = [string]$requiredOptions[$key]
                if ($actualValue -ne $expectedValue) {
                    $failures.Add("Preset '$presetName' must set $key='$expectedValue'; received '$actualValue'.")
                }
            }
        }

        foreach ($expectedName in $expectedPresets.Keys) {
            if (-not $seenPresetNames.Contains($expectedName)) {
                $failures.Add("Required export preset '$expectedName' is missing.")
            }
        }
    }
    catch {
        $failures.Add("export_presets.cfg could not be parsed: $($_.Exception.Message)")
    }

    try {
        $workflowContent = Get-Content -LiteralPath $WorkflowPath -Raw
        $runnerMatches = [regex]::Matches(
            $workflowContent,
            '(?m)^\s*runs-on:\s*(?<runner>[^\s#]+)'
        )
        if ($runnerMatches.Count -eq 0) {
            $failures.Add("The Windows workflow must define at least one runs-on entry.")
        }
        foreach ($runnerMatch in $runnerMatches) {
            $runner = $runnerMatch.Groups["runner"].Value
            if ($runner -ne "windows-2025") {
                $failures.Add("Every workflow job must use windows-2025; received '$runner'.")
            }
        }

        $requiredWorkflowPatterns = [ordered]@{
            "Windows editor archive" = '(?m)^\s*GODOT_ARCHIVE:\s+Godot_v[^\s]+_win64\.exe\.zip\s*$'
            "Windows console executable" = '(?m)^\s*GODOT_EXECUTABLE:\s+Godot_v[^\s]+_win64_console\.exe\s*$'
            "Windows release template" = 'windows_release_x86_64\.exe'
            "Windows debug template" = 'windows_debug_x86_64\.exe'
            "project verification entrypoint" = '\./scripts/ci/verify_project\.ps1'
            "Windows export entrypoint" = '\./scripts/ci/export_windows\.ps1'
        }
        foreach ($description in $requiredWorkflowPatterns.Keys) {
            if ($workflowContent -notmatch $requiredWorkflowPatterns[$description]) {
                $failures.Add("The Windows workflow is missing the required $description contract.")
            }
        }
    }
    catch {
        $failures.Add("Windows workflow could not be read: $($_.Exception.Message)")
    }

    return @($failures)
}

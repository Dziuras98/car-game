Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Get-TestScriptOwnershipFailures {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ProjectRoot,

        [Parameter(Mandatory = $true)]
        [string]$SceneTestRoot,

        [Parameter(Mandatory = $true)]
        [string]$TestScriptRoot,

        [AllowEmptyCollection()]
        [string[]]$AllowedHelpers = @()
    )

    $projectRootPath = [System.IO.Path]::GetFullPath($ProjectRoot)
    $sceneTestRootPath = [System.IO.Path]::GetFullPath($SceneTestRoot)
    $testScriptRootPath = [System.IO.Path]::GetFullPath($TestScriptRoot)
    $failures = [System.Collections.Generic.List[string]]::new()
    $referencedScripts = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    $allowedHelperSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )

    foreach ($allowedHelper in $AllowedHelpers) {
        if (-not [string]::IsNullOrWhiteSpace($allowedHelper)) {
            [void]$allowedHelperSet.Add($allowedHelper.Replace('\', '/'))
        }
    }

    if (-not (Test-Path -LiteralPath $sceneTestRootPath -PathType Container)) {
        $failures.Add("Required test scene directory is missing: $sceneTestRootPath")
    }
    else {
        foreach ($sceneFile in Get-ChildItem -LiteralPath $sceneTestRootPath -Filter "*.tscn" -File -Recurse) {
            $sceneContent = Get-Content -LiteralPath $sceneFile.FullName -Raw
            foreach ($match in [regex]::Matches($sceneContent, 'res://scripts/tests/([^"\r\n]+\.gd)')) {
                [void]$referencedScripts.Add("scripts/tests/$($match.Groups[1].Value)")
            }
        }
    }

    if (-not (Test-Path -LiteralPath $testScriptRootPath -PathType Container)) {
        $failures.Add("Required test script directory is missing: $testScriptRootPath")
        return @($failures)
    }

    foreach ($scriptFile in Get-ChildItem -LiteralPath $testScriptRootPath -Filter "*.gd" -File -Recurse) {
        $relativePath = [System.IO.Path]::GetRelativePath(
            $projectRootPath,
            $scriptFile.FullName
        ).Replace('\', '/')
        $content = Get-Content -LiteralPath $scriptFile.FullName -Raw
        $isStandaloneTest = $content -match '(?m)^\s*extends\s+SceneTree\s*$'
        $isEditorLauncher = $content -match '(?m)^\s*extends\s+EditorScript\s*$'
        $isKnownHelper = $allowedHelperSet.Contains($relativePath)
        $isSceneTest = $referencedScripts.Contains($relativePath)

        if (-not ($isStandaloneTest -or $isEditorLauncher -or $isKnownHelper -or $isSceneTest)) {
            $failures.Add("Test script is not discoverable, scene-referenced or an allowed helper: $relativePath")
        }
    }

    return @($failures)
}

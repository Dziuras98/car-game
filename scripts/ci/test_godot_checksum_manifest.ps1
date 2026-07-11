Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$manifestPath = Join-Path $PSScriptRoot "godot_4_7_sha512.txt"
$expected = [ordered]@{
    "Godot_v4.7-stable_win64.exe.zip" = "41645a908eb3181d6f2d1201ed7b6d6f095f6a23aaed8903d5d255277cc8d142814f3e6817f865b3cac142c39b8aff99280091d3bbdaa301517730b3ba0522b9"
    "Godot_v4.7-stable_export_templates.tpz" = "1035dfde4edcc2472bb0c0b9610ce3ee9302642c2b9957e9066372f9f6bb759ab250c8887551a66f0bc5f51bbd9a58bb45e33a0f29844e97615a9b1138c1120e"
}

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Pinned Godot checksum manifest is missing: $manifestPath"
}

$entries = [ordered]@{}
$lineNumber = 0
foreach ($line in Get-Content -LiteralPath $manifestPath) {
    $lineNumber += 1
    $trimmed = $line.Trim()
    if ([string]::IsNullOrWhiteSpace($trimmed) -or $trimmed.StartsWith("#")) {
        continue
    }
    if ($trimmed -notmatch '^(?<hash>[0-9a-fA-F]{128})\s+\*?(?<name>[^\s]+)$') {
        throw "Invalid checksum manifest entry at line $lineNumber."
    }
    $name = $Matches["name"]
    $hash = $Matches["hash"].ToLowerInvariant()
    if ($entries.Contains($name)) {
        throw "Duplicate checksum manifest entry for $name."
    }
    $entries[$name] = $hash
}

if ($entries.Count -ne $expected.Count) {
    throw "Pinned Godot checksum manifest must contain exactly $($expected.Count) archives; found $($entries.Count)."
}
foreach ($name in $expected.Keys) {
    if (-not $entries.Contains($name)) {
        throw "Pinned Godot checksum manifest is missing $name."
    }
    if ($entries[$name] -ne $expected[$name]) {
        throw "Pinned Godot checksum for $name does not match the reviewed 4.7-stable value."
    }
}
foreach ($name in $entries.Keys) {
    if (-not $expected.Contains($name)) {
        throw "Pinned Godot checksum manifest contains unexpected archive $name."
    }
}

Write-Host "[GODOT_CHECKSUM_MANIFEST_TEST] Passed: $($entries.Count) pinned archives"

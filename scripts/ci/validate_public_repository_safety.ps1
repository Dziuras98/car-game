param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$failures = [System.Collections.Generic.List[string]]::new()
$excludedContentPaths = @(
    "scripts/ci/validate_public_repository_safety.ps1",
    "scripts/ci/test_public_repository_safety.ps1"
)
$textExtensions = @(
    ".cfg", ".gd", ".gitattributes", ".gitignore", ".godot", ".json",
    ".md", ".po", ".ps1", ".tres", ".tscn", ".txt", ".yaml", ".yml"
)
$contentPatterns = @(
    [pscustomobject]@{ Label = "private-key header"; Pattern = '-----BEGIN (?:RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----' },
    [pscustomobject]@{ Label = "GitHub classic token"; Pattern = '\bgh[pousr]_[A-Za-z0-9]{36,255}\b' },
    [pscustomobject]@{ Label = "GitHub fine-grained token"; Pattern = '\bgithub_pat_[A-Za-z0-9_]{20,255}\b' },
    [pscustomobject]@{ Label = "AWS access key"; Pattern = '\b(?:AKIA|ASIA)[0-9A-Z]{16}\b' },
    [pscustomobject]@{ Label = "Google API key"; Pattern = '\bAIza[0-9A-Za-z_-]{35}\b' },
    [pscustomobject]@{ Label = "Slack token"; Pattern = '\bxox[baprs]-[A-Za-z0-9-]{20,255}\b' },
    [pscustomobject]@{ Label = "Windows user profile path"; Pattern = '(?i)\b[A-Z]:\\Users\\[^\\\r\n]+' },
    [pscustomobject]@{ Label = "Unix user home path"; Pattern = '(?m)(?:^|[\s"''])/home/[^/\s]+/' }
)

function Get-ProjectRelativePath {
    param([Parameter(Mandatory = $true)][string]$FullPath)
    return [System.IO.Path]::GetRelativePath($resolvedProjectRoot, $FullPath).Replace('\', '/')
}

function Test-IgnoredPath {
    param([Parameter(Mandatory = $true)][string]$RelativePath)
    return (
        $RelativePath -eq ".git" -or $RelativePath.StartsWith(".git/") -or
        $RelativePath -eq ".godot" -or $RelativePath.StartsWith(".godot/") -or
        $RelativePath -eq "build" -or $RelativePath.StartsWith("build/")
    )
}

function Test-ForbiddenFileName {
    param([Parameter(Mandatory = $true)][string]$RelativePath)

    $fileName = [System.IO.Path]::GetFileName($RelativePath)
    $lowerName = $fileName.ToLowerInvariant()
    if ($lowerName -eq ".env.example") {
        return $false
    }
    if ($lowerName -eq ".env" -or $lowerName.StartsWith(".env.")) {
        return $true
    }
    if ($lowerName -in @("id_rsa", "id_ed25519", "credentials.json")) {
        return $true
    }
    if ($lowerName -like "service-account*.json") {
        return $true
    }
    return [System.IO.Path]::GetExtension($lowerName) -in @(
        ".jks", ".key", ".keystore", ".p12", ".pem", ".pfx"
    )
}

foreach ($file in Get-ChildItem -LiteralPath $resolvedProjectRoot -File -Recurse -Force) {
    $relativePath = Get-ProjectRelativePath -FullPath $file.FullName
    if (Test-IgnoredPath -RelativePath $relativePath) {
        continue
    }

    if (Test-ForbiddenFileName -RelativePath $relativePath) {
        $failures.Add("Forbidden credential or secret file is tracked: $relativePath")
        continue
    }

    if ($excludedContentPaths -contains $relativePath) {
        continue
    }
    $extension = [System.IO.Path]::GetExtension($file.Name).ToLowerInvariant()
    if ($textExtensions -notcontains $extension) {
        continue
    }

    try {
        $content = Get-Content -LiteralPath $file.FullName -Raw
    }
    catch {
        $failures.Add("Could not inspect text file: $relativePath ($($_.Exception.Message))")
        continue
    }

    foreach ($definition in $contentPatterns) {
        if ([regex]::IsMatch($content, $definition.Pattern)) {
            $failures.Add("$relativePath contains a possible $($definition.Label).")
        }
    }
}

if ($failures.Count -gt 0) {
    foreach ($failure in $failures) {
        Write-Host "[PUBLIC_REPOSITORY_SAFETY][FAIL] $failure"
    }
    throw "Public repository safety validation failed with $($failures.Count) issue(s)."
}

Write-Host "Public repository safety validation passed."

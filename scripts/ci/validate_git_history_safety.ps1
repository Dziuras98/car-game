param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$failures = [System.Collections.Generic.List[string]]::new()
$excludedContentPaths = @(
    "scripts/ci/validate_public_repository_safety.ps1",
    "scripts/ci/test_public_repository_safety.ps1",
    "scripts/ci/validate_git_history_safety.ps1",
    "scripts/ci/test_git_history_safety.ps1"
)
$textExtensions = @(
    ".cfg", ".gd", ".json", ".md", ".po", ".ps1", ".tres", ".tscn",
    ".txt", ".yaml", ".yml"
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

function Invoke-Git {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)

    $output = @(& git @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git $($Arguments -join ' ') failed: $($output -join [Environment]::NewLine)"
    }
    return @($output | ForEach-Object { [string]$_ })
}

function Test-ForbiddenFileName {
    param([Parameter(Mandatory = $true)][string]$RepositoryPath)

    $fileName = [System.IO.Path]::GetFileName($RepositoryPath)
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

Push-Location $resolvedProjectRoot
try {
    $insideWorkTree = (Invoke-Git -Arguments @("rev-parse", "--is-inside-work-tree") | Select-Object -First 1).Trim()
    if ($insideWorkTree -ne "true") {
        throw "ProjectRoot is not a Git work tree: $resolvedProjectRoot"
    }

    $isShallow = (Invoke-Git -Arguments @("rev-parse", "--is-shallow-repository") | Select-Object -First 1).Trim()
    if ($isShallow -eq "true") {
        throw "Complete Git history is unavailable because the checkout is shallow."
    }

    $objectLines = Invoke-Git -Arguments @("-c", "core.quotePath=false", "rev-list", "--objects", "--all")
    $inspectedBlobs = 0
    foreach ($objectLine in $objectLines) {
        $match = [regex]::Match($objectLine, '^(?<sha>[0-9a-f]{40,64})(?: (?<path>.*))?$')
        if (-not $match.Success -or -not $match.Groups["path"].Success) {
            continue
        }

        $objectSha = $match.Groups["sha"].Value
        $repositoryPath = $match.Groups["path"].Value.Replace('\', '/')
        if ([string]::IsNullOrWhiteSpace($repositoryPath)) {
            continue
        }

        if (Test-ForbiddenFileName -RepositoryPath $repositoryPath) {
            $failures.Add("Forbidden credential or secret filename exists in Git history: $repositoryPath ($objectSha)")
            continue
        }

        if ($excludedContentPaths -contains $repositoryPath) {
            continue
        }
        $extension = [System.IO.Path]::GetExtension($repositoryPath).ToLowerInvariant()
        if ($textExtensions -notcontains $extension) {
            continue
        }

        $objectType = (Invoke-Git -Arguments @("cat-file", "-t", $objectSha) | Select-Object -First 1).Trim()
        if ($objectType -ne "blob") {
            continue
        }
        $objectSize = [int64]((Invoke-Git -Arguments @("cat-file", "-s", $objectSha) | Select-Object -First 1).Trim())
        if ($objectSize -gt 5MB) {
            Write-Host "[GIT_HISTORY_SAFETY][NOTICE] Skipped text-like blob larger than 5 MiB: $repositoryPath ($objectSha)"
            continue
        }

        $content = (Invoke-Git -Arguments @("cat-file", "blob", $objectSha)) -join "`n"
        $inspectedBlobs += 1
        foreach ($definition in $contentPatterns) {
            if ([regex]::IsMatch($content, $definition.Pattern)) {
                $failures.Add("$repositoryPath ($objectSha) contains a possible $($definition.Label).")
            }
        }
    }

    $emailLines = Invoke-Git -Arguments @("log", "--all", "--format=%ae%x09%ce")
    $nonNoreplyEmails = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($emailLine in $emailLines) {
        foreach ($email in $emailLine.Split("`t", [System.StringSplitOptions]::RemoveEmptyEntries)) {
            $trimmedEmail = $email.Trim()
            if (
                -not [string]::IsNullOrWhiteSpace($trimmedEmail) -and
                -not $trimmedEmail.EndsWith("@users.noreply.github.com", [System.StringComparison]::OrdinalIgnoreCase) -and
                -not $trimmedEmail.EndsWith("@noreply.github.com", [System.StringComparison]::OrdinalIgnoreCase)
            ) {
                [void]$nonNoreplyEmails.Add($trimmedEmail)
            }
        }
    }
    foreach ($email in $nonNoreplyEmails) {
        Write-Host "[GIT_HISTORY_SAFETY][NOTICE] Commit metadata exposes non-noreply email: $email"
    }

    if ($failures.Count -gt 0) {
        foreach ($failure in $failures) {
            Write-Host "[GIT_HISTORY_SAFETY][FAIL] $failure"
        }
        throw "Git history safety validation failed with $($failures.Count) issue(s)."
    }

    Write-Host "Git history safety validation passed: $inspectedBlobs text blob(s) inspected."
}
finally {
    Pop-Location
}

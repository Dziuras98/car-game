param(
    [string]$ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "../..")).Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$resolvedProjectRoot = (Resolve-Path -LiteralPath $ProjectRoot).Path
$diagnosticDirectory = Join-Path $resolvedProjectRoot "build/test-logs"
$diagnosticPath = Join-Path $diagnosticDirectory "git-history-safety.log"
$failures = [System.Collections.Generic.List[string]]::new()
$excludedContentPaths = @(
    "scripts/ci/validate_public_repository_safety.ps1",
    "scripts/ci/test_public_repository_safety.ps1",
    "scripts/ci/validate_git_history_safety.ps1",
    "scripts/ci/test_git_history_safety.ps1"
)
$contentPatterns = @(
    [pscustomobject]@{ Label = "private-key header"; Pattern = '-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----' },
    [pscustomobject]@{ Label = "GitHub classic token"; Pattern = 'gh[pousr]_[A-Za-z0-9]{36,255}' },
    [pscustomobject]@{ Label = "GitHub fine-grained token"; Pattern = 'github_pat_[A-Za-z0-9_]{20,255}' },
    [pscustomobject]@{ Label = "AWS access key"; Pattern = '(AKIA|ASIA)[0-9A-Z]{16}' },
    [pscustomobject]@{ Label = "Google API key"; Pattern = 'AIza[0-9A-Za-z_-]{35}' },
    [pscustomobject]@{ Label = "Slack token"; Pattern = 'xox[baprs]-[A-Za-z0-9-]{20,255}' },
    [pscustomobject]@{ Label = "Windows user profile path"; Pattern = '[A-Za-z]:\\Users\\' },
    [pscustomobject]@{ Label = "Unix user home path"; Pattern = '/home/[^/[:space:]]+/' }
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

function Get-MaskedEmail {
    param([Parameter(Mandatory = $true)][string]$Email)

    $separatorIndex = $Email.IndexOf('@')
    if ($separatorIndex -le 0) {
        return "***"
    }
    $localPart = $Email.Substring(0, $separatorIndex)
    $domainPart = $Email.Substring($separatorIndex + 1)
    $visiblePrefixLength = [Math]::Min(2, $localPart.Length)
    return "$($localPart.Substring(0, $visiblePrefixLength))***@$domainPart"
}

function Write-DiagnosticReport {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    New-Item -ItemType Directory -Path $diagnosticDirectory -Force | Out-Null
    Set-Content -LiteralPath $diagnosticPath -Value $Lines -Encoding utf8
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

    $historicalPaths = Invoke-Git -Arguments @(
        "-c", "core.quotePath=false", "log", "--all", "--format=", "--name-only", "--", "."
    )
    $uniqueHistoricalPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($historicalPath in $historicalPaths) {
        $normalizedPath = $historicalPath.Trim().Replace('\', '/')
        if ([string]::IsNullOrWhiteSpace($normalizedPath)) {
            continue
        }
        [void]$uniqueHistoricalPaths.Add($normalizedPath)
    }
    foreach ($historicalPath in $uniqueHistoricalPaths) {
        if (Test-ForbiddenFileName -RepositoryPath $historicalPath) {
            $failures.Add("Forbidden credential or secret filename exists in Git history: $historicalPath")
        }
    }

    $pathspecs = @(".")
    foreach ($excludedPath in $excludedContentPaths) {
        $pathspecs += ":(exclude)$excludedPath"
    }

    foreach ($definition in $contentPatterns) {
        $arguments = @(
            "-c", "core.quotePath=false", "log", "--all", "--format=commit:%H",
            "--name-only", "-G$($definition.Pattern)", "--"
        ) + $pathspecs
        $matches = @(
            Invoke-Git -Arguments $arguments |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
                Select-Object -Unique
        )
        if ($matches.Count -gt 0) {
            $evidence = ($matches | Select-Object -First 20) -join ", "
            $failures.Add("Git history contains a possible $($definition.Label): $evidence")
        }
    }

    $emailLines = Invoke-Git -Arguments @("log", "--all", "--format=%ae%x09%ce")
    $nonNoreplyEmails = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($emailLine in $emailLines) {
        foreach ($email in ($emailLine -split "`t")) {
            $trimmedEmail = $email.Trim()
            $isNoreplyEmail = (
                $trimmedEmail.EndsWith("@users.noreply.github.com", [System.StringComparison]::OrdinalIgnoreCase) -or
                $trimmedEmail.EndsWith("@noreply.github.com", [System.StringComparison]::OrdinalIgnoreCase) -or
                $trimmedEmail.Equals("noreply@github.com", [System.StringComparison]::OrdinalIgnoreCase)
            )
            if (-not [string]::IsNullOrWhiteSpace($trimmedEmail) -and -not $isNoreplyEmail) {
                [void]$nonNoreplyEmails.Add($trimmedEmail)
            }
        }
    }
    foreach ($email in $nonNoreplyEmails) {
        $failures.Add("Commit metadata exposes a non-noreply email address: $(Get-MaskedEmail -Email $email)")
    }

    if ($failures.Count -gt 0) {
        $reportLines = @(
            "Git history safety validation failed.",
            "Historical paths inspected: $($uniqueHistoricalPaths.Count)",
            "Issues: $($failures.Count)",
            ""
        ) + @($failures)
        Write-DiagnosticReport -Lines $reportLines
        foreach ($failure in $failures) {
            Write-Host "[GIT_HISTORY_SAFETY][FAIL] $failure"
        }
        throw "Git history safety validation failed with $($failures.Count) issue(s). Diagnostic log: $diagnosticPath"
    }

    $successMessage = "Git history safety validation passed: $($uniqueHistoricalPaths.Count) historical path(s) inspected."
    Write-DiagnosticReport -Lines @($successMessage)
    Write-Host $successMessage
}
finally {
    Pop-Location
}

param(
    [Parameter(Mandatory = $true)]
    [string]$ReportPath,

    [Parameter(Mandatory = $true)]
    [string]$SummaryPath,

    [ValidateRange(1, 100)]
    [int]$MaxFailures = 20
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

. (Join-Path $PSScriptRoot "junit_report.ps1")

function ConvertTo-MarkdownTableCell {
    param(
        [AllowNull()]
        [string]$Value,

        [int]$MaximumLength = 500
    )

    if ([string]::IsNullOrEmpty($Value)) {
        return ""
    }

    $normalized = $Value.Replace("`r`n", "<br>").Replace("`n", "<br>").Replace("`r", "<br>")
    $normalized = $normalized.Replace("|", "\|").Trim()
    if ($normalized.Length -gt $MaximumLength) {
        return $normalized.Substring(0, $MaximumLength - 3) + "..."
    }
    return $normalized
}

function Add-StepSummaryLines {
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Lines
    )

    $fullSummaryPath = [System.IO.Path]::GetFullPath($SummaryPath)
    $parentDirectory = [System.IO.Path]::GetDirectoryName($fullSummaryPath)
    if (-not [string]::IsNullOrWhiteSpace($parentDirectory)) {
        New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
    }

    $text = ($Lines -join [Environment]::NewLine) + [Environment]::NewLine
    [System.IO.File]::AppendAllText(
        $fullSummaryPath,
        $text,
        [System.Text.UTF8Encoding]::new($false)
    )
}

if (-not (Test-Path -LiteralPath $ReportPath -PathType Leaf)) {
    Add-StepSummaryLines -Lines @(
        "## Windows verification",
        "",
        "**Status:** Report unavailable",
        "",
        "The expected JUnit report was not created: ``$ReportPath``"
    )
    throw "JUnit report was not found for the GitHub step summary: $ReportPath"
}

try {
    $results = @(Read-JUnitReportResults -Path $ReportPath)
}
catch {
    Add-StepSummaryLines -Lines @(
        "## Windows verification",
        "",
        "**Status:** Report could not be parsed",
        "",
        (ConvertTo-MarkdownTableCell -Value $_.Exception.Message)
    )
    throw
}

if ($results.Count -eq 0) {
    Add-StepSummaryLines -Lines @(
        "## Windows verification",
        "",
        "**Status:** Invalid empty report",
        "",
        "No test cases were recorded."
    )
    throw "JUnit report contains no test cases: $ReportPath"
}

$failures = @($results | Where-Object { $_.Status -eq "failed" })
$totalDuration = 0.0
foreach ($result in $results) {
    $totalDuration += [double]$result.DurationSeconds
}

$invariantCulture = [System.Globalization.CultureInfo]::InvariantCulture
$status = if ($failures.Count -eq 0) { "Passed" } else { "Failed" }
$durationText = $totalDuration.ToString("0.000", $invariantCulture) + " s"
$summaryLines = [System.Collections.Generic.List[string]]::new()
$summaryLines.Add("## Windows verification")
$summaryLines.Add("")
$summaryLines.Add("| Result | Tests | Failures | Duration |")
$summaryLines.Add("| --- | ---: | ---: | ---: |")
$summaryLines.Add("| $status | $($results.Count) | $($failures.Count) | $durationText |")

if ($failures.Count -eq 0) {
    $summaryLines.Add("")
    $summaryLines.Add("All recorded verification cases passed.")
}
else {
    $summaryLines.Add("")
    $summaryLines.Add("### Failures")
    $summaryLines.Add("")
    $summaryLines.Add("| Test | Class | Message |")
    $summaryLines.Add("| --- | --- | --- |")

    foreach ($failure in @($failures | Select-Object -First $MaxFailures)) {
        $name = ConvertTo-MarkdownTableCell -Value ([string]$failure.Name)
        $className = ConvertTo-MarkdownTableCell -Value ([string]$failure.ClassName)
        $message = ConvertTo-MarkdownTableCell -Value ([string]$failure.Message)
        if ([string]::IsNullOrEmpty($message)) {
            $message = "No failure message was recorded."
        }
        $summaryLines.Add("| $name | $className | $message |")
    }

    if ($failures.Count -gt $MaxFailures) {
        $remaining = $failures.Count - $MaxFailures
        $summaryLines.Add("")
        $summaryLines.Add("$remaining additional failure(s) are available in the JUnit artifact.")
    }
}

Add-StepSummaryLines -Lines @($summaryLines)
Write-Host "GitHub step summary updated from JUnit report: $ReportPath"

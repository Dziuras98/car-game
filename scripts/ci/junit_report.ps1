Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function ConvertTo-JUnitXmlText {
    param([AllowNull()][string]$Value)

    if ([string]::IsNullOrEmpty($Value)) {
        return ""
    }

    $builder = [System.Text.StringBuilder]::new($Value.Length)
    foreach ($character in $Value.ToCharArray()) {
        if ([System.Xml.XmlConvert]::IsXmlChar($character)) {
            [void]$builder.Append($character)
        }
    }
    return $builder.ToString()
}

function New-JUnitTestResult {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$ClassName,
        [Parameter(Mandatory = $true)][double]$DurationSeconds,
        [Parameter(Mandatory = $true)][ValidateSet("passed", "failed")][string]$Status,
        [string]$Message = "",
        [string]$Output = ""
    )

    return [pscustomobject]@{
        Name = $Name
        ClassName = $ClassName
        DurationSeconds = [Math]::Max(0.0, $DurationSeconds)
        Status = $Status
        Message = $Message
        Output = $Output
    }
}

function Write-JUnitReport {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Results,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$SuiteName
    )

    $resultList = @($Results)
    $failureCount = @($resultList | Where-Object { $_.Status -eq "failed" }).Count
    $durationMeasure = $resultList | Measure-Object -Property DurationSeconds -Sum
    $totalDuration = if ($null -eq $durationMeasure.Sum) { 0.0 } else { [double]$durationMeasure.Sum }
    $invariantCulture = [System.Globalization.CultureInfo]::InvariantCulture
    $fullPath = [System.IO.Path]::GetFullPath($Path)
    $parentDirectory = [System.IO.Path]::GetDirectoryName($fullPath)
    if (-not [string]::IsNullOrWhiteSpace($parentDirectory)) {
        New-Item -ItemType Directory -Path $parentDirectory -Force | Out-Null
    }

    $settings = [System.Xml.XmlWriterSettings]::new()
    $settings.Encoding = [System.Text.UTF8Encoding]::new($false)
    $settings.Indent = $true
    $settings.NewLineChars = [Environment]::NewLine
    $settings.NewLineHandling = [System.Xml.NewLineHandling]::Entitize

    $writer = [System.Xml.XmlWriter]::Create($fullPath, $settings)
    try {
        $writer.WriteStartDocument()
        $writer.WriteStartElement("testsuites")
        $writer.WriteAttributeString("name", (ConvertTo-JUnitXmlText -Value $SuiteName))
        $writer.WriteAttributeString("tests", $resultList.Count.ToString($invariantCulture))
        $writer.WriteAttributeString("failures", $failureCount.ToString($invariantCulture))
        $writer.WriteAttributeString("errors", "0")
        $writer.WriteAttributeString("time", $totalDuration.ToString("0.000000", $invariantCulture))

        $writer.WriteStartElement("testsuite")
        $writer.WriteAttributeString("name", (ConvertTo-JUnitXmlText -Value $SuiteName))
        $writer.WriteAttributeString("tests", $resultList.Count.ToString($invariantCulture))
        $writer.WriteAttributeString("failures", $failureCount.ToString($invariantCulture))
        $writer.WriteAttributeString("errors", "0")
        $writer.WriteAttributeString("skipped", "0")
        $writer.WriteAttributeString("time", $totalDuration.ToString("0.000000", $invariantCulture))
        $writer.WriteAttributeString("timestamp", [DateTimeOffset]::UtcNow.ToString("O", $invariantCulture))

        foreach ($result in $resultList) {
            $writer.WriteStartElement("testcase")
            $writer.WriteAttributeString("name", (ConvertTo-JUnitXmlText -Value ([string]$result.Name)))
            $writer.WriteAttributeString("classname", (ConvertTo-JUnitXmlText -Value ([string]$result.ClassName)))
            $writer.WriteAttributeString(
                "time",
                ([double]$result.DurationSeconds).ToString("0.000000", $invariantCulture)
            )

            if ($result.Status -eq "failed") {
                $failureMessage = ConvertTo-JUnitXmlText -Value ([string]$result.Message)
                $writer.WriteStartElement("failure")
                $writer.WriteAttributeString("type", "TestFailure")
                $writer.WriteAttributeString("message", $failureMessage)
                $writer.WriteString($failureMessage)
                $writer.WriteEndElement()
            }

            $outputText = ConvertTo-JUnitXmlText -Value ([string]$result.Output)
            if (-not [string]::IsNullOrEmpty($outputText)) {
                $writer.WriteStartElement("system-out")
                $writer.WriteString($outputText)
                $writer.WriteEndElement()
            }

            $writer.WriteEndElement()
        }

        $writer.WriteEndElement()
        $writer.WriteEndElement()
        $writer.WriteEndDocument()
    }
    finally {
        $writer.Dispose()
    }

    if (-not (Test-Path -LiteralPath $fullPath -PathType Leaf)) {
        throw "JUnit report was not created: $fullPath"
    }
    if ((Get-Item -LiteralPath $fullPath).Length -le 0) {
        throw "JUnit report is empty: $fullPath"
    }
}

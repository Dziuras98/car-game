Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:PackHeaderMagic = [uint32]0x43504447
$script:PackDirectoryEncryptedFlag = [uint32]1
$script:PackFileRemovalFlag = [uint32]2
$script:SupportedPackVersions = @(2, 3, 4)
$script:MaximumPackEntryCount = 1000000
$script:MaximumPackPathLength = 1048576

$script:RequiredProductionPackMarkers = @(
    "scenes/startup.tscn"
    "resources/cars/catalog.tres"
)
$script:ForbiddenProductionPackPathPrefixes = @(
    "scripts/tests/"
    "scenes/tests/"
    "scripts/ci/"
    "docs/"
)

function Get-ProductionPackPaths {
    param(
        [Parameter(Mandatory = $true)][string]$PackPath
    )

    $stream = [System.IO.File]::Open(
        $PackPath,
        [System.IO.FileMode]::Open,
        [System.IO.FileAccess]::Read,
        [System.IO.FileShare]::Read
    )
    try {
        $reader = [System.IO.BinaryReader]::new(
            $stream,
            [System.Text.Encoding]::UTF8,
            $true
        )
        try {
            if ($stream.Length -lt 40) {
                throw "Pack is too small to contain a supported Godot PCK header."
            }

            $magic = $reader.ReadUInt32()
            if ($magic -ne $script:PackHeaderMagic) {
                throw "Pack does not begin with the Godot PCK magic header."
            }

            $version = $reader.ReadUInt32()
            if ($version -notin $script:SupportedPackVersions) {
                throw "Unsupported Godot PCK format version: $version."
            }

            [void]$reader.ReadUInt32() # Engine major.
            [void]$reader.ReadUInt32() # Engine minor.
            [void]$reader.ReadUInt32() # Engine patch.
            $packFlags = $reader.ReadUInt32()
            if (($packFlags -band $script:PackDirectoryEncryptedFlag) -ne 0) {
                throw "Encrypted PCK directories are not supported by production content validation."
            }

            [void]$reader.ReadUInt64() # File-data base; not needed for directory validation.

            if ($version -eq 2) {
                for ($reservedIndex = 0; $reservedIndex -lt 16; $reservedIndex++) {
                    [void]$reader.ReadUInt32()
                }
            }
            else {
                $directoryOffset = $reader.ReadUInt64()
                if ($directoryOffset -gt [uint64]($stream.Length - 4)) {
                    throw "PCK directory offset is outside the pack file."
                }
                $stream.Position = [int64]$directoryOffset
            }

            $fileCount = $reader.ReadUInt32()
            if ($fileCount -gt $script:MaximumPackEntryCount) {
                throw "PCK directory entry count is unreasonably large: $fileCount."
            }

            $paths = [System.Collections.Generic.List[string]]::new()
            for ($fileIndex = 0; $fileIndex -lt $fileCount; $fileIndex++) {
                if (($stream.Length - $stream.Position) -lt 4) {
                    throw "PCK directory ended before entry $fileIndex."
                }

                $pathLength = $reader.ReadUInt32()
                if ($pathLength -eq 0 -or $pathLength -gt $script:MaximumPackPathLength) {
                    throw "PCK entry $fileIndex has an invalid path length: $pathLength."
                }

                $remainingEntryBytes = [uint64]($stream.Length - $stream.Position)
                $requiredEntryBytes = [uint64]$pathLength + 36
                if ($requiredEntryBytes -gt $remainingEntryBytes) {
                    throw "PCK entry $fileIndex extends beyond the pack directory."
                }

                $pathBytes = $reader.ReadBytes([int]$pathLength)
                if ($pathBytes.Length -ne [int]$pathLength) {
                    throw "PCK entry $fileIndex path could not be read completely."
                }
                $path = [System.Text.Encoding]::UTF8.GetString($pathBytes).TrimEnd([char[]]@([char]0))

                [void]$reader.ReadUInt64() # File-data offset.
                [void]$reader.ReadUInt64() # File-data size.
                $md5 = $reader.ReadBytes(16)
                if ($md5.Length -ne 16) {
                    throw "PCK entry $fileIndex checksum could not be read completely."
                }
                $fileFlags = $reader.ReadUInt32()

                if (($fileFlags -band $script:PackFileRemovalFlag) -ne 0) {
                    continue
                }

                $normalizedPath = $path.Replace("\", "/")
                if ($normalizedPath.StartsWith("res://", [System.StringComparison]::OrdinalIgnoreCase)) {
                    $normalizedPath = $normalizedPath.Substring(6)
                }
                [void]$paths.Add($normalizedPath)
            }

            return $paths.ToArray()
        }
        finally {
            $reader.Dispose()
        }
    }
    finally {
        $stream.Dispose()
    }
}

function Get-ProductionPackContentFailures {
    param(
        [Parameter(Mandatory = $true)][string]$PackPath
    )

    $failures = [System.Collections.Generic.List[string]]::new()
    if (-not (Test-Path -LiteralPath $PackPath -PathType Leaf)) {
        [void]$failures.Add("Production pack was not found: $PackPath")
        return @($failures)
    }
    if ((Get-Item -LiteralPath $PackPath).Length -le 0) {
        [void]$failures.Add("Production pack is empty: $PackPath")
        return @($failures)
    }

    try {
        $packPaths = @(Get-ProductionPackPaths -PackPath $PackPath)
    }
    catch {
        [void]$failures.Add("Production pack directory could not be read: $($_.Exception.Message)")
        return @($failures)
    }

    $pathSet = [System.Collections.Generic.HashSet[string]]::new(
        [System.StringComparer]::OrdinalIgnoreCase
    )
    foreach ($packPath in $packPaths) {
        [void]$pathSet.Add($packPath)
    }

    foreach ($requiredMarker in $script:RequiredProductionPackMarkers) {
        $requiredCandidates = @(
            $requiredMarker
            "$requiredMarker.remap"
        )
        $requiredMarkerFound = $false
        foreach ($candidate in $requiredCandidates) {
            if ($pathSet.Contains($candidate)) {
                $requiredMarkerFound = $true
                break
            }
        }
        if (-not $requiredMarkerFound) {
            [void]$failures.Add(
                "Production pack does not expose the required resource or remap path: $requiredMarker"
            )
        }
    }

    foreach ($forbiddenPrefix in $script:ForbiddenProductionPackPathPrefixes) {
        $matchingPath = $packPaths | Where-Object {
            $_.StartsWith($forbiddenPrefix, [System.StringComparison]::OrdinalIgnoreCase)
        } | Select-Object -First 1
        if ($null -ne $matchingPath) {
            [void]$failures.Add(
                "Production pack contains excluded repository content: $forbiddenPrefix (for example: $matchingPath)"
            )
        }
    }

    return @($failures)
}

function Assert-ProductionPackContent {
    param(
        [Parameter(Mandatory = $true)][string]$PackPath
    )

    $failures = @(Get-ProductionPackContentFailures -PackPath $PackPath)
    if ($failures.Count -gt 0) {
        $details = $failures -join [Environment]::NewLine
        throw "Production pack content validation failed with $($failures.Count) issue(s):$([Environment]::NewLine)$details"
    }

    Write-Output "Production pack content validation passed: $PackPath"
}

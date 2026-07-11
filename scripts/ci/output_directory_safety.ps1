Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:ExportPathComparison = [System.StringComparison]::OrdinalIgnoreCase

function Add-TrailingDirectorySeparator {
    param([Parameter(Mandatory = $true)][string]$Path)

    $trimCharacters = [char[]]@(
        [System.IO.Path]::DirectorySeparatorChar,
        [System.IO.Path]::AltDirectorySeparatorChar
    )
    return $Path.TrimEnd($trimCharacters) + [System.IO.Path]::DirectorySeparatorChar
}

function Assert-SafeExportOutputPath {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    if ([string]::IsNullOrWhiteSpace($Path)) {
        throw "$Label output directory cannot be empty."
    }

    $fullProjectRoot = [System.IO.Path]::GetFullPath($ProjectRoot)
    $buildRoot = [System.IO.Path]::GetFullPath((Join-Path $fullProjectRoot "build"))
    $fullOutputPath = [System.IO.Path]::GetFullPath($Path)
    $buildPrefix = Add-TrailingDirectorySeparator -Path $buildRoot

    if (-not $fullOutputPath.StartsWith($buildPrefix, $script:ExportPathComparison)) {
        throw "$Label output directory must be a descendant of the repository build directory: $buildRoot"
    }
    if ($fullOutputPath.Equals($buildRoot, $script:ExportPathComparison)) {
        throw "$Label output directory cannot be the build root itself: $buildRoot"
    }

    $currentPath = $fullOutputPath
    while ($true) {
        if (Test-Path -LiteralPath $currentPath) {
            $currentItem = Get-Item -LiteralPath $currentPath -Force
            if (-not $currentItem.PSIsContainer) {
                throw "$Label output path exists but is not a directory: $currentPath"
            }
            if (($currentItem.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0) {
                throw "$Label output path cannot pass through a symbolic link or junction: $currentPath"
            }
        }

        if ($currentPath.Equals($buildRoot, $script:ExportPathComparison)) {
            break
        }

        $parentDirectory = [System.IO.Directory]::GetParent($currentPath)
        if ($null -eq $parentDirectory) {
            throw "$Label output directory could not be validated against build root: $fullOutputPath"
        }
        $currentPath = $parentDirectory.FullName
    }

    return $fullOutputPath
}

function Assert-IndependentExportOutputPaths {
    param(
        [Parameter(Mandatory = $true)][string]$FirstPath,
        [Parameter(Mandatory = $true)][string]$FirstLabel,
        [Parameter(Mandatory = $true)][string]$SecondPath,
        [Parameter(Mandatory = $true)][string]$SecondLabel
    )

    $fullFirstPath = [System.IO.Path]::GetFullPath($FirstPath)
    $fullSecondPath = [System.IO.Path]::GetFullPath($SecondPath)

    if ($fullFirstPath.Equals($fullSecondPath, $script:ExportPathComparison)) {
        throw "$FirstLabel and $SecondLabel output directories must be different."
    }

    $firstPrefix = Add-TrailingDirectorySeparator -Path $fullFirstPath
    $secondPrefix = Add-TrailingDirectorySeparator -Path $fullSecondPath
    if (
        $fullSecondPath.StartsWith($firstPrefix, $script:ExportPathComparison) -or
        $fullFirstPath.StartsWith($secondPrefix, $script:ExportPathComparison)
    ) {
        throw "$FirstLabel and $SecondLabel output directories cannot contain one another."
    }
}

function Reset-SafeExportOutputDirectory {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][string]$ProjectRoot,
        [Parameter(Mandatory = $true)][string]$Label
    )

    $safePath = Assert-SafeExportOutputPath -Path $Path -ProjectRoot $ProjectRoot -Label $Label
    New-Item -ItemType Directory -Path $safePath -Force | Out-Null
    [void](Assert-SafeExportOutputPath -Path $safePath -ProjectRoot $ProjectRoot -Label $Label)
    Get-ChildItem -LiteralPath $safePath -Force | Remove-Item -Recurse -Force
}

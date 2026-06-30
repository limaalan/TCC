param(
	[string]$MapName = 'highrise'
)

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$clientProjectDir = Join-Path $scriptDir 'Client'
$serverProjectDir = Join-Path $scriptDir 'Server'

$clientMapDir = Join-Path $clientProjectDir (Join-Path 'maps' $MapName)
$serverMapDir = Join-Path $serverProjectDir (Join-Path 'maps' $MapName)
$clientMapScenePath = Join-Path $clientMapDir ("map_{0}.tscn" -f $MapName)
$clientPlayableScenePath = Join-Path $clientMapDir 'highRisePlayableArea.tscn'
$clientUnplayableScenePath = Join-Path $clientMapDir 'highRiseUnplayableArea.tscn'
$serverMapScenePath = Join-Path $serverMapDir ("server_map_{0}.tscn" -f $MapName)

$defaultHillZoneTransform = 'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 10.519203, 7.5208964, -2.843248)'
$defaultDeathZoneTransform = 'Transform3D(1, 0, 0, 0, 1, 0, 0, 0, 1, 0, -25.984848, 0)'
$spawnPointExtResourceId = '6_spawn_point'

function Assert-PathExists {
	param(
		[string]$Path,
		[string]$Label
	)

	if (-not (Test-Path -LiteralPath $Path)) {
		throw "$Label not found: $Path"
	}
}

function Convert-ToResPath {
	param(
		[string]$ProjectDir,
		[string]$AbsolutePath
	)

	$projectRoot = [System.IO.Path]::GetFullPath($ProjectDir)
	$fullPath = [System.IO.Path]::GetFullPath($AbsolutePath)
	if (-not $fullPath.StartsWith($projectRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
		throw "Path '$fullPath' is outside project '$projectRoot'."
	}

	$relativePath = $fullPath.Substring($projectRoot.Length).TrimStart('\', '/')
	return ('res://{0}' -f ($relativePath -replace '\\', '/'))
}

function Resolve-ResPath {
	param(
		[string]$ProjectDir,
		[string]$ResPath
	)

	if (-not $ResPath.StartsWith('res://')) {
		throw "Unsupported resource path: $ResPath"
	}

	$relativePath = $ResPath.Substring(6) -replace '/', '\\'
	return Join-Path $ProjectDir $relativePath
}

function Get-ParentResPath {
	param([string]$ResPath)

	if (-not $ResPath.StartsWith('res://')) {
		throw "Unsupported resource path: $ResPath"
	}

	$lastSlash = $ResPath.LastIndexOf('/')
	if ($lastSlash -lt 6) {
		throw "Resource path has no parent directory: $ResPath"
	}

	return $ResPath.Substring(0, $lastSlash)
}

function Get-AssetPackageResPath {
	param([string]$ResPath)

	if (-not $ResPath.StartsWith('res://assets/')) {
		throw "Unsupported asset resource path: $ResPath"
	}

	$normalizedResPath = $ResPath -replace '\\', '/'
	foreach ($marker in @('/import/', '/source/')) {
		$markerIndex = $normalizedResPath.IndexOf($marker, [System.StringComparison]::OrdinalIgnoreCase)
		if ($markerIndex -ge 0) {
			return $normalizedResPath.Substring(0, $markerIndex)
		}
	}

	return Get-ParentResPath $normalizedResPath
}

function Should-SkipFile {
	param(
		[System.IO.FileInfo]$File,
		[string[]]$ExcludedNames = @()
	)

	if ($ExcludedNames -contains $File.Name) {
		return $true
	}

	$ignoredExtensions = @('.import', '.blend', '.blend1', '.uid')
	return $ignoredExtensions -contains $File.Extension.ToLowerInvariant()
}

function Ensure-ParentDirectory {
	param([string]$FilePath)

	$parentDir = Split-Path -Parent $FilePath
	if ($parentDir -and -not (Test-Path -LiteralPath $parentDir)) {
		New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
	}
}

function Copy-FilteredDirectory {
	param(
		[string]$SourceDir,
		[string]$DestinationDir,
		[string[]]$ExcludedNames = @()
	)

	Assert-PathExists $SourceDir 'Source directory'
	if (-not (Test-Path -LiteralPath $DestinationDir)) {
		New-Item -ItemType Directory -Path $DestinationDir -Force | Out-Null
	}

	$sourceRoot = [System.IO.Path]::GetFullPath($SourceDir)
	Get-ChildItem -LiteralPath $SourceDir -Recurse -File | ForEach-Object {
		if (Should-SkipFile $_ $ExcludedNames) {
			return
		}

		$sourcePath = [System.IO.Path]::GetFullPath($_.FullName)
		$relativePath = $sourcePath.Substring($sourceRoot.Length).TrimStart('\')
		$destinationPath = Join-Path $DestinationDir $relativePath
		Ensure-ParentDirectory $destinationPath
		Copy-Item -LiteralPath $sourcePath -Destination $destinationPath -Force
	}
}

function Remove-ExtResourceUidsFromSceneFiles {
	param([string]$RootDir)

	if (-not (Test-Path -LiteralPath $RootDir)) {
		return
	}

	Get-ChildItem -LiteralPath $RootDir -Recurse -File -Filter '*.tscn' | ForEach-Object {
		$content = Get-Content -LiteralPath $_.FullName -Raw
		$normalizedContent = [System.Text.RegularExpressions.Regex]::Replace(
			$content,
			'(?m)(^\[ext_resource [^\]]*?) uid="uid://[^"]+"',
			'$1'
		)

		if ($normalizedContent -ne $content) {
			$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
			[System.IO.File]::WriteAllText($_.FullName, $normalizedContent, $utf8NoBom)
		}
	}
}

function Get-ResourcePathsFromFile {
	param([string]$FilePath)

	if (-not (Test-Path -LiteralPath $FilePath)) {
		return @()
	}

	$text = Get-Content -LiteralPath $FilePath -Raw
	$matches = [System.Text.RegularExpressions.Regex]::Matches($text, 'path="(res://[^"]+)"')
	$result = New-Object System.Collections.Generic.List[string]
	foreach ($match in $matches) {
		$result.Add($match.Groups[1].Value)
	}
	return $result | Select-Object -Unique
}

function Get-NodeBlocksFromText {
	param([string]$Text)

	$blocks = New-Object System.Collections.Generic.List[string]
	$lines = [System.Text.RegularExpressions.Regex]::Split($Text, "`r?`n")
	$current = New-Object System.Text.StringBuilder

	foreach ($line in $lines) {
		if ($line -match '^\[node ' -and $current.Length -gt 0) {
			$blocks.Add($current.ToString().TrimEnd())
			$current.Clear() | Out-Null
		}

		if ($current.Length -gt 0 -or $line -match '^\[node ') {
			[void]$current.AppendLine($line)
		}
	}

	if ($current.Length -gt 0) {
		$blocks.Add($current.ToString().TrimEnd())
	}

	return $blocks
}

function Get-TransformForNode {
	param(
		[string]$Text,
		[string]$NodeName,
		[string]$FallbackTransform
	)

	foreach ($block in Get-NodeBlocksFromText $Text) {
		$header = ($block -split "`r?`n")[0]
		if ($header -notmatch ('name="{0}"' -f [System.Text.RegularExpressions.Regex]::Escape($NodeName))) {
			continue
		}

		foreach ($line in [System.Text.RegularExpressions.Regex]::Split($block, "`r?`n")) {
			if ($line -match '^transform = (.+)$') {
				return $Matches[1]
			}
		}
	}

	return $FallbackTransform
}

function Get-NormalizedSpawnBlocks {
	param([string]$ClientMapScenePath)

	$text = Get-Content -LiteralPath $ClientMapScenePath -Raw
	$spawnBlocks = New-Object System.Collections.Generic.List[string]

	foreach ($block in Get-NodeBlocksFromText $text) {
		$header = ($block -split "`r?`n")[0]
		if ($header -notmatch 'parent="SpawnPoints"') {
			continue
		}

		$lines = New-Object System.Collections.Generic.List[string]
		$scriptInjected = $false
		foreach ($line in [System.Text.RegularExpressions.Regex]::Split($block, "`r?`n")) {
			if ($line -match '^metadata/_custom_type_script = ') {
				continue
			}

			if ($line -match '^script = ExtResource\(') {
				$lines.Add(('script = ExtResource("{0}")' -f $spawnPointExtResourceId))
				$scriptInjected = $true
				continue
			}

			$lines.Add($line)
		}

		if (-not $scriptInjected) {
			$lines.Add(('script = ExtResource("{0}")' -f $spawnPointExtResourceId))
		}

		$spawnBlocks.Add(($lines -join "`r`n"))
	}

	return $spawnBlocks
}

Assert-PathExists $clientProjectDir 'Client project directory'
Assert-PathExists $serverProjectDir 'Server project directory'
Assert-PathExists $clientMapDir 'Client map directory'
Assert-PathExists $clientMapScenePath 'Client map scene'
Assert-PathExists $clientPlayableScenePath 'Client playable area scene'
Assert-PathExists $clientUnplayableScenePath 'Client unplayable area scene'

$existingServerMapText = ''
if (Test-Path -LiteralPath $serverMapScenePath) {
	$existingServerMapText = Get-Content -LiteralPath $serverMapScenePath -Raw
}

$existingHillZoneTransform = Get-TransformForNode $existingServerMapText 'HillZone' $defaultHillZoneTransform
$existingDeathZoneTransform = Get-TransformForNode $existingServerMapText 'MainDeathZone' $defaultDeathZoneTransform

if (Test-Path -LiteralPath $serverMapDir) {
	Remove-Item -LiteralPath $serverMapDir -Recurse -Force
}
New-Item -ItemType Directory -Path $serverMapDir -Force | Out-Null

Copy-FilteredDirectory $clientMapDir $serverMapDir @(("map_{0}.tscn" -f $MapName))
Remove-ExtResourceUidsFromSceneFiles $serverMapDir

$assetScenePaths = @($clientPlayableScenePath, $clientUnplayableScenePath)
$assetQueue = [System.Collections.Generic.Queue[string]]::new()
$seenAssetPaths = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$copiedAssetPackages = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($scenePath in $assetScenePaths) {
	foreach ($resPath in Get-ResourcePathsFromFile $scenePath) {
		if ($resPath.StartsWith('res://assets/')) {
			$assetQueue.Enqueue($resPath)
		}
	}
}

while ($assetQueue.Count -gt 0) {
	$resPath = $assetQueue.Dequeue()
	if (-not $seenAssetPaths.Add($resPath)) {
		continue
	}

	$sourceFilePath = Resolve-ResPath $clientProjectDir $resPath
	Assert-PathExists $sourceFilePath "Client dependency '$resPath'"

	$packageResDir = Get-AssetPackageResPath $resPath
	$packageSourceDir = Resolve-ResPath $clientProjectDir $packageResDir
	$packageDestinationDir = Resolve-ResPath $serverProjectDir $packageResDir

	if ($copiedAssetPackages.Add($packageSourceDir)) {
		if (Test-Path -LiteralPath $packageDestinationDir) {
			Remove-Item -LiteralPath $packageDestinationDir -Recurse -Force
		}
		Copy-FilteredDirectory $packageSourceDir $packageDestinationDir
		Remove-ExtResourceUidsFromSceneFiles $packageDestinationDir
	}

	$parseableExtensions = @('.tscn', '.tres', '.material', '.res')
	if ($parseableExtensions -contains ([System.IO.Path]::GetExtension($sourceFilePath).ToLowerInvariant())) {
		foreach ($nestedResPath in Get-ResourcePathsFromFile $sourceFilePath) {
			if ($nestedResPath.StartsWith('res://assets/')) {
				$assetQueue.Enqueue($nestedResPath)
			}
		}
	}
}

$spawnBlocks = Get-NormalizedSpawnBlocks $clientMapScenePath
$spawnSection = ''
if ($spawnBlocks.Count -gt 0) {
	$spawnSection = ($spawnBlocks -join "`r`n`r`n") + "`r`n`r`n"
}

$serverMapContents = @"
[gd_scene load_steps=7 format=3]

[ext_resource type="Script" path="res://shared/server_game_map.gd" id="1_server_game_map"]
[ext_resource type="PackedScene" path="res://maps/$MapName/highRisePlayableArea.tscn" id="2_playable_area"]
[ext_resource type="PackedScene" path="res://maps/$MapName/highRiseUnplayableArea.tscn" id="3_unplayable_area"]
[ext_resource type="PackedScene" path="res://platforms/death_zone.tscn" id="4_death_zone"]
[ext_resource type="PackedScene" path="res://game_modes/objectives/hill_zone.tscn" id="5_hill_zone"]
[ext_resource type="Script" path="res://player/spawn_point/player_spawn_point.gd" id="$spawnPointExtResourceId"]

[node name="Map" type="Node3D" node_paths=PackedStringArray("spawn_points_root", "pickups_root", "objectives_root", "special_platforms_root")]
script = ExtResource("1_server_game_map")
spawn_points_root = NodePath("SpawnPoints")
pickups_root = NodePath("Pickups")
objectives_root = NodePath("Objectives")
special_platforms_root = NodePath("SpecialPlatforms")

[node name="HighRisePlayableArea" parent="." instance=ExtResource("2_playable_area")]

[node name="HighRiseUnplayableArea" parent="." instance=ExtResource("3_unplayable_area")]

[node name="SpawnPoints" type="Node3D" parent="."]

${spawnSection}[node name="Pickups" type="Node3D" parent="."]

[node name="Objectives" type="Node3D" parent="."]

[node name="HillZone" parent="Objectives" instance=ExtResource("5_hill_zone")]
transform = $existingHillZoneTransform

[node name="SpecialPlatforms" type="Node3D" parent="."]

[node name="MainDeathZone" parent="SpecialPlatforms" instance=ExtResource("4_death_zone")]
transform = $existingDeathZoneTransform
"@

$utf8NoBom = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllText($serverMapScenePath, $serverMapContents.TrimEnd() + "`r`n", $utf8NoBom)

$copiedMapResPath = Convert-ToResPath $serverProjectDir $serverMapScenePath
$copiedAssetPackageList = @($copiedAssetPackages) | Sort-Object

"Generated server map: $copiedMapResPath"
"Synced map source from: $(Convert-ToResPath $clientProjectDir $clientMapDir)"
if ($copiedAssetPackageList.Count -gt 0) {
	'Synced client asset packages:'
	$copiedAssetPackageList | ForEach-Object {
		' - ' + (Convert-ToResPath $clientProjectDir $_)
	}
} else {
	'No external client asset packages were referenced by the highrise geometry scenes.'
}

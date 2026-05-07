param()

$ErrorActionPreference = 'Stop'

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$sharedPath = Join-Path $scriptDir 'shared'
$clientLinkPath = Join-Path $scriptDir 'Client\shared'
$serverLinkPath = Join-Path $scriptDir 'Server\shared'

function Assert-PathExists($path, $label) {
	if (-not (Test-Path -LiteralPath $path)) {
		throw "$label not found: $path"
	}
}

function Ensure-Junction($linkPath, $targetPath) {
	if (Test-Path -LiteralPath $linkPath) {
		$item = Get-Item -LiteralPath $linkPath -Force
		if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
			"Junction already exists: $linkPath"
			return
		}

		throw "Path already exists and is not a junction: $linkPath"
	}

	$targetFullPath = [System.IO.Path]::GetFullPath($targetPath)
	New-Item -ItemType Junction -Path $linkPath -Target $targetFullPath | Out-Null

	"Created junction: $linkPath -> $targetFullPath"
}

Assert-PathExists $sharedPath 'Shared directory'
Assert-PathExists (Join-Path $scriptDir 'Client') 'Client project directory'
Assert-PathExists (Join-Path $scriptDir 'Server') 'Server project directory'

Ensure-Junction $clientLinkPath $sharedPath
Ensure-Junction $serverLinkPath $sharedPath

'Shared links setup complete.'

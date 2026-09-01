param(
	[string]$GodotCommand = "godot",
	[string]$PythonCommand = "python",
	[switch]$RecordMetrics,
	[string]$DashboardHost = "127.0.0.1",
	[int]$DashboardPort = 8000,
	[string]$MetricsUdpHost = "127.0.0.1",
	[int]$MetricsUdpPort = 8765,
	[int]$ServerPort = 7777,
	[double]$MetricsIntervalSeconds = 1.0,
	[string]$MetricsOutputDir = "metrics-logs"
)

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$initialProjectDir = Join-Path $repoRoot "initial_project"
$clientProjectDir = Join-Path $initialProjectDir "Client"
$serverProjectDir = Join-Path $initialProjectDir "Server"
$serverMainScene = "res://game/main_game.tscn"
$dashboardEntry = Join-Path $repoRoot "metrics_dashboard\main.py"
$sharedLinksScript = Join-Path $initialProjectDir "setup_shared_links.ps1"

function Assert-PathExists($path, $label) {
	if (-not (Test-Path -LiteralPath $path)) {
		throw "$label not found: $path"
	}
}

function Assert-CommandExists($command, $label) {
	$resolved = Get-Command $command -ErrorAction SilentlyContinue
	if ($null -eq $resolved) {
		throw "$label command not found on PATH: $command"
	}
	return $resolved
}

function Resolve-GodotExecutable($commandInfo) {
	$resolvedPath = $commandInfo.Source
	$extension = [System.IO.Path]::GetExtension($resolvedPath).ToLowerInvariant()
	if ($extension -ne ".cmd" -and $extension -ne ".bat") {
		return $resolvedPath
	}

	$wrapperDir = Split-Path -Parent $resolvedPath
	$wrapperContent = Get-Content -Raw $resolvedPath
	if ($wrapperContent -match '"([^"]+_console\.exe)"') {
		$consolePath = $matches[1]
		if (Test-Path -LiteralPath $consolePath) {
			return $consolePath
		}
	}

	$consoleCandidate = Get-ChildItem -LiteralPath $wrapperDir -Filter "*_console.exe" -File -ErrorAction SilentlyContinue |
		Select-Object -First 1
	if ($null -ne $consoleCandidate) {
		return $consoleCandidate.FullName
	}

	return $resolvedPath
}

function Ensure-Junction($linkPath, $targetPath) {
	if (Test-Path -LiteralPath $linkPath) {
		$item = Get-Item -LiteralPath $linkPath -Force
		if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
			return
		}

		throw "Path already exists and is not a junction: $linkPath"
	}

	$targetFullPath = [System.IO.Path]::GetFullPath($targetPath)
	New-Item -ItemType Junction -Path $linkPath -Target $targetFullPath | Out-Null
}

function Ensure-ServerAssetsPath($serverAssetsPath, $clientAssetsPath) {
	if (Test-Path -LiteralPath $serverAssetsPath) {
		return
	}

	Ensure-Junction $serverAssetsPath $clientAssetsPath
}

function Resolve-MetricsOutputDir($basePath, $pathValue) {
	if ([System.IO.Path]::IsPathRooted($pathValue)) {
		return [System.IO.Path]::GetFullPath($pathValue)
	}

	return [System.IO.Path]::GetFullPath((Join-Path $basePath $pathValue))
}

function Convert-ToPSLiteral([string]$value) {
	return "'" + $value.Replace("'", "''") + "'"
}

function New-WindowCommand(
	[string]$windowTitle,
	[string]$workingDirectory,
	[string]$filePath,
	[string[]]$arguments
) {
	$titleLiteral = Convert-ToPSLiteral $windowTitle
	$workingDirectoryLiteral = Convert-ToPSLiteral $workingDirectory
	$filePathLiteral = Convert-ToPSLiteral $filePath
	$argumentLiterals = @($arguments | ForEach-Object { Convert-ToPSLiteral $_ }) -join ", "

	return @"
Set-Location -LiteralPath $workingDirectoryLiteral
`$Host.UI.RawUI.WindowTitle = $titleLiteral
Write-Host ""
Write-Host "Starting $windowTitle..."
Write-Host ""
try {
	& $filePathLiteral @($argumentLiterals)
	`$exitCode = `$LASTEXITCODE
	if (`$exitCode -ne 0) {
		Write-Host ""
		Write-Host "Process exited with code `$exitCode."
	}
} catch {
	Write-Host ""
	Write-Error `$_
}
"@
}

# Avoid duplicated PATH/Path entries breaking Start-Process in some PowerShell sessions.
$pathValue = [System.Environment]::GetEnvironmentVariable("Path", "Process")
[System.Environment]::SetEnvironmentVariable("PATH", $null, "Process")
[System.Environment]::SetEnvironmentVariable("Path", $pathValue, "Process")

Assert-PathExists $serverProjectDir "Godot server project"
Assert-PathExists $clientProjectDir "Godot client project"
Assert-PathExists $dashboardEntry "Metrics dashboard entrypoint"
Assert-PathExists $sharedLinksScript "Shared links script"

$godotCommandInfo = Assert-CommandExists $GodotCommand "Godot"
$godotExecutable = Resolve-GodotExecutable $godotCommandInfo
$pythonCommandInfo = Assert-CommandExists $PythonCommand "Python"
$pythonExecutable = $pythonCommandInfo.Source

& $sharedLinksScript
Ensure-ServerAssetsPath (Join-Path $serverProjectDir "assets") (Join-Path $clientProjectDir "assets")

$dashboardArgs = @(
	$dashboardEntry,
	"--udp-host=$MetricsUdpHost",
	"--udp-port=$MetricsUdpPort",
	"--http-host=$DashboardHost",
	"--http-port=$DashboardPort"
)

$godotArgs = @(
	"--path",
	$serverProjectDir,
	"--headless",
	$serverMainScene,
	"--",
	"--port=$ServerPort",
	"--stream-metrics",
	"--metrics-interval=$MetricsIntervalSeconds",
	"--metrics-stream-host=$MetricsUdpHost",
	"--metrics-stream-port=$MetricsUdpPort"
)

$metricsOutputDirResolved = Resolve-MetricsOutputDir $repoRoot $MetricsOutputDir

if ($RecordMetrics) {
	$godotArgs += "--record-metrics"
	$godotArgs += "--metrics-output-dir=$metricsOutputDirResolved"
}

$dashboardCommand = New-WindowCommand `
	-windowTitle "TCC Metrics Dashboard" `
	-workingDirectory $repoRoot `
	-filePath $pythonExecutable `
	-arguments $dashboardArgs

$serverCommand = New-WindowCommand `
	-windowTitle "TCC Godot Server" `
	-workingDirectory $repoRoot `
	-filePath $godotExecutable `
	-arguments $godotArgs

$dashboardProcess = Start-Process `
	-FilePath "powershell.exe" `
	-ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $dashboardCommand) `
	-WorkingDirectory $repoRoot `
	-WindowStyle Normal `
	-PassThru

Start-Sleep -Milliseconds 300

$serverProcess = Start-Process `
	-FilePath "powershell.exe" `
	-ArgumentList @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", $serverCommand) `
	-WorkingDirectory $repoRoot `
	-WindowStyle Normal `
	-PassThru

Write-Host ""
Write-Host "Dashboard window PID: $($dashboardProcess.Id)"
Write-Host "Server window PID: $($serverProcess.Id)"
Write-Host "Dashboard URL: http://$DashboardHost`:$DashboardPort"
Write-Host "Metrics CSV recording: $(if ($RecordMetrics) { 'enabled' } else { 'disabled' })"
if ($RecordMetrics) {
	Write-Host "Metrics CSV directory: $metricsOutputDirResolved"
}
Write-Host "Client: open the Godot editor and run initial_project/Client manually."
Write-Host ""

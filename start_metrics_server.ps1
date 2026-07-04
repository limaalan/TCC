param(
	[string]$GodotCommand = "godot",
	[string]$PythonCommand = "python",
	[switch]$RecordMetrics,
	[switch]$StreamMetrics,
	[switch]$StartDashboard,
	[string]$DashboardHost = "127.0.0.1",
	[int]$DashboardPort = 8000,
	[string]$MetricsUdpHost = "127.0.0.1",
	[int]$MetricsUdpPort = 8765,
	[int]$ServerPort = 7777,
	[double]$MetricsIntervalSeconds = 1.0
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

function New-LogPath($name) {
	$logDir = Join-Path ([System.IO.Path]::GetTempPath()) "tcc-metrics"
	New-Item -ItemType Directory -Force -Path $logDir | Out-Null
	$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
	return Join-Path $logDir "$name-$timestamp.log"
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

Assert-PathExists $serverProjectDir "Godot server project"
Assert-PathExists $sharedLinksScript "Shared links script"
Assert-PathExists $clientProjectDir "Godot client project"

if ($StartDashboard) {
	Assert-PathExists $dashboardEntry "Metrics dashboard entrypoint"
}

$godotCommandInfo = Assert-CommandExists $GodotCommand "Godot"
$godotExecutable = Resolve-GodotExecutable $godotCommandInfo
$pythonExecutable = ""

if ($StartDashboard) {
	$pythonCommandInfo = Assert-CommandExists $PythonCommand "Python"
	$pythonExecutable = $pythonCommandInfo.Source
}

& $sharedLinksScript
Ensure-ServerAssetsPath (Join-Path $serverProjectDir "assets") (Join-Path $clientProjectDir "assets")

$serverOutLog = New-LogPath "godot-server-out"
$serverErrLog = New-LogPath "godot-server-err"
$dashboardOutLog = ""
$dashboardErrLog = ""
$metricsStreamEnabled = $StreamMetrics -or $StartDashboard
$metricsEnabled = $RecordMetrics -or $metricsStreamEnabled

$godotArgs = @(
	"--path",
	$serverProjectDir,
	"--headless",
	$serverMainScene,
	"--",
	"--port=$ServerPort"
)

if ($metricsEnabled) {
	$godotArgs += "--metrics-interval=$MetricsIntervalSeconds"
}

if ($RecordMetrics) {
	$godotArgs += "--record-metrics"
}

if ($metricsStreamEnabled) {
	$godotArgs += @(
		"--stream-metrics",
		"--metrics-stream-host=$MetricsUdpHost",
		"--metrics-stream-port=$MetricsUdpPort"
	)
}

if ($StartDashboard) {
	$dashboardOutLog = New-LogPath "dashboard-out"
	$dashboardErrLog = New-LogPath "dashboard-err"

	$dashboardArgs = @(
		$dashboardEntry,
		"--udp-host=$MetricsUdpHost",
		"--udp-port=$MetricsUdpPort",
		"--http-host=$DashboardHost",
		"--http-port=$DashboardPort"
	)
}

$dashboardProcess = $null

if ($StartDashboard) {
	$dashboardProcess = Start-Process `
		-FilePath $pythonExecutable `
		-ArgumentList $dashboardArgs `
		-WorkingDirectory $repoRoot `
		-WindowStyle Hidden `
		-RedirectStandardOutput $dashboardOutLog `
		-RedirectStandardError $dashboardErrLog `
		-PassThru
}

$serverProcess = Start-Process `
	-FilePath $godotExecutable `
	-ArgumentList $godotArgs `
	-WorkingDirectory $repoRoot `
	-WindowStyle Hidden `
	-RedirectStandardOutput $serverOutLog `
	-RedirectStandardError $serverErrLog `
	-PassThru

Start-Sleep -Seconds 2

if ($StartDashboard -and $dashboardProcess -and $dashboardProcess.HasExited) {
	Write-Warning "Metrics dashboard exited early. Check log: $dashboardErrLog"
}

if ($serverProcess.HasExited) {
	throw "Godot server exited early. Check log: $serverErrLog"
}

$dashboardUrl = "http://$DashboardHost`:$DashboardPort"

Write-Host ""
Write-Host "Godot executable: $godotExecutable"
Write-Host "Godot server PID: $($serverProcess.Id)"
Write-Host "Godot stdout log: $serverOutLog"
Write-Host "Godot stderr log: $serverErrLog"
Write-Host "Metrics CSV recording: $(if ($RecordMetrics) { 'enabled' } else { 'disabled' })"
Write-Host "Metrics UDP stream: $(if ($metricsStreamEnabled) { 'enabled' } else { 'disabled' })"
if ($StartDashboard) {
	if ($dashboardProcess -and -not $dashboardProcess.HasExited) {
		Write-Host "Metrics dashboard started at: $dashboardUrl"
		Write-Host "Dashboard PID: $($dashboardProcess.Id)"
	} else {
		Write-Host "Metrics dashboard did not stay running."
	}
	Write-Host "Dashboard stdout log: $dashboardOutLog"
	Write-Host "Dashboard stderr log: $dashboardErrLog"
} else {
	Write-Host "Dashboard disabled. Start manually with:"
	Write-Host "  python metrics_dashboard/main.py --udp-host=$MetricsUdpHost --udp-port=$MetricsUdpPort --http-host=$DashboardHost --http-port=$DashboardPort"
}
Write-Host ""

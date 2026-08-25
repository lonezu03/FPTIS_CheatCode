param(
    [string]$ApiBaseUrl = "https://https-github-com-lonezu03-fptis.onrender.com/api",
    [ValidateSet("release", "debug")]
    [string]$Mode = "release"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$localFlutter = "C:\Users\anime\AppData\Local\Temp\fittrack_flutter_sdk\bin\flutter.bat"
$localAndroidSdk = Join-Path $projectRoot ".local-android-sdk"
$localPubCache = Join-Path $projectRoot ".pub-cache"

$flutterOnPath = Get-Command flutter.bat -ErrorAction SilentlyContinue
if ($flutterOnPath) {
    $flutter = $flutterOnPath.Source
} elseif (Test-Path -LiteralPath $localFlutter) {
    $flutter = $localFlutter
} else {
    throw "Flutter SDK not found. Install Flutter and add its bin directory to PATH."
}

if (Test-Path -LiteralPath $localAndroidSdk) {
    $env:ANDROID_HOME = (Resolve-Path -LiteralPath $localAndroidSdk).Path
    $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
}

New-Item -ItemType Directory -Force -Path $localPubCache | Out-Null
$env:PUB_CACHE = (Resolve-Path -LiteralPath $localPubCache).Path

if (-not $env:JAVA_HOME -and (Test-Path -LiteralPath "C:\Program Files\Java\jdk-17")) {
    $env:JAVA_HOME = "C:\Program Files\Java\jdk-17"
}

Set-Location -LiteralPath $projectRoot
Write-Host "Building FitTrack Android ($Mode)"
Write-Host "API: $ApiBaseUrl"

& $flutter pub get
if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }

& $flutter build apk "--$Mode" "--dart-define=API_BASE_URL=$ApiBaseUrl"
if ($LASTEXITCODE -ne 0) { throw "flutter build apk failed." }

$apkName = if ($Mode -eq "release") { "app-release.apk" } else { "app-debug.apk" }
$apkPath = Join-Path $projectRoot "build\app\outputs\flutter-apk\$apkName"
if (-not (Test-Path -LiteralPath $apkPath)) { throw "Build completed but APK was not found at $apkPath" }

Write-Host ""
Write-Host "APK is ready:" -ForegroundColor Green
Write-Host $apkPath -ForegroundColor Cyan

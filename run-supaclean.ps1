# Starts everything the app needs, in order: API -> tunnel -> Flutter (Chrome).
# Run from the SupaClean folder:   .\run-supaclean.ps1
# Anything already running is left alone, so it is safe to run again.

# The copy of the API to run: the develop branch (it has the order dates).
$ApiFolder  = 'C:\Users\chied\AppData\Local\Temp\wtdev\aspnet\SupaClean.WebApi'
$ApiPort    = 5238   # the "http" launch profile; the tunnel points at this port
$TunnelName = 'supaclean-api'
$TunnelUrl  = 'https://6v214f84-5238.inc1.devtunnels.ms'
$DevTunnel  = 'C:\Users\chied\AppData\Local\Microsoft\WinGet\Links\devtunnel.exe'
$AppFolder  = Join-Path $PSScriptRoot 'flutter\supaclean_app'

function Test-Url($url) {
    try { (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 15).StatusCode -eq 200 }
    catch { $false }
}

# 1. The API
$apiUp = Get-NetTCPConnection -State Listen -LocalPort $ApiPort -ErrorAction SilentlyContinue
if ($apiUp) {
    Write-Host "API already running on port $ApiPort."
} else {
    if (-not (Test-Path $ApiFolder)) { throw "API folder not found: $ApiFolder" }
    Write-Host 'Starting the API in a new window...'
    Start-Process powershell -ArgumentList '-NoExit', '-Command',
        "Set-Location '$ApiFolder'; dotnet run --launch-profile http"
    for ($i = 0; $i -lt 60 -and -not (Test-Url "http://localhost:$ApiPort/api/v1/services"); $i++) {
        Start-Sleep -Seconds 2
    }
    if (-not (Test-Url "http://localhost:$ApiPort/api/v1/services")) {
        throw 'The API did not start. Look at the API window for the error.'
    }
}

# 2. The tunnel
if (Get-Process devtunnel -ErrorAction SilentlyContinue) {
    Write-Host 'Tunnel already running.'
} else {
    Write-Host 'Starting the tunnel in a new window...'
    Start-Process powershell -ArgumentList '-NoExit', '-Command', "& '$DevTunnel' host $TunnelName"
    Start-Sleep -Seconds 8
}

# 3. Check the public address works before starting the app
if (-not (Test-Url "$TunnelUrl/api/v1/services")) {
    throw "The tunnel address does not answer: $TunnelUrl. Run '$DevTunnel show $TunnelName' to see the current address."
}
Write-Host "Server reachable at $TunnelUrl"

# 4. The app
Set-Location $AppFolder
flutter run -d chrome --web-port 5050 "--dart-define=API_BASE_URL=$TunnelUrl"

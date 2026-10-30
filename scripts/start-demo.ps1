param([switch]$SkipBuild, [switch]$OpenBrowser)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Set-Location $projectRoot
$demoDir = Join-Path $projectRoot '.local/demo'
New-Item -ItemType Directory -Force $demoDir | Out-Null
$python = Join-Path $projectRoot '.tools/postgres/pgsql/pgAdmin 4/python/python.exe'
if (-not (Test-Path $python)) { $python = (Get-Command python -ErrorAction Stop).Source }
$pg = Join-Path $projectRoot '.tools/postgres/pgsql/bin'
if (-not (Test-Path $pg)) { throw 'PostgreSQL tools not found. See docs/DEMO.md for dependencies.' }
& $python -c 'import psycopg, bcrypt; from PIL import Image'
if ($LASTEXITCODE -ne 0) { throw 'Python requires psycopg, bcrypt and Pillow; see docs/DEMO.md.' }
$cluster = Join-Path $projectRoot '.local/advanced-pgdata'
if (-not (Test-Path $cluster)) { throw 'Dedicated local PostgreSQL cluster not found. This script never uses a production database.' }
& "$pg/pg_ctl.exe" status -D $cluster *> $null
if ($LASTEXITCODE -ne 0) {
    & "$pg/pg_ctl.exe" start -D $cluster -l (Join-Path $projectRoot '.local/advanced-postgres.log') -o '-h 127.0.0.1 -p 55433' -w
    if ($LASTEXITCODE -ne 0) { throw 'Cannot start the dedicated local PostgreSQL cluster.' }
}
$exists = & "$pg/psql.exe" -X -h 127.0.0.1 -p 55433 -U postgres -d postgres --no-password -At -c "SELECT 1 FROM pg_database WHERE datname='thoxay_defense_demo'"
if ($LASTEXITCODE -ne 0) { throw 'Cannot inspect local demo database.' }
if ($exists -ne '1') {
    & "$pg/createdb.exe" -h 127.0.0.1 -p 55433 -U postgres --no-password thoxay_defense_demo
    if ($LASTEXITCODE -ne 0) { throw 'Cannot create local demo database.' }
}
$buildJar = Join-Path $projectRoot '.local/advanced-target/tho-xay-1.0.0.jar'
$jar = Join-Path $demoDir 'backend.jar'
if (-not $SkipBuild) {
    & ./mvnw.cmd -B '-Dthoxay.build.directory=.local/advanced-target' -DskipTests package *> "$demoDir/build-backend.log"
    if ($LASTEXITCODE -ne 0) { throw 'Demo Backend build failed.' }
    Push-Location mobile_app
    try {
        $webOutput=Join-Path $demoDir 'web'
        New-Item -ItemType Directory -Force (Join-Path $webOutput 'assets/shaders') | Out-Null
        & ../.tools/flutter/bin/flutter.bat build web --release --no-wasm-dry-run '--dart-define=API_BASE_URL=http://127.0.0.1:18083' "--output=$webOutput" *> "$demoDir/build-web.log"
        if ($LASTEXITCODE -ne 0) { throw 'Demo Web build failed.' }
    } finally { Pop-Location }
}
if (-not (Test-Path $buildJar) -or -not (Test-Path "$demoDir/web/index.html")) { throw 'Build outputs missing. Run without -SkipBuild.' }
function Occupied([int]$port) {
    $client = New-Object Net.Sockets.TcpClient
    try { return ($client.ConnectAsync('127.0.0.1',$port).Wait(500) -and $client.Connected) } catch { return $false } finally { $client.Dispose() }
}
if ((Occupied 18083) -or (Occupied 3008)) { throw 'Demo port 18083 or 3008 is already occupied. Existing services were left running.' }
Copy-Item -LiteralPath $buildJar -Destination $jar
$settings = @{ DB_URL='jdbc:postgresql://127.0.0.1:55433/thoxay_defense_demo'; DB_USERNAME='postgres'; DB_PASSWORD='postgres'; CORS_ORIGINS='http://127.0.0.1:3008'; APP_FCM_ENABLED='false'; LOGGING_LEVEL_ROOT='WARN' }
$bytes = New-Object byte[] 48
$rng = [Security.Cryptography.RandomNumberGenerator]::Create()
try { $rng.GetBytes($bytes) } finally { $rng.Dispose() }
$settings.JWT_SECRET = [Convert]::ToBase64String($bytes)
$previous = @{}; $backend = $null; $web = $null; $success = $false
try {
    foreach ($key in $settings.Keys) { $previous[$key]=[Environment]::GetEnvironmentVariable($key,'Process'); [Environment]::SetEnvironmentVariable($key,$settings[$key],'Process') }
    $backend = Start-Process -FilePath (Get-Command java).Source -ArgumentList @('-jar',('"'+$jar+'"'),'--spring.profiles.active=prod','--server.address=127.0.0.1','--server.port=18083','--server.servlet.session.cookie.secure=false','--spring.config.import=optional:classpath:/demo-no-local.properties') -WorkingDirectory $projectRoot -WindowStyle Hidden -RedirectStandardOutput "$demoDir/backend.log" -RedirectStandardError "$demoDir/backend-error.log" -PassThru
    foreach ($key in $previous.Keys) { [Environment]::SetEnvironmentVariable($key,$previous[$key],'Process') }
    $ready=$false
    for($i=0;$i -lt 240;$i++) {
        $backend.Refresh(); if($backend.HasExited) { throw 'Demo Backend exited; inspect .local/demo/backend.log.' }
        try { if ((Invoke-RestMethod 'http://127.0.0.1:18083/health' -TimeoutSec 2).status -eq 'UP') { $ready=$true; break } } catch { }
        Start-Sleep -Milliseconds 500
    }
    if(-not $ready) { throw 'Demo Backend readiness timeout.' }
    & $python scripts/demo_seed.py
    if($LASTEXITCODE -ne 0) { throw 'Demo seed refused or failed; transaction was rolled back.' }
    $node=(Get-Command node).Source
    $web=Start-Process -FilePath $node -ArgumentList @('scripts/serve-web.cjs',('"'+(Join-Path $demoDir 'web')+'"'),'3008') -WorkingDirectory $projectRoot -WindowStyle Hidden -RedirectStandardOutput "$demoDir/web.log" -RedirectStandardError "$demoDir/web-error.log" -PassThru
    @{backendPid=$backend.Id;webPid=$web.Id;jar=$jar;webRoot=(Join-Path $demoDir 'web')} | ConvertTo-Json | Set-Content -Encoding UTF8 "$demoDir/processes.json"
    $success=$true
    Write-Output 'Demo Web: http://127.0.0.1:3008'
    Write-Output 'Demo Admin: http://127.0.0.1:18083/admin/login'
    Write-Output 'Local credentials: .local/demo/access.md (never commit this file)'
    if($OpenBrowser) { Start-Process 'http://127.0.0.1:3008' }
} finally {
    foreach ($key in $previous.Keys) { [Environment]::SetEnvironmentVariable($key,$previous[$key],'Process') }
    if(-not $success) {
        foreach($process in @($backend,$web)) {
            if($null -ne $process) {
                $actual=Get-CimInstance Win32_Process -Filter "ProcessId=$($process.Id)" -ErrorAction SilentlyContinue
                if($actual -and ($actual.CommandLine.Contains($jar) -or $actual.CommandLine.Contains('scripts/serve-web.cjs'))) { Stop-Process -Id $process.Id }
            }
        }
    }
}

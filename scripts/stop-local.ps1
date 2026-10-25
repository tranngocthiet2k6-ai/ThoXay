$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$stateFile = Join-Path $projectRoot '.local\processes.json'
if (-not (Test-Path -LiteralPath $stateFile)) { Write-Host 'No managed local application processes.'; return }
$state = Get-Content -Raw -LiteralPath $stateFile | ConvertFrom-Json
foreach ($kind in @('frontend', 'backend')) {
    $processId = $state.$kind
    if (-not $processId) { continue }
    $process = Get-CimInstance Win32_Process -Filter "ProcessId = $([int]$processId)" -ErrorAction SilentlyContinue
    if (-not $process) { continue }
    $expectedFile = if ($kind -eq 'backend') { Join-Path $projectRoot 'target\tho-xay-1.0.0.jar' } else { Join-Path $PSScriptRoot 'serve-web.cjs' }
    if ($process.CommandLine -and $process.CommandLine.Contains($expectedFile)) {
        Stop-Process -Id ([int]$processId)
        Write-Host "Stopped project $kind process $processId."
    } else { Write-Warning "Process $processId is not a matching project process; left running." }
}
Remove-Item -LiteralPath $stateFile
Write-Host 'PostgreSQL is left running so mvnw spring-boot:run can reconnect.'

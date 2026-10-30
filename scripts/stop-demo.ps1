$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$statePath=Join-Path $projectRoot '.local/demo/processes.json'
if(-not (Test-Path $statePath)) { Write-Output 'No owned demo process record.'; exit 0 }
$state=Get-Content $statePath -Raw | ConvertFrom-Json
foreach($item in @(@{id=$state.backendPid;match=$state.jar;port='18083'},@{id=$state.webPid;match=$state.webRoot;port='3008'})) {
    $actual=Get-CimInstance Win32_Process -Filter "ProcessId=$($item.id)" -ErrorAction SilentlyContinue
    if($actual -and $actual.CommandLine.Contains($item.match) -and $actual.CommandLine.Contains($item.port)) { Stop-Process -Id $item.id; Write-Output "Stopped owned demo process $($item.id)." }
}
# Keep the database and access file. Never stop PostgreSQL used by other tasks.

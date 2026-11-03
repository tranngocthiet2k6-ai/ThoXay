# Manual entry point only. Never call from app builds, tests, CI/CD or Git hooks.
# Run only after the user explicitly requests the report/defense pack again:
#   .\scripts\rebuild-defense.ps1 -Rebuild
# Requires a migrated local PostgreSQL database, the existing report Python/Node
# dependencies, and Microsoft Word/PowerPoint. Review report facts after app changes.
param([switch]$Rebuild, [switch]$RestoreOnly, [switch]$UseCapturedScreens)
$ErrorActionPreference = 'Stop'
if (-not $Rebuild) {
    Write-Output 'Report generation is paused. Explicit manual command: .\scripts\rebuild-defense.ps1 -Rebuild'
    return
}
$projectRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$sourceCommit = 'ed8260723cae82f3faacf9d443b50daf93dde50e'
$inputs = @(
    'docs/BAO_CAO_DO_AN.md',
    'docs/KICH_BAN_DEMO_VA_HOI_DAP.md',
    'docs/BAN_DO_MO_CODE_NHANH.md',
    'docs/TAI_KHOAN_VA_LINK_DEMO.md',
    'docs/PROJECT_INVENTORY.json',
    'docs/diagrams',
    'docs/figma_screens',
    '00_BAO_VE_DO_AN/README.md',
    '00_BAO_VE_DO_AN/HUONG_DAN_WORKSPACE.md',
    'ThoXay-BaoVe.code-workspace'
)
$python = $env:THOXAY_REPORT_PYTHON
if (-not $python) { $python = Join-Path $projectRoot '.tools/postgres/pgsql/pgAdmin 4/python/python.exe' }
if (-not (Test-Path -LiteralPath $python -PathType Leaf)) { throw 'Set THOXAY_REPORT_PYTHON to the Python executable with the report dependencies.' }
$null = Get-Command node -ErrorAction Stop
$null = Get-Command git -ErrorAction Stop
function Invoke-ReportStep([string]$program, [string[]]$arguments) {
    & $program @arguments
    if ($LASTEXITCODE -ne 0) { throw "Manual report step failed: $program $($arguments -join ' ')" }
}
Push-Location $projectRoot
try {
    # Git retains the removed source material; do not keep report backups in docs.
    # Restore only missing inputs, preserving any later edits made by the user.
    $tempRoot = Join-Path $projectRoot ('.local/report-restore/'+[Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null
    $archive = Join-Path $tempRoot 'inputs.zip'
    Invoke-ReportStep 'git' (@('archive','--format=zip',('--output='+$archive),$sourceCommit,'--')+$inputs)
    Expand-Archive -LiteralPath $archive -DestinationPath (Join-Path $tempRoot 'source')
    $restoreRoot = Join-Path $tempRoot 'source'
    foreach ($file in Get-ChildItem -LiteralPath $restoreRoot -Recurse -File) {
        $relative = $file.FullName.Substring($restoreRoot.Length+1)
        $destination = Join-Path $projectRoot $relative
        if (-not (Test-Path -LiteralPath $destination)) {
            New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
            Copy-Item -LiteralPath $file.FullName -Destination $destination
        }
    }
    New-Item -ItemType Directory -Path '.local/final-delivery' -Force | Out-Null
    if ($RestoreOnly) { Write-Output 'Report source inputs restored; no document was built.'; return }
    if (-not $UseCapturedScreens) {
        Invoke-ReportStep 'node' @('scripts/capture-commercial-ui.mjs','--publish')
    }
    Invoke-ReportStep $python @('scripts/prepare-defense-branding.py')
    Invoke-ReportStep $python @('scripts/report_inventory.py')
    Invoke-ReportStep $python @('scripts/generate_report.py')
    Invoke-ReportStep 'node' @('scripts/render-report-diagrams.mjs')
    Invoke-ReportStep $python @('scripts/export-report-docx.py')
    Invoke-ReportStep 'powershell' @('-NoProfile','-File','scripts/render-office.ps1','-InputFile','docs/BAO_CAO_DO_AN.docx','-OutputDirectory','.local/manual-report-render','-UpdateFields')
    Invoke-ReportStep $python @('scripts/build-defense-slides.py')
    Invoke-ReportStep 'powershell' @('-NoProfile','-File','scripts/finalize-defense-slides.ps1')
    Invoke-ReportStep $python @('scripts/validate-report.py')
    Invoke-ReportStep $python @('scripts/validate-defense-slides.py')
    Invoke-ReportStep 'powershell' @('-NoProfile','-File','scripts/prepare-defense-workspace.ps1')
    Write-Output 'Manual report and defense pack rebuilt. Review all content and rendered pages before use.'
} finally {
    Pop-Location
}

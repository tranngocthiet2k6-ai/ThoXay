$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$manifestPath = Join-Path $projectRoot '00_BAO_VE_DO_AN/THAM_CHIEU.json'
$previous = @{}
if (Test-Path -LiteralPath $manifestPath) {
    $old = Get-Content -LiteralPath $manifestPath -Raw -Encoding UTF8 | ConvertFrom-Json
    foreach ($copy in $old.copies) { $previous[$copy.destination] = $copy.sha256 }
}
# Recognize the existing, verified defense copies when upgrading their numbering.
$renamed = @{
    '00_BAO_VE_DO_AN/BAO_CAO_DO_AN.docx'='00_BAO_VE_DO_AN/01_BAO_CAO_DO_AN.docx'
    '00_BAO_VE_DO_AN/SLIDE_BAO_VE_DO_AN.pptx'='00_BAO_VE_DO_AN/02_SLIDE_BAO_VE_DO_AN.pptx'
    '00_BAO_VE_DO_AN/KICH_BAN_DEMO_VA_HOI_DAP.md'='00_BAO_VE_DO_AN/04_KICH_BAN_VA_20_CAU_HOI_DAP.md'
}
foreach ($oldPath in $renamed.Keys) {
    if ($previous.ContainsKey($oldPath)) { $previous[$renamed[$oldPath]]=$previous[$oldPath] }
}
$copies = @(
    @{ source='docs/BAO_CAO_DO_AN.docx'; destination='00_BAO_VE_DO_AN/01_BAO_CAO_DO_AN.docx' },
    @{ source='docs/SLIDE_BAO_VE_DO_AN.pptx'; destination='00_BAO_VE_DO_AN/02_SLIDE_BAO_VE_DO_AN.pptx' },
    @{ source='docs/TAI_KHOAN_VA_LINK_DEMO.md'; destination='00_BAO_VE_DO_AN/03_TAI_KHOAN_VA_LINK_DEMO.md' },
    @{ source='docs/KICH_BAN_DEMO_VA_HOI_DAP.md'; destination='00_BAO_VE_DO_AN/04_KICH_BAN_VA_20_CAU_HOI_DAP.md' },
    @{ source='docs/BAN_DO_MO_CODE_NHANH.md'; destination='00_BAO_VE_DO_AN/05_BAN_DO_MO_CODE_NHANH.md' },
    @{ source='schema.sql'; destination='migrations/tham_chieu/schema.sql' },
    @{ source='render.yaml'; destination='cloud_deploy/render.yaml' },
    @{ source='Dockerfile'; destination='cloud_deploy/Dockerfile' },
    @{ source='vercel.json'; destination='cloud_deploy/vercel.json' }
)
Get-ChildItem -LiteralPath (Join-Path $projectRoot 'docs/figma_screens') -Filter '*.png' -File | Sort-Object Name | ForEach-Object {
    $copies += @{ source=('docs/figma_screens/'+$_.Name); destination=('00_BAO_VE_DO_AN/06_ANH_THIET_KE_FIGMA/'+$_.Name) }
}
Get-ChildItem -LiteralPath (Join-Path $projectRoot '.github/workflows') -File | Sort-Object Name | ForEach-Object {
    $copies += @{ source=('.github/workflows/'+$_.Name); destination=('cloud_deploy/.github/workflows/'+$_.Name) }
}
function Inside-Project([string]$relative) {
    $absolute = [IO.Path]::GetFullPath((Join-Path $projectRoot $relative))
    if (-not $absolute.StartsWith($projectRoot+[IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
        throw "Path outside project: $relative"
    }
    return $absolute
}
# Preflight every copy before writing anything. Never overwrite an edited reference.
foreach ($copy in $copies) {
    $source = Inside-Project $copy.source
    $destination = Inside-Project $copy.destination
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { throw "Source missing: $($copy.source)" }
    $copy.sha256 = (Get-FileHash -LiteralPath $source -Algorithm SHA256).Hash.ToLowerInvariant()
    if (Test-Path -LiteralPath $destination) {
        $actual = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $copy.sha256 -and $actual -ne $previous[$copy.destination]) {
            throw "Reference was edited locally; left untouched: $($copy.destination)"
        }
    }
}
$links = @(
    @{ link='kiem_thu/Backend'; target='src/test' },
    @{ link='kiem_thu/Flutter'; target='mobile_app/test' }
)
foreach ($link in $links) {
    $path = Inside-Project $link.link
    $target = Inside-Project $link.target
    if (-not (Test-Path -LiteralPath $target -PathType Container)) { throw "Test folder missing: $($link.target)" }
    $existing = Get-Item -LiteralPath $path -Force -ErrorAction SilentlyContinue
    if ($existing) {
        if ($existing.LinkType -ne 'Junction' -or
            -not [string]::Equals([IO.Path]::GetFullPath([string]@($existing.Target)[0]), $target, [StringComparison]::OrdinalIgnoreCase)) {
            throw "Unexpected existing path; no overwrite or delete: $($link.link)"
        }
    }
}
foreach ($copy in $copies) {
    $destination = Inside-Project $copy.destination
    New-Item -ItemType Directory -Path (Split-Path $destination -Parent) -Force | Out-Null
    Copy-Item -LiteralPath (Inside-Project $copy.source) -Destination $destination
}
foreach ($link in $links) {
    $path = Inside-Project $link.link
    if (-not (Test-Path -LiteralPath $path)) {
        New-Item -ItemType Directory -Path (Split-Path $path -Parent) -Force | Out-Null
        New-Item -ItemType Junction -Path $path -Target (Inside-Project $link.target) | Out-Null
    }
}
$manifest = [ordered]@{
    description='Byte-identical presentation references. Edit original source files, then run this script again.'
    copies=@($copies | ForEach-Object { [ordered]@{source=$_.source; destination=$_.destination; sha256=$_.sha256} })
    testLinks=@($links | ForEach-Object { [ordered]@{link=$_.link; target=$_.target} })
}
$json = $manifest | ConvertTo-Json -Depth 5
[IO.File]::WriteAllText($manifestPath, $json+"`n", [Text.UTF8Encoding]::new($false))
Write-Output "Defense workspace ready: 6 Explorer sections, $($copies.Count) reference copies and 2 local test junctions."
Write-Output 'No original source folder was moved or renamed. No password was copied.'

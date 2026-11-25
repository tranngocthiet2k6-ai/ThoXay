[CmdletBinding()]
param(
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9.-]*$')][string]$Server,
    [Parameter(Mandatory)][ValidatePattern('^[a-zA-Z0-9][a-zA-Z0-9.-]*\.[a-zA-Z0-9.-]+$')][string]$ApiDomain,
    [Parameter(Mandatory)][string]$IdentityFile,
    [ValidatePattern('^https://[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$')][string]$WebOrigin = 'https://thoxay.vercel.app',
    [ValidateSet('existing', 'new')][string]$DatabaseMode = 'existing',
    [string]$RuntimeEnvironmentFile,
    [switch]$PrepareOnly
)
$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path $PSScriptRoot -Parent
Push-Location $repoRoot
try {
    if ($RuntimeEnvironmentFile -and $DatabaseMode -eq 'new') {
        throw 'Use existing mode when supplying database credentials.'
    }
    if (-not $PrepareOnly -and -not (Test-Path -LiteralPath $IdentityFile -PathType Leaf)) {
        throw 'SSH identity file does not exist.'
    }
    if ($RuntimeEnvironmentFile -and -not (Test-Path -LiteralPath $RuntimeEnvironmentFile -PathType Leaf)) {
        throw 'Runtime environment file does not exist.'
    }
    & .\mvnw.cmd -B -ntp verify
    if ($LASTEXITCODE -ne 0) { throw 'Backend verification failed; deployment stopped.' }
    $deployId = [guid]::NewGuid().ToString('N')
    $staging = Join-Path $repoRoot ".local/aws/$deployId"
    New-Item -ItemType Directory -Path $staging -Force | Out-Null
    Copy-Item -LiteralPath (Join-Path $repoRoot 'target/tho-xay-1.0.0.jar') -Destination (Join-Path $staging 'backend.jar')
    foreach ($name in @('install.sh', 'thoxay.service', 'nginx.conf.template')) {
        Copy-Item -LiteralPath (Join-Path $repoRoot "deploy/aws/$name") -Destination (Join-Path $staging $name)
    }
    # Ensure Linux line endings even when the checkout was created on Windows.
    foreach ($name in @('install.sh', 'thoxay.service', 'nginx.conf.template')) {
        $filePath = Join-Path $staging $name
        [IO.File]::WriteAllText($filePath, [IO.File]::ReadAllText($filePath).Replace("`r`n", "`n"), [Text.UTF8Encoding]::new($false))
    }
    $archive = Join-Path $staging 'thoxay.tar.gz'
    & tar -czf $archive -C $staging backend.jar install.sh thoxay.service nginx.conf.template
    if ($LASTEXITCODE -ne 0) { throw 'Cannot package the deployment.' }
    Write-Host "Verified deployment package: $archive"
    if ($PrepareOnly) { return }

    # Verify the server fingerprint before deployment; never disable host-key checking.
    $sshArgs = @('-i', $IdentityFile, '-o', 'BatchMode=yes', '-o', 'StrictHostKeyChecking=yes')
    $remoteDir = ".thoxay-deploy-$deployId"
    $destination = "ubuntu@$Server"
    & ssh @sshArgs $destination "umask 077 && mkdir '$remoteDir'"
    if ($LASTEXITCODE -ne 0) { throw 'SSH failed. Check the identity, security group and trusted server fingerprint.' }
    & scp @sshArgs $archive "${destination}:$remoteDir/thoxay.tar.gz"
    if ($LASTEXITCODE -ne 0) { throw 'Package upload failed.' }
    if ($RuntimeEnvironmentFile) {
        & scp @sshArgs $RuntimeEnvironmentFile "${destination}:$remoteDir/backend.env"
        if ($LASTEXITCODE -ne 0) { throw 'Runtime configuration upload failed.' }
    }
    & ssh @sshArgs $destination "tar -xzf '$remoteDir/thoxay.tar.gz' -C '$remoteDir' && sudo bash '$remoteDir/install.sh' '$ApiDomain' '$WebOrigin' '$DatabaseMode'"
    if ($LASTEXITCODE -ne 0) { throw 'Server installation failed; the existing web API has not been switched.' }
    $health = Invoke-RestMethod -Uri "https://$ApiDomain/health" -TimeoutSec 30
    if ($health.status -ne 'UP') { throw 'Public HTTPS readiness check failed.' }
    Write-Host "AWS backend verified: https://$ApiDomain"
} finally {
    Pop-Location
}

param([switch]$SkipBuild)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    if (-not $env:JWT_SECRET) {
        $jwtBytes = New-Object byte[] 48
        $random = [System.Security.Cryptography.RandomNumberGenerator]::Create()
        try { $random.GetBytes($jwtBytes) } finally { $random.Dispose() }
        $env:JWT_SECRET = [Convert]::ToBase64String($jwtBytes)
        Write-Host 'Created a temporary JWT key for this local session.'
    }
    if (-not $SkipBuild) {
        & .\mvnw.cmd -B verify
        if ($LASTEXITCODE -ne 0) { throw 'Maven verify failed.' }
    }
    $jarPath = Join-Path $projectRoot 'target\tho-xay-1.0.0.jar'
    if (-not (Test-Path -LiteralPath $jarPath)) { throw 'Build the application before using -SkipBuild.' }
    & java -jar $jarPath
    if ($LASTEXITCODE -ne 0) { throw 'The application stopped with an error.' }
} finally {
    Pop-Location
}

param([Parameter(Mandatory=$true)][string]$InputFile,[Parameter(Mandatory=$true)][string]$OutputDirectory,[int]$Width=1240,[int]$MaxPages=0)
$ErrorActionPreference='Stop'
Add-Type -AssemblyName System.Runtime.WindowsRuntime
$null=[Windows.Storage.StorageFile,Windows.Storage,ContentType=WindowsRuntime]
$null=[Windows.Storage.StorageFolder,Windows.Storage,ContentType=WindowsRuntime]
$null=[Windows.Data.Pdf.PdfDocument,Windows.Data.Pdf,ContentType=WindowsRuntime]
$null=[Windows.Storage.Streams.IRandomAccessStream,Windows.Storage.Streams,ContentType=WindowsRuntime]
$generic=([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncOperation`1' })[0]
function Await($operation,[Type]$resultType) {
    $task=$generic.MakeGenericMethod($resultType).Invoke($null,@($operation))
    $task.Wait(); return $task.Result
}
$actionMethod=([System.WindowsRuntimeSystemExtensions].GetMethods() | Where-Object { $_.Name -eq 'AsTask' -and -not $_.IsGenericMethod -and $_.GetParameters().Count -eq 1 -and $_.GetParameters()[0].ParameterType.Name -eq 'IAsyncAction' })[0]
function AwaitAction($action) { $actionTask=$actionMethod.Invoke($null,@($action)); $actionTask.Wait() }
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$file=Await ([Windows.Storage.StorageFile]::GetFileFromPathAsync((Resolve-Path -LiteralPath $InputFile).Path)) ([Windows.Storage.StorageFile])
$pdf=Await ([Windows.Data.Pdf.PdfDocument]::LoadFromFileAsync($file)) ([Windows.Data.Pdf.PdfDocument])
$folder=Await ([Windows.Storage.StorageFolder]::GetFolderFromPathAsync((Resolve-Path $OutputDirectory).Path)) ([Windows.Storage.StorageFolder])
$pages=if($MaxPages -gt 0) { [Math]::Min($MaxPages,$pdf.PageCount) } else { $pdf.PageCount }
for($i=0;$i -lt $pages;$i++) {
    $page=$pdf.GetPage($i); $stream=$null
    try {
        $image=Await ($folder.CreateFileAsync(('page-{0:D3}.png' -f ($i+1)),[Windows.Storage.CreationCollisionOption]::ReplaceExisting)) ([Windows.Storage.StorageFile])
        $stream=Await ($image.OpenAsync([Windows.Storage.FileAccessMode]::ReadWrite)) ([Windows.Storage.Streams.IRandomAccessStream])
        $options=New-Object Windows.Data.Pdf.PdfPageRenderOptions
        $options.DestinationWidth=$Width
        AwaitAction ($page.RenderToStreamAsync($stream,$options))
    } finally { if($stream) { $stream.Dispose() }; $page.Dispose() }
}
Write-Output "Rasterized $pages pages."

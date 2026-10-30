param(
    [Parameter(Mandatory=$true)][string]$InputFile,
    [Parameter(Mandatory=$true)][string]$OutputDirectory,
    [switch]$UpdateFields
)
$ErrorActionPreference='Stop'
$inputPath=(Resolve-Path -LiteralPath $InputFile).Path
New-Item -ItemType Directory -Force $OutputDirectory | Out-Null
$outPath=(Resolve-Path -LiteralPath $OutputDirectory).Path
$extension=[IO.Path]::GetExtension($inputPath).ToLowerInvariant()
if($extension -eq '.docx') {
    $word=$null; $document=$null
    try {
        Write-Output 'Creating dedicated Word automation instance.'
        $word=New-Object -ComObject Word.Application
        $word.Visible=$false; $word.DisplayAlerts=0
        $word.Options.UpdateFieldsAtPrint=$false
        $word.Options.UpdateLinksAtPrint=$false
        Write-Output 'Opening generated DOCX in a dedicated Word instance.'
        $document=$word.Documents.Open($inputPath,$false,(-not $UpdateFields))
        Write-Output 'DOCX opened successfully.'
        if($UpdateFields) {
            $document.Fields.Update() | Out-Null
            Write-Output 'Fields updated.'
            $document.Repaginate()
            foreach($toc in $document.TablesOfContents) { $toc.Update() }
            $document.Save()
            Write-Output 'Table of contents and DOCX saved.'
        }
        $pdf=Join-Path $outPath ([IO.Path]::GetFileNameWithoutExtension($inputPath)+'.pdf')
        # SaveAs2 avoids a hanging ExportAsFixedFormat call on this Office build.
        $document.SaveAs2([string]$pdf,17)
        Write-Output "Word rendered $($document.ComputeStatistics(2)) pages to $pdf"
    } finally {
        if($document) { $document.Close(0); [Runtime.InteropServices.Marshal]::FinalReleaseComObject($document) | Out-Null }
        if($word) { $word.Quit(); [Runtime.InteropServices.Marshal]::FinalReleaseComObject($word) | Out-Null }
    }
} elseif($extension -eq '.pptx') {
    $powerpoint=$null; $presentation=$null
    try {
        $powerpoint=New-Object -ComObject PowerPoint.Application
        $presentation=$powerpoint.Presentations.Open($inputPath,$true,$false,$false)
        $presentation.Export($outPath,'PNG',1600,900)
        Write-Output "PowerPoint rendered $($presentation.Slides.Count) slides to $outPath"
    } finally {
        if($presentation) { $presentation.Close(); [Runtime.InteropServices.Marshal]::FinalReleaseComObject($presentation) | Out-Null }
        if($powerpoint) { $powerpoint.Quit(); [Runtime.InteropServices.Marshal]::FinalReleaseComObject($powerpoint) | Out-Null }
    }
} else { throw 'Expected DOCX or PPTX.' }

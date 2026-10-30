$ErrorActionPreference='Stop'
$projectRoot=Split-Path $PSScriptRoot -Parent
$draft=Join-Path $projectRoot '.local/final-delivery/slides-draft.pptx'
$final=Join-Path $projectRoot 'docs/SLIDE_BAO_VE_DO_AN.pptx'
$notes=Get-Content -Encoding UTF8 (Join-Path $projectRoot '.local/final-delivery/speaker-notes.json') -Raw | ConvertFrom-Json
$output=Join-Path $projectRoot '.local/final-delivery/slides-render'
New-Item -ItemType Directory -Force $output | Out-Null
$ppt=$null;$deck=$null
try {
    $ppt=New-Object -ComObject PowerPoint.Application
    $ppt.DisplayAlerts=1
    $deck=$ppt.Presentations.Open($draft,0,0,0)
    if($deck.Slides.Count -ne 15 -or $notes.Count -ne 15) { throw 'Expected exactly 15 slides and notes.' }
    for($i=1;$i -le 15;$i++) {
        $body=$null
        foreach($shape in $deck.Slides.Item($i).NotesPage.Shapes) {
            if($shape.Type -eq 14 -and $shape.PlaceholderFormat.Type -eq 2) { $body=$shape; break }
        }
        if($null -eq $body) { throw "Native notes body missing on slide $i" }
        $body.TextFrame.TextRange.Text=[string]$notes[$i-1]
        $body.TextFrame.TextRange.Font.Name='Arial'
        $body.TextFrame.TextRange.Font.Size=14
    }
    $deck.SaveAs($final,24)
    $deck.Export($output,'PNG',1600,900)
    Write-Output "Saved native PowerPoint with 15 Speaker Notes and rendered 15 slides."
} finally {
    if($deck) { $deck.Close(); [Runtime.InteropServices.Marshal]::FinalReleaseComObject($deck) | Out-Null }
    if($ppt) { $ppt.Quit(); [Runtime.InteropServices.Marshal]::FinalReleaseComObject($ppt) | Out-Null }
}

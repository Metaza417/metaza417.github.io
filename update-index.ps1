# Scan articles/ directory, regenerate index.html article list
# Usage: .\update-index.ps1

$siteRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $siteRoot

$indexPath = Join-Path $siteRoot "index.html"
$indexHtml = Get-Content $indexPath -Raw -Encoding UTF8

# Collect article metadata
$articles = @()
$articleDir = Join-Path $siteRoot "articles"
Get-ChildItem "$articleDir\*.html" | Where-Object { $_.Name -ne "_template.html" } | ForEach-Object {
    $html = Get-Content $_.FullName -Raw -Encoding UTF8

    $title = ""
    $description = ""
    $date = ""
    $keywords = ""

    if ($html -match '<meta name="description" content="([^"]*)"') { $description = $Matches[1] }
    if ($html -match '<meta property="article:published_time" content="([^"]*)"') { $date = $Matches[1] }
    if ($html -match '<meta name="keywords" content="([^"]*)"') { $keywords = $Matches[1] }
    if ($html -match '<h1>([^<]*)</h1>') { $title = $Matches[1] }

    if (-not $date) { $date = $_.LastWriteTime.ToString("yyyy-MM-dd") }

    $dateCn = ""
    if ($date -match "(\d{4})-(\d{2})-(\d{2})") {
        $dateCn = "$($Matches[1])" + [char]0x5e74 + "$([int]$Matches[2])" + [char]0x6708 + "$([int]$Matches[3])" + [char]0x65e5
    }

    $articles += @{
        FileName = $_.Name
        Title = $title
        Description = $description
        Date = $date
        DateCn = $dateCn
        Keywords = $keywords
    }
}

$articles = $articles | Sort-Object { $_.Date } -Descending

# Generate article cards
$cardsHtml = ""
foreach ($a in $articles) {
    $tagsHtml = ""
    $tagList = $a.Keywords -split ",\s*" | Where-Object { $_ } | Select-Object -First 4
    foreach ($tag in $tagList) {
        $tagsHtml += "`n      <span class=`"tag`">$($tag.Trim())</span>"
    }

    $cardsHtml += @"

  <article class="article-card">
    <div class="date">$($a.DateCn)</div>
    <h3><a href="articles/$($a.FileName)">$($a.Title)</a></h3>
    <div class="summary">$($a.Description)</div>
    <div class="tags">$tagsHtml
    </div>
  </article>
"@
}

# Replace article list area
$pattern = "(?s)(<div class=`"article-list`" id=`"articles`">.*?<h2>" + [char]0x6587 + [char]0x7ae0 + "</h2>).*?(</div>\s*<footer>)"
$replacement = "`${1}$cardsHtml`n`${2}"

$newIndexHtml = $indexHtml -replace $pattern, $replacement
[System.IO.File]::WriteAllText($indexPath, $newIndexHtml, [System.Text.UTF8Encoding]::new($false))
# Add trailing newline
Add-Content -Path $indexPath -Value "`n" -Encoding UTF8 -NoNewline

Write-Output "Index regenerated with $($articles.Count) articles."
Write-Output ($articles | ForEach-Object { "  - $($_.DateCn) $($_.Title)" })

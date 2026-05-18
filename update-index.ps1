# 扫描 articles/ 目录，自动更新 index.html
# 用法: .\update-index.ps1

$siteRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $siteRoot

# 读取现有 index.html，提取 header 和 footer 之间的内容
$indexPath = Join-Path $siteRoot "index.html"
$indexHtml = Get-Content $indexPath -Raw -Encoding UTF8

# 收集所有文章信息
$articles = @()
$articleDir = Join-Path $siteRoot "articles"
Get-ChildItem "$articleDir\*.html" | Where-Object { $_.Name -ne "_template.html" } | ForEach-Object {
    $html = Get-Content $_.FullName -Raw -Encoding UTF8

    # 提取 meta 信息
    $title = ""
    $description = ""
    $date = ""
    $keywords = ""

    if ($html -match '<meta name="description" content="([^"]*)"') { $description = $Matches[1] }
    if ($html -match '<meta property="article:published_time" content="([^"]*)"') { $date = $Matches[1] }
    if ($html -match '<meta name="keywords" content="([^"]*)"') { $keywords = $Matches[1] }
    if ($html -match '<h1>([^<]*)</h1>') { $title = $Matches[1] }

    # 从文件修改时间作为 fallback
    if (-not $date) { $date = $_.LastWriteTime.ToString("yyyy-MM-dd") }

    # 中文日期
    $dateCn = ""
    if ($date -match "(\d{4})-(\d{2})-(\d{2})") {
        $dateCn = "$($Matches[1])年$($Matches[2])月$($Matches[3])日"
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

# 按日期倒序排列
$articles = $articles | Sort-Object { $_.Date } -Descending

# 生成文章列表 HTML
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

# 用正则替换 index.html 中的文章列表区域
$pattern = '(?s)(<div class="article-list" id="articles">.*?<h2>文章</h2>).*?(</div>\s*<footer>)'
$replacement = "`${1}$cardsHtml`n`${2}"

$newIndexHtml = $indexHtml -replace $pattern, $replacement
Set-Content -Path $indexPath -Value $newIndexHtml -Encoding UTF8 -NoNewline
# 确保末尾有换行
Add-Content -Path $indexPath -Value "`n" -Encoding UTF8 -NoNewline

Write-Output "Index regenerated with $($articles.Count) articles."
Write-Output ($articles | ForEach-Object { "  - $($_.DateCn) $($_.Title)" })

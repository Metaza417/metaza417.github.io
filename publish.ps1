# 更新首页索引并推送到 GitHub Pages
# 用法: .\publish.ps1 "commit message"
param([string]$Message = "Update website")

$siteRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $siteRoot

Write-Output "Step 1/3: Regenerating index..."
& "$siteRoot\update-index.ps1"

Write-Output "Step 2/3: Committing..."
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")
git add -A
git commit -m $Message

Write-Output "Step 3/3: Pushing to GitHub Pages..."
git push

Write-Output "Done. Site live at https://metaza417.github.io/"

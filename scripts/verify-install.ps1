<#
.SYNOPSIS
  Comprehensive check that the skills from this repo are correctly installed
  for GitHub Copilot / VS Code. Windows version of verify-install.sh.

.DESCRIPTION
  Checks: target exists and its scope (personal = all workspaces); every repo
  skill present with SKILL.md directly inside; VS Code spec (frontmatter name
  matches folder, lowercase letters/numbers/hyphens, <= 64 chars; description
  present and <= 1024 chars); installed files identical to this repo
  (SHA-256); no duplicates in other scanned locations; VS Code >= 1.109
  (Agent Skills GA, on by default); chat.useAgentSkills not disabled in the
  VS Code user settings (%APPDATA%\Code\User\settings.json).

  Exit code 0 = PASS, 1 = FAIL (warnings alone do not fail).

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File scripts\verify-install.ps1
  powershell -ExecutionPolicy Bypass -File scripts\verify-install.ps1 -Workspace C:\path\to\repo
#>
param(
  [string]$Target = "",
  [string]$Project = "",
  [string]$Source = "",
  [string]$Workspace = ""
)

if (-not $Source) { $Source = Split-Path -Parent $PSScriptRoot }
$SrcSkills = Join-Path $Source "skills"
if (-not (Test-Path $SrcSkills -PathType Container)) { Write-Host "FAIL: no skills\ under source $Source"; exit 1 }

if ($Project) { $Target = Join-Path $Project ".github\skills"; $Scope = "PROJECT (one workspace only)" }
elseif (-not $Target) { $Target = Join-Path $HOME ".copilot\skills"; $Scope = "PERSONAL (all VS Code workspaces)" }
else { $Scope = "CUSTOM" }

$script:pass = 0; $script:fail = 0; $script:warn = 0
function Ok($m)   { $script:pass++; Write-Host "PASS  $m" }
function Bad($m)  { $script:fail++; Write-Host "FAIL  $m" }
function Warn($m) { $script:warn++; Write-Host "WARN  $m" }

function Get-SkillHash($Dir) {
  $lines = Get-ChildItem $Dir -Recurse -File | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($Dir.Length)
    "$rel=$((Get-FileHash $_.FullName -Algorithm SHA256).Hash)"
  }
  $bytes = [System.Text.Encoding]::UTF8.GetBytes([string]::Join("`n", $lines))
  return [BitConverter]::ToString(([System.Security.Cryptography.SHA256]::Create()).ComputeHash($bytes)) -replace "-", ""
}

function Get-Description($SkillMd) {
  $lines = Get-Content $SkillMd
  $inFm = $false; $desc = $null; $folded = $false
  foreach ($line in $lines) {
    if ($line -match "^---\s*$") { if ($inFm) { break } else { $inFm = $true; continue } }
    if (-not $inFm) { continue }
    if ($line -match "^description:\s*(.*)$") {
      $v = $Matches[1].Trim()
      if ($v -in @(">", "|", ">-", "|-")) { $folded = $true; $desc = "" } else { $desc = $v }
      continue
    }
    if ($folded -and $line -match "^\s+\S") { $desc = ($desc + " " + $line.Trim()).Trim(); continue }
    if ($folded) { $folded = $false }
  }
  return $desc
}

Write-Host "Target : $Target"
Write-Host "Scope  : $Scope"
Write-Host ""

if (-not (Test-Path $Target -PathType Container)) { Bad "target directory missing: $Target"; Write-Host ""; Write-Host "RESULT: FAIL (target missing)"; exit 1 }
Ok "target directory exists"

$count = 0
foreach ($srcDir in Get-ChildItem $SrcSkills -Directory) {
  $name = $srcDir.Name
  if (-not (Test-Path (Join-Path $srcDir.FullName "SKILL.md"))) { continue }
  $count++
  $dest = Join-Path $Target $name
  $destMd = Join-Path $dest "SKILL.md"
  if (-not (Test-Path $destMd)) { Bad "$name`: missing (no $destMd)"; continue }
  $fnameLine = Select-String -Path $destMd -Pattern "^name:\s*(.+?)\s*$" | Select-Object -First 1
  $fname = if ($fnameLine) { $fnameLine.Matches[0].Groups[1].Value.Trim('"', "'") } else { "" }
  if ($fname -ne $name) { Bad "$name`: frontmatter name is '$fname'"; continue }
  if ($name -notmatch "^[a-z0-9-]{1,64}$") { Bad "$name`: name invalid for VS Code"; continue }
  $desc = Get-Description $destMd
  if (-not $desc) { Bad "$name`: no description in frontmatter"; continue }
  if ($desc.Length -gt 1024) { Bad "$name`: description $($desc.Length) chars > 1024 (VS Code limit)"; continue }
  if ((Get-SkillHash $srcDir.FullName) -eq (Get-SkillHash $dest)) { Ok $name }
  else { Bad "$name`: installed files differ from repo (stale or partial - re-run installer)" }
}
Write-Host "Checked $count repo skills."
Write-Host ""

$dups = @()
$otherLocations = @(
  @((Join-Path $HOME ".copilot\skills"), "~/.copilot/skills"),
  @((Join-Path $HOME ".claude\skills"), "~/.claude/skills"),
  @((Join-Path $HOME ".agents\skills"), "~/.agents/skills")
)
if ($Workspace) {
  $otherLocations += @((Join-Path $Workspace ".github\skills"), "workspace/.github/skills")
  $otherLocations += @((Join-Path $Workspace ".claude\skills"), "workspace/.claude/skills")
  $otherLocations += @((Join-Path $Workspace ".agents\skills"), "workspace/.agents/skills")
}
foreach ($loc in $otherLocations) {
  if ($loc[0] -eq $Target) { continue }
  if (-not (Test-Path $loc[0] -PathType Container)) { continue }
  foreach ($srcDir in Get-ChildItem $SrcSkills -Directory) {
    if (Test-Path (Join-Path $loc[0] $srcDir.Name)) { $dups += "$($srcDir.Name)@$($loc[1])" }
  }
}
if ($dups.Count) { Warn "same skill also present elsewhere (VS Code may list/load it twice): $($dups -join ' ')" }
else { Ok "no duplicates in other scanned locations" }
Write-Host ""

$codeCmd = Get-Command code -ErrorAction SilentlyContinue
if ($codeCmd) {
  $v = (& code --version | Select-Object -First 1)
  if ($v -match "^(\d+)\.(\d+)") {
    if ([int]$Matches[1] -gt 1 -or ([int]$Matches[1] -eq 1 -and [int]$Matches[2] -ge 109)) { Ok "VS Code $v (>= 1.109, Agent Skills GA)" }
    else { Bad "VS Code $v < 1.109 - update VS Code, Agent Skills may not load" }
  } else { Warn "VS Code version unparsable: $v (need >= 1.109)" }
} else { Warn "'code' not on PATH here - verify on the target machine: VS Code >= 1.109 (latest recommended)" }

$settings = Join-Path $env:APPDATA "Code\User\settings.json"
if (Test-Path $settings) {
  if ((Get-Content $settings -Raw) -match '"chat\.useAgentSkills"\s*:\s*false') { Bad "chat.useAgentSkills is false in $settings - Agent Skills are disabled" }
  else { Ok "chat.useAgentSkills not disabled in user settings" }
} else { Warn "no VS Code user settings.json found here (fine if VS Code is on another machine)" }

Write-Host ""
$result = if ($script:fail -eq 0) { "PASS" } else { "FAIL" }
Write-Host "RESULT: $result - $($script:pass) passed, $($script:fail) failed, $($script:warn) warnings"
if ($script:fail -gt 0) { exit 1 } else { exit 0 }

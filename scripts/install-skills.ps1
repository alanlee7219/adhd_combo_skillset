<#
.SYNOPSIS
  Install / update the skills in this repo into a GitHub Copilot (or any
  Agent Skills) skills directory. Windows version of install-skills.sh.

.DESCRIPTION
  Safe to re-run, idempotent, no internet required:
    * Skill missing from target          -> ADDED
    * Skill present but files differ     -> UPDATED (old copy backed up first)
    * Skill present and identical        -> SKIPPED (up to date)
    * Folders in target not in this repo -> LEFT UNTOUCHED (your other skills)

  File comparison is by SHA-256 hash of every file in the skill folder.

.EXAMPLE
  # Personal Copilot skills (~/.copilot/skills)
  powershell -ExecutionPolicy Bypass -File scripts\install-skills.ps1

.EXAMPLE
  # Project skills (<repo>\.github\skills) + merge core instructions block
  powershell -ExecutionPolicy Bypass -File scripts\install-skills.ps1 -Project C:\path\to\repo -WithInstructions

.EXAMPLE
  # Report only, change nothing (exit 1 if anything would change)
  powershell -ExecutionPolicy Bypass -File scripts\install-skills.ps1 -Check
#>
param(
  [string]$Target = "",
  [string]$Project = "",
  [string]$Source = "",
  [switch]$Check,
  [switch]$DryRun,
  [switch]$NoBackup,
  [string]$BackupDir = "",
  [string[]]$Only = @(),
  [string[]]$Exclude = @(),
  [switch]$WithInstructions,
  [switch]$VSCode
)

$ErrorActionPreference = "Stop"

if (-not $Source) { $Source = Split-Path -Parent $PSScriptRoot }
$SrcSkills = Join-Path $Source "skills"
if (-not (Test-Path $SrcSkills -PathType Container)) {
  Write-Error "No skills\ directory found under source: $Source. Run from inside the extracted repo (or pass -Source)."
  exit 2
}

if ($Project) { $Target = Join-Path $Project ".github\skills"; $Scope = "PROJECT - only the workspace at $Project" }
elseif ($Target) { $Scope = "CUSTOM target" }
else { $Scope = "PERSONAL - user level, applies to ALL VS Code workspaces" }
if (-not $Target) { $Target = Join-Path $HOME ".copilot\skills" }
if (-not $BackupDir) { $BackupDir = Join-Path (Split-Path -Parent $Target) "skills-backup" }
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$ReportOnly = $Check -or $DryRun

function Get-SkillHash($Dir) {
  # One combined hash over relative paths + file hashes, order-stable.
  $lines = Get-ChildItem $Dir -Recurse -File | Sort-Object FullName | ForEach-Object {
    $rel = $_.FullName.Substring($Dir.Length)
    $h = (Get-FileHash $_.FullName -Algorithm SHA256).Hash
    "$rel=$h"
  }
  $joined = [string]::Join("`n", $lines)
  $bytes = [System.Text.Encoding]::UTF8.GetBytes($joined)
  $sha = [System.Security.Cryptography.SHA256]::Create()
  return [BitConverter]::ToString($sha.ComputeHash($bytes)) -replace "-", ""
}

Write-Host "Source : $SrcSkills"
Write-Host "Target : $Target"
Write-Host "Scope  : $Scope"
if ($ReportOnly) { Write-Host "Mode   : check only (nothing will be changed)" }
Write-Host ""

$added = 0; $updated = 0; $skipped = 0; $failed = 0
$addedList = @(); $updatedList = @()
if (-not $ReportOnly) { New-Item -ItemType Directory -Force $Target | Out-Null }

foreach ($srcDir in Get-ChildItem $SrcSkills -Directory) {
  $name = $srcDir.Name
  if (-not (Test-Path (Join-Path $srcDir.FullName "SKILL.md"))) { Write-Host "WARN  $name has no SKILL.md in source, skipped"; continue }
  if ($Only.Count -gt 0 -and $Only -notcontains $name) { continue }
  if ($Exclude -contains $name) { continue }
  $dest = Join-Path $Target $name

  if (-not (Test-Path $dest -PathType Container)) {
    if ($ReportOnly) { Write-Host "WOULD ADD     $name" }
    else {
      try { Copy-Item $srcDir.FullName $Target -Recurse; Write-Host "ADDED         $name" }
      catch { Write-Host "FAILED        $name"; $failed++; continue }
    }
    $added++; $addedList += $name; continue
  }

  if ((Get-SkillHash $srcDir.FullName) -eq (Get-SkillHash $dest)) {
    Write-Host "UP TO DATE    $name"; $skipped++; continue
  }

  if ($ReportOnly) { Write-Host "WOULD UPDATE  $name" }
  else {
    try {
      if (-not $NoBackup) {
        $bdir = Join-Path $BackupDir $Stamp
        New-Item -ItemType Directory -Force $bdir | Out-Null
        Copy-Item $dest $bdir -Recurse
      }
      Remove-Item $dest -Recurse -Force
      Copy-Item $srcDir.FullName $Target -Recurse
      Write-Host "UPDATED       $name (old copy in $BackupDir\$Stamp)"
    } catch { Write-Host "FAILED        $name"; $failed++; continue }
  }
  $updated++; $updatedList += $name
}

if ($WithInstructions) {
  $snippet = Join-Path $Source "copilot\copilot-instructions.snippet.md"
  if (-not $Project) { Write-Host "NOTE  -WithInstructions needs -Project; skipped." }
  elseif (-not (Test-Path $snippet)) { Write-Host "NOTE  snippet not found at $snippet; skipped." }
  else {
    $instr = Join-Path $Project ".github\copilot-instructions.md"
    if ($ReportOnly) { Write-Host "WOULD MERGE   core instructions block into $instr" }
    else {
      New-Item -ItemType Directory -Force (Split-Path -Parent $instr) | Out-Null
      if (-not (Test-Path $instr)) { New-Item -ItemType File $instr | Out-Null }
      $existing = Get-Content $instr -Raw
      $existing = [regex]::Replace($existing, "(?s)<!-- BEGIN adhd-combo core -->.*?<!-- END adhd-combo core -->\r?\n?", "")
      Set-Content $instr ($existing + (Get-Content $snippet -Raw)) -Encoding UTF8
      Write-Host "MERGED        core instructions block into $instr"
    }
  }
}

Write-Host ""
Write-Host "Verifying..."
$verifyFail = 0; $count = 0
foreach ($srcDir in Get-ChildItem $SrcSkills -Directory) {
  $name = $srcDir.Name
  if (-not (Test-Path (Join-Path $srcDir.FullName "SKILL.md"))) { continue }
  if ($Only.Count -gt 0 -and $Only -notcontains $name) { continue }
  if ($Exclude -contains $name) { continue }
  $count++
  $targetSkill = Join-Path $Target "$name\SKILL.md"
  if ($ReportOnly -and -not (Test-Path (Join-Path $Target $name))) { continue }
  if (-not (Test-Path $targetSkill)) { Write-Host "VERIFY FAIL   $name`: SKILL.md missing in target"; $verifyFail++; continue }
  if (-not (Select-String -Path $targetSkill -Pattern "^name:\s*$([regex]::Escape($name))\s*$" -Quiet)) {
    Write-Host "VERIFY FAIL   $name`: frontmatter name does not match folder"; $verifyFail++
  }
}

Write-Host ""
Write-Host "Summary: $count repo skills checked | added:$added updated:$updated up-to-date:$skipped failed:$failed verify-failures:$verifyFail"
if ($addedList.Count) { Write-Host "  added:   $($addedList -join ' ')" }
if ($updatedList.Count) { Write-Host "  updated: $($updatedList -join ' ')" }
Write-Host "Skills already in the target that are not in this repo were left untouched."

# VS Code check (personal installs, or with -VSCode): Agent Skills are GA and
# on by default in VS Code >= 1.109 (Jan 2026). Latest is best.
if ($VSCode -or -not $Project) {
  Write-Host ""
  $codeCmd = Get-Command code -ErrorAction SilentlyContinue
  if ($codeCmd) {
    $v = (& code --version | Select-Object -First 1)
    Write-Host "VS Code: $v"
    if ($v -match "^(\d+)\.(\d+)") {
      if ([int]$Matches[1] -gt 1 -or ([int]$Matches[1] -eq 1 -and [int]$Matches[2] -ge 109)) {
        Write-Host "  OK - Agent Skills supported and enabled by default."
      } else { Write-Host "  WARNING - VS Code < 1.109: update VS Code, Agent Skills may not load." }
    }
  } else { Write-Host "VS Code: 'code' not on PATH here - on the target machine use VS Code >= 1.109 (latest recommended)." }
}

if ($failed -gt 0 -or $verifyFail -gt 0) { exit 1 }
if ($Check -and ($added -gt 0 -or $updated -gt 0)) { exit 1 }
exit 0

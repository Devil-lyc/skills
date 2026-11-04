<#
.SYNOPSIS
  Sync the skill folders under skills/ into various agent platforms with one command.
.DESCRIPTION
  Global platforms (WorkBuddy / Claude Code): symlink (junction) skills/<name> into the
  user-level skills directory so every workspace/project can use them.
  Rule-based platforms (Cursor / Trae / Codex / Gemini): convert SKILL.md into the platform's
  rule file and write it into each project's rules directory (rules are per-project).
.PARAMETER Project
  Extra project root to write rules into (can be specified multiple times).
.PARAMETER WhatIf
  Preview only, do not write.
#>
[CmdletBinding()]
param(
  [string[]]$Project = @(),
  [switch]$WhatIf
)

$ErrorActionPreference = "Stop"
$Root = $PSScriptRoot
$SkillSource = Join-Path $Root "skills"

# ============ CONFIG: edit as needed ============
# Global platforms: anything using SKILL.md gets symlinked into the user-level skills dir.
$GlobalPlatforms = @(
  @{ Name = "WorkBuddy";   Target = "$env:USERPROFILE\.workbuddy\skills" }
  @{ Name = "Claude Code"; Target = "$env:USERPROFILE\.claude\skills" }
)
# Rule-based platforms: SKILL.md -> rule file in the project's rules dir.
$RulePlatforms = @(
  @{ Name = "Cursor"; RulesRel = ".cursor\rules";  Ext = "mdc"; Frontmatter = $true }
  @{ Name = "Trae";   RulesRel = ".trae\rules";    Ext = "mdc"; Frontmatter = $true }
  @{ Name = "Codex";  RulesRel = ".codex\rules";   Ext = "md";  Frontmatter = $false }
  @{ Name = "Gemini"; RulesRel = ".gemini\rules";  Ext = "md";  Frontmatter = $false }
)
# Projects that rule-based platforms apply to (rules are per-project).
# Fill in your project paths here, or pass -Project at runtime.
$Projects = @(
  # "C:\Code\MyProject"
)
# ============ END CONFIG ============

if (-not (Test-Path $SkillSource)) { Write-Error "skills/ not found: $SkillSource"; exit 1 }
$skills = Get-ChildItem $SkillSource -Directory
if ($skills.Count -eq 0) { Write-Warning "skills/ has no skill folders."; exit 0 }

function New-SkillJunction($link, $src) {
  if (Test-Path $link) {
    $it = Get-Item $link
    if ($it.Attributes -band [System.IO.FileAttributes]::ReparsePoint) {
      if ($WhatIf) { Write-Host "  [WhatIf] remove old link $link" } else { [System.IO.Directory]::Delete($link) }
    } else {
      Write-Warning "skip: exists and not a link -> $link"; return $false
    }
  }
  if ($WhatIf) { Write-Host "  [WhatIf] link $link -> $src"; return $true }
  New-Item -ItemType Junction -Path $link -Target $src | Out-Null
  return $true
}

function Get-SkillBody($skillDir) {
  $f = Join-Path $skillDir "SKILL.md"
  if (-not (Test-Path $f)) { return "(this skill has no SKILL.md)" }
  $lines = Get-Content $f
  if ($lines.Count -eq 0 -or $lines[0].Trim() -ne "---") { return ($lines -join "`n") }
  $end = 1
  while ($end -lt $lines.Count -and $lines[$end].Trim() -ne "---") { $end++ }
  if ($end -ge $lines.Count) { return ($lines -join "`n") }
  return ($lines[($end + 1)..($lines.Count - 1)] -join "`n")
}

Write-Host "==> Syncing $($skills.Count) skill(s): $($skills.Name -join ', ')" -ForegroundColor Cyan

# ---- Global platforms: symlink ----
foreach ($p in $GlobalPlatforms) {
  $target = $p.Target
  if (-not (Test-Path $target)) {
    if ($WhatIf) { Write-Host "  [WhatIf] create dir $target" } else { New-Item -ItemType Directory -Path $target -Force | Out-Null }
  }
  Write-Host ">> Global platform $($p.Name) -> $target" -ForegroundColor Green
  foreach ($s in $skills) {
    $link = Join-Path $target $s.Name
    $src = $s.FullName
    $ok = New-SkillJunction $link $src
    if ($ok) { Write-Host "  + linked $($s.Name)" }
  }
}

# ---- Rule-based platforms: generate rule files ----
$allProjects = $Projects + $Project
if ($allProjects.Count -eq 0) {
  Write-Host ">> Rule-based platforms skipped (no projects configured; set `$Projects or use -Project)." -ForegroundColor Yellow
} else {
  foreach ($proj in $allProjects) {
    if (-not (Test-Path $proj)) { Write-Warning "project not found, skip: $proj"; continue }
    Write-Host ">> Project rules $proj" -ForegroundColor Green
    foreach ($rp in $RulePlatforms) {
      $rulesDir = Join-Path $proj $rp.RulesRel
      if (-not (Test-Path $rulesDir)) {
        if ($WhatIf) { Write-Host "  [WhatIf] create $rulesDir" } else { New-Item -ItemType Directory -Path $rulesDir -Force | Out-Null }
      }
      foreach ($s in $skills) {
        $body = Get-SkillBody $s.FullName
        if ($rp.Frontmatter) {
          $content = "---`n" +
                     "description: $($s.Name) (synced from personal skill repo)`n" +
                     "alwaysApply: false`n" +
                     "---`n`n" + $body
        } else {
          $content = "# $($s.Name)`n`n" + $body
        }
        $out = Join-Path $rulesDir "$($s.Name).$($rp.Ext)"
        if ($WhatIf) { Write-Host "  [WhatIf] write $out"; continue }
        Set-Content -Path $out -Value $content -Encoding UTF8
        Write-Host "  + [$($rp.Name)] $($s.Name).$($rp.Ext)"
      }
    }
  }
}

Write-Host "==> Done." -ForegroundColor Cyan

# open-skills 安装脚本 (PowerShell)
# 仓库地址: https://github.com/uaio/open-skills.git
#
# 使用方式:
#   # 远程安装
#   irm https://raw.githubusercontent.com/uaio/open-skills/main/install.ps1 | iex
#
#   # 本地使用
#   .\install.ps1 init     # 首次安装
#   .\install.ps1 all      # 一键安装
#   .\install.ps1 ls       # 查看状态

param(
    [Parameter(Position = 0)]
    [string]$Command = "",

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Args
)

# 项目配置
$RepoUrl = "https://github.com/uaio/open-skills.git"
$OpenSkillsDir = Join-Path $env:USERPROFILE ".open-skills"
$ScriptDir = $PSScriptRoot
if ([string]::IsNullOrEmpty($ScriptDir)) {
    $ScriptDir = Get-Location
}
$SkillsSource = Join-Path $ScriptDir "skills"

# 工具配置
$Tools = @(
    @{Name = "claude"; Dir = Join-Path $env:USERPROFILE ".claude\skills"; Native = $true; Display = "Claude Code" },
    @{Name = "agents"; Dir = Join-Path $env:USERPROFILE ".agents\skills"; Native = $true; Display = "Agents" },
    @{Name = "openclaw"; Dir = Join-Path $env:USERPROFILE ".openclaw\skills"; Native = $true; Display = "OpenClaw" },
    @{Name = "codex"; Dir = Join-Path $env:USERPROFILE ".codex\skills"; Native = $false; Display = "Codex CLI" },
    @{Name = "gemini"; Dir = Join-Path $env:USERPROFILE ".gemini\skills"; Native = $false; Display = "Gemini CLI" },
    @{Name = "continue"; Dir = Join-Path $env:USERPROFILE ".continue\skills"; Native = $false; Display = "Continue" },
    @{Name = "windsurf"; Dir = Join-Path $env:USERPROFILE ".windsurf\skills"; Native = $false; Display = "Windsurf" },
    @{Name = "cursor"; Dir = Join-Path $env:USERPROFILE ".cursor\skills"; Native = $false; Display = "Cursor" },
    @{Name = "copilot"; Dir = Join-Path $env:USERPROFILE ".copilot\skills"; Native = $false; Display = "Copilot" },
    @{Name = "opencode"; Dir = Join-Path $env:USERPROFILE ".opencode\skills"; Native = $false; Display = "OpenCode" }
)

# 颜色函数
function Write-Success { Write-Host "  [OK] $args" -ForegroundColor Green }
function Write-Warning { Write-Host "  [!] $args" -ForegroundColor Yellow }
function Write-Error { Write-Host "  [X] $args" -ForegroundColor Red }
function Write-Info { Write-Host "  [*] $args" -ForegroundColor Cyan }

# 获取所有 skill 名称
function Get-Skills {
    $skills = @()
    if (Test-Path $SkillsSource) {
        $dirs = Get-ChildItem -Path $SkillsSource -Directory
        foreach ($dir in $dirs) {
            $skills += $dir.Name
        }
    }
    return $skills
}

# 创建 skill 链接（使用 Junction）
function Link-Skill {
    param($Skill, $TargetDir)

    $TargetPath = Join-Path $TargetDir $Skill
    $SourcePath = Join-Path $SkillsSource $Skill

    # 确保目标目录存在
    if (-not (Test-Path $TargetDir)) {
        New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
    }

    # 如果目标已存在
    if (Test-Path $TargetPath) {
        $junction = Get-Item $TargetPath -ErrorAction SilentlyContinue
        if ($junction.LinkType -eq "Junction") {
            $currentTarget = $junction.Target
            if ($currentTarget -eq $SourcePath) {
                Write-Info "$Skill (已链接)"
                return
            }
        }
        # 删除现有内容
        Remove-Item $TargetPath -Recurse -Force
    }

    # 创建 Junction（不需要管理员权限）
    New-Item -ItemType Junction -Path $TargetPath -Target $SourcePath | Out-Null
    Write-Success $Skill
}

# 移除 skill 链接
function Unlink-Skill {
    param($Skill, $TargetDir)

    $TargetPath = Join-Path $TargetDir $Skill

    if (Test-Path $TargetPath) {
        $item = Get-Item $TargetPath
        if ($item.LinkType -eq "Junction") {
            $item.Delete()
            Write-Host "  [OK] $Skill (已移除)" -ForegroundColor Green
        }
        else {
            Write-Warning "$Skill (非链接，跳过)"
        }
    }
}

# 安装到指定工具
function Install-Tool {
    param($Tool)

    $config = $Tools | Where-Object { $_.Name -eq $Tool }
    if (-not $config) {
        Write-Host "错误: 未知工具 '$Tool'" -ForegroundColor Red
        return
    }

    $skills = Get-Skills
    $targetDir = $config.Dir
    $toolName = $config.Display

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "安装到: $toolName" -ForegroundColor Yellow
    Write-Host "目录:   $targetDir" -ForegroundColor Yellow
    Write-Host ""

    foreach ($skill in $skills) {
        Link-Skill $skill $targetDir
    }
    Write-Host ""
}

# 从指定工具移除
function Uninstall-Tool {
    param($Tool)

    $config = $Tools | Where-Object { $_.Name -eq $Tool }
    if (-not $config) {
        Write-Host "错误: 未知工具 '$Tool'" -ForegroundColor Red
        return
    }

    $skills = Get-Skills
    $targetDir = $config.Dir
    $toolName = $config.Display

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "移除: $toolName" -ForegroundColor Yellow
    Write-Host "目录: $targetDir" -ForegroundColor Yellow
    Write-Host ""

    foreach ($skill in $skills) {
        Unlink-Skill $skill $targetDir
    }
    Write-Host ""
}

# 一键安装
function Install-All {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "     open-skills 一键安装" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

    foreach ($tool in $Tools) {
        if ($tool.Native) {
            Install-Tool $tool.Name
        }
    }

    Write-Host "已安装到:" -ForegroundColor Green
    foreach ($tool in $Tools) {
        if ($tool.Native) {
            Write-Host "  [OK] $($tool.Display) -> $($tool.Dir)" -ForegroundColor Green
        }
    }
    Write-Host ""
}

# 一键卸载
function Uninstall-All {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "     open-skills 一键卸载" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

    foreach ($tool in $Tools) {
        if ($tool.Native) {
            Uninstall-Tool $tool.Name
        }
    }

    Write-Host "全部卸载完成！" -ForegroundColor Green
}

# 首次安装
function Install-Self {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "     open-skills 安装向导" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

    if (Test-Path $OpenSkillsDir) {
        Write-Host "open-skills 已安装在 $OpenSkillsDir" -ForegroundColor Yellow
        Write-Host "正在更新..." -ForegroundColor Green
        Set-Location $OpenSkillsDir
        git pull origin main
        Write-Host "[OK] 更新完成" -ForegroundColor Green
        Write-Host ""
    }
    else {
        Write-Host "正在克隆项目..." -ForegroundColor Yellow
        git clone $RepoUrl $OpenSkillsDir
        Write-Host "[OK] 项目已克隆到 $OpenSkillsDir" -ForegroundColor Green
        Write-Host ""
    }

    # 添加到 PATH
    Add-ToPath

    Write-Host ""
    Write-Host "========================================" -ForegroundColor Green
    Write-Host "     安装成功！" -ForegroundColor Green
    Write-Host "========================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "运行 'skills all' 安装到所有工具" -ForegroundColor Cyan
    Write-Host "更多命令运行 'skills help' 查看" -ForegroundColor Cyan
}

# 添加到 PATH
function Add-ToPath {
    $binDir = Join-Path $OpenSkillsDir "bin"

    # 创建 bin 目录
    if (-not (Test-Path $binDir)) {
        New-Item -ItemType Directory -Path $binDir -Force | Out-Null
    }

    # 创建 skills.ps1 包装脚本
    $wrapperScript = @'
param(
    [Parameter(Position = 0)]
    [string]$Command = "",

    [Parameter(ValueFromRemainingArguments)]
    [string[]]$Args
)

& "$PSScriptRoot\..\install.ps1" $Command @Args
'@
    $wrapperPath = Join-Path $binDir "skills.ps1"
    Set-Content -Path $wrapperPath -Value $wrapperScript -Encoding UTF8

    # 检查是否已在 PATH 中
    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -notlike "*$binDir*") {
        [Environment]::SetEnvironmentVariable("Path", "$currentPath;$binDir", "User")
        Write-Host "[OK] 已添加到 PATH: $binDir" -ForegroundColor Green
        Write-Host "请重新打开终端或运行: `$env:Path += `";$binDir`"" -ForegroundColor Yellow
    }
    else {
        Write-Info "PATH 已配置"
    }
}

# 从 PATH 移除
function Remove-FromPath {
    $binDir = Join-Path $OpenSkillsDir "bin"

    $currentPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($currentPath -like "*$binDir*") {
        $newPath = ($currentPath -split ';' | Where-Object { $_ -ne $binDir }) -join ';'
        [Environment]::SetEnvironmentVariable("Path", $newPath, "User")
        Write-Host "[OK] 已从 PATH 移除" -ForegroundColor Green
    }
    else {
        Write-Info "未找到 PATH 配置"
    }
}

# 升级
function Upgrade-Self {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "     open-skills 升级" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

    if (-not (Test-Path $OpenSkillsDir)) {
        Write-Host "错误: open-skills 未安装" -ForegroundColor Red
        Write-Host "请先运行安装命令" -ForegroundColor Yellow
        exit 1
    }

    Write-Host "正在更新..." -ForegroundColor Yellow
    Set-Location $OpenSkillsDir
    git pull origin main
    Write-Host "[OK] 更新完成" -ForegroundColor Green
    Write-Host ""

    Add-ToPath
}

# 卸载自身
function Uninstall-Self {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "     open-skills 卸载" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

    Write-Host "警告: 这将移除 open-skills 及所有链接" -ForegroundColor Yellow
    $confirm = Read-Host "确认卸载？(y/N)"

    if ($confirm -ne "y" -and $confirm -ne "Y") {
        Write-Host "已取消"
        exit 0
    }

    Uninstall-All
    Remove-FromPath

    if (Test-Path $OpenSkillsDir) {
        Remove-Item $OpenSkillsDir -Recurse -Force
        Write-Host "[OK] 已删除 $OpenSkillsDir" -ForegroundColor Green
    }

    Write-Host ""
    Write-Host "open-skills 已完全卸载" -ForegroundColor Green
}

# 显示状态
function Show-Status {
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host "     open-skills 安装状态" -ForegroundColor Blue
    Write-Host "========================================" -ForegroundColor Blue
    Write-Host ""

    $skills = Get-Skills
    Write-Host "可用 Skills (源目录: $SkillsSource):" -ForegroundColor Yellow
    foreach ($skill in $skills) {
        Write-Host "  - $skill"
    }
    Write-Host ""

    Write-Host "各工具安装状态:" -ForegroundColor Yellow

    $claudeShown = $false

    foreach ($tool in $Tools) {
        # 原生工具只显示一次
        if ($tool.Native) {
            if ($claudeShown) { continue }
            $claudeShown = $true
            $nativeNote = " (原生读取 ~/.claude/skills)"
        }
        else {
            $nativeNote = ""
        }

        Write-Host ""
        Write-Host "$($tool.Display)$nativeNote" -ForegroundColor Cyan
        Write-Host "  目录: $($tool.Dir)"

        foreach ($skill in $skills) {
            $targetPath = Join-Path $tool.Dir $skill
            $sourcePath = Join-Path $SkillsSource $skill

            if (Test-Path $targetPath) {
                $item = Get-Item $targetPath
                if ($item.LinkType -eq "Junction") {
                    if ($item.Target -eq $sourcePath) {
                        Write-Success $skill
                    }
                    else {
                        Write-Warning "$skill (链接到其他位置)"
                    }
                }
                else {
                    Write-Warning "$skill (非链接)"
                }
            }
            else {
                Write-Error $skill
            }
        }
    }
}

# 显示帮助
function Show-Help {
    Write-Host "skills - AI 工具 Skills 管理器"
    Write-Host ""
    Write-Host "用法: skills <命令> [工具...]"
    Write-Host ""
    Write-Host "命令:"
    Write-Host "  init          首次安装"
    Write-Host "  up            更新版本"
    Write-Host "  rm            卸载 skills 本身"
    Write-Host "  ls            查看状态"
    Write-Host "  all           安装到所有工具"
    Write-Host "  clear         移除所有链接"
    Write-Host "  <工具>        安装到指定工具"
    Write-Host "  rm <工具>     从指定工具移除"
    Write-Host ""
    Write-Host "工具:"
    Write-Host "  claude  openclaw  codex  gemini  continue  windsurf"
    Write-Host "  cursor  copilot  opencode"
    Write-Host ""
    Write-Host "  skills all  # 一键安装到 ~/.claude ~/.agents ~/.openclaw"
    Write-Host ""
    Write-Host "示例:"
    Write-Host "  skills init          # 首次安装"
    Write-Host "  skills all           # 安装到 claude/agents/openclaw"
    Write-Host "  skills codex         # 安装到 Codex 私有目录"
    Write-Host "  skills rm codex      # 从 Codex 移除"
    Write-Host "  skills ls            # 查看状态"
}

# 主逻辑
switch ($Command) {
    "" {
        # 交互式安装
        Write-Host ""
        Write-Host "========================================" -ForegroundColor Blue
        Write-Host "     open-skills 交互式安装" -ForegroundColor Blue
        Write-Host "========================================" -ForegroundColor Blue
        Write-Host ""

        $skills = Get-Skills
        Write-Host "将安装以下 Skills:" -ForegroundColor Yellow
        foreach ($skill in $skills) {
            Write-Host "  - $skill"
        }
        Write-Host ""

        Write-Host "请选择要安装的工具:" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "  1) claude     2) openclaw    3) codex"
        Write-Host "  4) gemini     5) continue    6) windsurf"
        Write-Host "  7) cursor     8) copilot     9) opencode"
        Write-Host ""
        Write-Host "  a) all        - 一键安装到 claude/agents/openclaw"
        Write-Host "  q) quit       - 退出"
        Write-Host ""

        $choices = Read-Host "请输入选项"

        if ($choices -eq "q") {
            Write-Host "已取消"
            exit 0
        }

        if ($choices -eq "a") {
            Install-All
            exit 0
        }

        $toolMap = @{
            "1" = "claude"; "2" = "openclaw"; "3" = "codex"
            "4" = "gemini"; "5" = "continue"; "6" = "windsurf"
            "7" = "cursor"; "8" = "copilot"; "9" = "opencode"
        }

        $selectedTools = @()
        foreach ($choice in $choices -split '[,\s]+') {
            if ($toolMap[$choice]) {
                $selectedTools += $toolMap[$choice]
            }
        }

        if ($selectedTools.Count -eq 0) {
            Write-Host "未选择任何工具" -ForegroundColor Red
            exit 1
        }

        Write-Host ""
        foreach ($tool in $selectedTools) {
            Install-Tool $tool
        }

        Write-Host "安装完成！" -ForegroundColor Green
    }
    "help" { Show-Help }
    "--help" { Show-Help }
    "-h" { Show-Help }
    "init" { Install-Self }
    "setup" { Install-Self }
    "up" { Upgrade-Self }
    "upgrade" { Upgrade-Self }
    "update" { Upgrade-Self }
    "rm" {
        if ($Args.Count -eq 0) {
            Uninstall-Self
        }
        else {
            foreach ($tool in $Args) {
                Uninstall-Tool $tool
            }
        }
    }
    "ls" { Show-Status }
    "status" { Show-Status }
    "st" { Show-Status }
    "all" { Install-All }
    "clear" { Uninstall-All }
    "none" { Uninstall-All }
    "clean" { Uninstall-All }
    default {
        # 检查是否是有效的工具名
        $toolNames = $Tools | ForEach-Object { $_.Name }
        if ($toolNames -contains $Command) {
            Install-Tool $Command
        }
        else {
            Write-Host "未知命令: $Command" -ForegroundColor Red
            Show-Help
            exit 1
        }
    }
}

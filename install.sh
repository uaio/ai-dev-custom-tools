#!/bin/bash

# open-skills 安装脚本
# 仓库地址: https://github.com/uaio/open-skills.git
#
# 策略：以本项目 skills/ 目录为源，将每个 skill 软链接到各工具目录
#
# 使用方式:
#   # 远程安装（推荐）
#   curl -fsSL https://raw.githubusercontent.com/uaio/open-skills/main/install.sh | bash -s -- setup
#
#   # 安装后使用全局命令
#   skills all              # 安装到所有工具
#   skills claude           # 仅安装到 Claude Code
#   skills status           # 查看安装状态
#   skills unlink codex     # 从 Codex 移除软链接

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# 项目配置
REPO_URL="https://github.com/uaio/open-skills.git"
OPEN_SKILLS_DIR="$HOME/.open-skills"
BIN_DIR="/usr/local/bin"
CMD_NAME="skills"

# 获取脚本所在目录（项目根目录）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_SOURCE="$SCRIPT_DIR/skills"

# ============================================
# 工具配置
# 格式: "工具名:目标目录:是否一键安装:显示名称"
# ============================================
TOOLS=(
    # 一键安装目标（skills all 会安装到这里）
    "claude:$HOME/.claude/skills:true:Claude Code"
    "agents:$HOME/.agents/skills:true:Agents"
    "openclaw:$HOME/.openclaw/skills:true:OpenClaw"
    # 私有链接（可单独指定）
    "codex:$HOME/.codex/skills:false:Codex CLI"
    "gemini:$HOME/.gemini/skills:false:Gemini CLI"
    "continue:$HOME/.continue/skills:false:Continue"
    "windsurf:$HOME/.windsurf/skills:false:Windsurf"
    "cursor:$HOME/.cursor/skills:false:Cursor"
    "copilot:$HOME/.copilot/skills:false:Copilot"
    "opencode:$HOME/.opencode/skills:false:OpenCode"
)

# 所有支持的私有链接工具（用于帮助显示）
PRIVATE_TOOLS="claude openclaw codex gemini continue windsurf cursor copilot opencode"

# 从配置中获取字段
get_tool_name() { echo "$1" | cut -d':' -f1; }
get_tool_dir() { echo "$1" | cut -d':' -f2; }
get_tool_native() { echo "$1" | cut -d':' -f3; }
get_tool_display() { echo "$1" | cut -d':' -f4; }

# 根据工具名查找配置
find_tool_config() {
    local target="$1"
    for config in "${TOOLS[@]}"; do
        if [ "$(get_tool_name "$config")" = "$target" ]; then
            echo "$config"
            return 0
        fi
    done
    return 1
}

# 获取项目中的所有 skill 名称
get_skills() {
    local skills=()
    if [ -d "$SKILLS_SOURCE" ]; then
        for dir in "$SKILLS_SOURCE"/*/; do
            if [ -d "$dir" ]; then
                skills+=("$(basename "$dir")")
            fi
        done
    fi
    echo "${skills[@]}"
}

# 创建单个 skill 的软链接
link_skill() {
    local skill="$1"
    local target_dir="$2"
    local target_path="$target_dir/$skill"
    local source_path="$SKILLS_SOURCE/$skill"

    # 确保目标目录存在
    mkdir -p "$target_dir"

    # 如果目标已存在
    if [ -e "$target_path" ] || [ -L "$target_path" ]; then
        # 如果已经是正确的软链接，跳过
        if [ -L "$target_path" ]; then
            local current_link
            current_link=$(readlink "$target_path")
            if [ "$current_link" = "$source_path" ]; then
                echo -e "  ${CYAN}⊙${NC} $skill (已链接)"
                return 0
            fi
        fi
        # 否则先删除
        rm -rf "$target_path"
    fi

    # 创建软链接
    ln -s "$source_path" "$target_path"
    echo -e "  ${GREEN}✓${NC} $skill"
}

# 移除单个 skill 的软链接
unlink_skill() {
    local skill="$1"
    local target_dir="$2"
    local target_path="$target_dir/$skill"

    if [ -L "$target_path" ]; then
        rm "$target_path"
        echo -e "  ${GREEN}✗${NC} $skill (已移除)"
    elif [ -e "$target_path" ]; then
        echo -e "  ${YELLOW}!${NC} $skill (非软链接，跳过)"
    fi
}

# 安装到指定工具
install_tool() {
    local tool="$1"
    local config
    config=$(find_tool_config "$tool")

    if [ -z "$config" ]; then
        echo -e "${RED}错误: 未知工具 '$tool'${NC}"
        return 1
    fi

    local skills=$(get_skills)
    local target_dir=$(get_tool_dir "$config")
    local tool_name=$(get_tool_display "$config")

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}安装到:${NC} $tool_name"
    echo -e "${YELLOW}目录:${NC}   $target_dir"
    echo ""

    for skill in $skills; do
        link_skill "$skill" "$target_dir"
    done

    echo ""
}

# 从指定工具移除
uninstall_tool() {
    local tool="$1"
    local config
    config=$(find_tool_config "$tool")

    if [ -z "$config" ]; then
        echo -e "${RED}错误: 未知工具 '$tool'${NC}"
        return 1
    fi

    local skills=$(get_skills)
    local target_dir=$(get_tool_dir "$config")
    local tool_name=$(get_tool_display "$config")

    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}移除:${NC} $tool_name"
    echo -e "${YELLOW}目录:${NC}   $target_dir"
    echo ""

    for skill in $skills; do
        unlink_skill "$skill" "$target_dir"
    done

    echo ""
}

# 一键安装（只安装 native=true 的工具）
install_all() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     open-skills 一键安装                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    for config in "${TOOLS[@]}"; do
        local tool=$(get_tool_name "$config")
        local native=$(get_tool_native "$config")

        if [ "$native" = "true" ]; then
            install_tool "$tool"
        fi
    done

    echo ""
    echo -e "${GREEN}✓ 已安装到:${NC}"
    for config in "${TOOLS[@]}"; do
        local native=$(get_tool_native "$config")
        if [ "$native" = "true" ]; then
            local tool_name=$(get_tool_display "$config")
            local target_dir=$(get_tool_dir "$config")
            echo "  ${GREEN}✓${NC} $tool_name → $target_dir"
        fi
    done
    echo ""
}

# 一键卸载（只卸载 native=true 的工具）
uninstall_all() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     open-skills 一键卸载                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    for config in "${TOOLS[@]}"; do
        local tool=$(get_tool_name "$config")
        local native=$(get_tool_native "$config")

        if [ "$native" = "true" ]; then
            uninstall_tool "$tool"
        fi
    done

    echo ""
    echo -e "${GREEN}全部卸载完成！${NC}"
}

# ============================================
# open-skills 自身管理命令
# ============================================

# 首次安装 setup
do_setup() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     open-skills 安装向导               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    # 检查是否已安装
    if [ -d "$OPEN_SKILLS_DIR" ]; then
        echo -e "${YELLOW}open-skills 已安装在 $OPEN_SKILLS_DIR${NC}"
        echo -n "是否重新安装？(y/N): "
        read confirm
        if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
            echo "已取消"
            exit 0
        fi
        rm -rf "$OPEN_SKILLS_DIR"
    fi

    # Clone 项目
    echo -e "${YELLOW}正在克隆项目...${NC}"
    git clone "$REPO_URL" "$OPEN_SKILLS_DIR"
    echo -e "${GREEN}✓${NC} 项目已克隆到 $OPEN_SKILLS_DIR"
    echo ""

    # 创建全局命令
    do_link_global_cmd

    echo ""
    echo -e "${GREEN}╔════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║     安装成功！                         ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════╝${NC}"
    echo ""

    # 询问是否自动安装
    echo -n "是否自动安装 skills 到所有工具？(Y/n): "
    read auto_install
    if [ "$auto_install" != "n" ] && [ "$auto_install" != "N" ]; then
        echo ""
        install_all
    else
        echo ""
        echo -e "稍后运行 ${CYAN}skills all${NC} 安装到所有工具"
    fi

    echo ""
    echo -e "更多命令运行 ${CYAN}skills help${NC} 查看"
}

# 创建全局命令软链接
do_link_global_cmd() {
    local target="$BIN_DIR/$CMD_NAME"
    local source="$OPEN_SKILLS_DIR/install.sh"

    # 检查是否已存在
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
        echo -e "${CYAN}⊙${NC} 全局命令已存在: $CMD_NAME"
        return 0
    fi

    # 尝试直接创建
    if ln -s "$source" "$target" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 全局命令已创建: $CMD_NAME -> $source"
        return 0
    fi

    # 需要 sudo
    echo -e "${YELLOW}需要管理员权限创建全局命令...${NC}"
    if sudo ln -s "$source" "$target"; then
        echo -e "${GREEN}✓${NC} 全局命令已创建: $CMD_NAME -> $source"
        return 0
    else
        echo -e "${RED}✗${NC} 创建全局命令失败"
        echo ""
        echo "你可以手动添加到 PATH："
        echo ""
        echo "  # 添加到 ~/.zshrc 或 ~/.bashrc："
        echo "  export PATH=\"\$HOME/.open-skills:\$PATH\""
        echo ""
        echo "  # 或者创建 alias："
        echo "  alias skills='bash \$HOME/.open-skills/install.sh'"
        echo ""
        return 1
    fi
}

# 移除全局命令
do_unlink_global_cmd() {
    local target="$BIN_DIR/$CMD_NAME"

    if [ ! -L "$target" ]; then
        echo -e "${CYAN}⊙${NC} 全局命令不存在"
        return 0
    fi

    # 尝试直接删除
    if rm "$target" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 全局命令已移除"
        return 0
    fi

    # 需要 sudo
    echo -e "${YELLOW}需要管理员权限移除全局命令...${NC}"
    if sudo rm "$target"; then
        echo -e "${GREEN}✓${NC} 全局命令已移除"
        return 0
    else
        echo -e "${RED}✗${NC} 移除全局命令失败"
        return 1
    fi
}

# 升级
do_upgrade() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     open-skills 升级                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    if [ ! -d "$OPEN_SKILLS_DIR" ]; then
        echo -e "${RED}错误: open-skills 未安装${NC}"
        echo "请先运行: curl -fsSL https://raw.githubusercontent.com/uaio/open-skills/main/install.sh | bash -s -- setup"
        exit 1
    fi

    echo -e "${YELLOW}正在更新...${NC}"
    cd "$OPEN_SKILLS_DIR"
    git pull origin main
    echo -e "${GREEN}✓${NC} 更新完成"
    echo ""

    # 重新创建全局命令（以防万一）
    do_link_global_cmd
}

# 卸载 open-skills 本身
do_self_uninstall() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     open-skills 卸载                   ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}警告: 这将移除 open-skills 及所有软链接${NC}"
    echo -n "确认卸载？(y/N): "
    read confirm

    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo "已取消"
        exit 0
    fi

    # 移除所有工具的软链接
    uninstall_all

    # 移除全局命令
    do_unlink_global_cmd

    # 删除项目目录
    if [ -d "$OPEN_SKILLS_DIR" ]; then
        rm -rf "$OPEN_SKILLS_DIR"
        echo -e "${GREEN}✓${NC} 已删除 $OPEN_SKILLS_DIR"
    fi

    echo ""
    echo -e "${GREEN}open-skills 已完全卸载${NC}"
}

# 显示状态
show_status() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     open-skills 安装状态               ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    local skills=$(get_skills)
    echo -e "${YELLOW}可用 Skills (源目录: $SKILLS_SOURCE):${NC}"
    for skill in $skills; do
        echo "  • $skill"
    done
    echo ""

    echo -e "${YELLOW}各工具安装状态:${NC}"

    local claude_shown=false

    for config in "${TOOLS[@]}"; do
        local tool=$(get_tool_name "$config")
        local target_dir=$(get_tool_dir "$config")
        local tool_name=$(get_tool_display "$config")
        local native=$(get_tool_native "$config")
        local native_note=""

        # 原生读取 ~/.claude/skills 的工具只显示一次
        if [ "$native" = "true" ]; then
            if [ "$claude_shown" = true ]; then
                continue
            fi
            claude_shown=true
            native_note=" (原生读取 ~/.claude/skills)"
        fi

        echo -e "\n${CYAN}$tool_name${NC}$native_note"
        echo "  目录: $target_dir"

        for skill in $skills; do
            local target_path="$target_dir/$skill"
            local source_path="$SKILLS_SOURCE/$skill"
            if [ -L "$target_path" ]; then
                local current_link
                current_link=$(readlink "$target_path")
                if [ "$current_link" = "$source_path" ]; then
                    echo -e "  ${GREEN}✓${NC} $skill"
                else
                    echo -e "  ${YELLOW}!${NC} $skill (链接到其他位置)"
                fi
            elif [ -e "$target_path" ]; then
                echo -e "  ${YELLOW}!${NC} $skill (非软链接)"
            else
                echo -e "  ${RED}✗${NC} $skill"
            fi
        done
    done
}

# 显示帮助
show_help() {
    echo "skills - AI 工具 Skills 管理器"
    echo ""
    echo "用法: skills <命令> [工具...]"
    echo ""
    echo "命令:"
    echo "  init          首次安装"
    echo "  up            更新版本"
    echo "  rm            卸载 skills 本身"
    echo "  ls            查看状态"
    echo "  all           安装到所有工具"
    echo "  clear         移除所有软链接"
    echo "  <工具>        安装到指定工具"
    echo "  rm <工具>     从指定工具移除"
    echo ""
    echo "工具:"
    echo "  claude  openclaw  codex  gemini  continue  windsurf"
    echo "  cursor  copilot  opencode"
    echo ""
    echo "  skills all  # 一键安装到 ~/.claude ~/.agents ~/.openclaw"
    echo ""
    echo "示例:"
    echo "  skills init          # 首次安装"
    echo "  skills all           # 安装到 claude/agents/openclaw"
    echo "  skills codex         # 安装到 Codex 私有目录"
    echo "  skills rm codex      # 从 Codex 移除"
    echo "  skills ls            # 查看状态"
}

# 交互式选择
interactive_install() {
    echo -e "${BLUE}╔════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║     open-skills 交互式安装             ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════╝${NC}"
    echo ""

    local skills=$(get_skills)
    echo -e "${YELLOW}将安装以下 Skills:${NC}"
    for skill in $skills; do
        echo "  • $skill"
    done
    echo ""

    echo -e "${YELLOW}请选择要安装的工具:${NC}"
    echo ""
    echo "  1) claude     2) openclaw    3) codex"
    echo "  4) gemini     5) continue    6) windsurf"
    echo "  7) cursor     8) copilot     9) opencode"
    echo ""
    echo "  a) all        - 一键安装到 claude/agents/openclaw"
    echo "  q) quit       - 退出"
    echo ""
    echo -n "请输入选项: "
    read choices

    if [ "$choices" = "q" ]; then
        echo "已取消"
        exit 0
    fi

    if [ "$choices" = "a" ]; then
        install_all
        exit 0
    fi

    local selected_tools=""

    for choice in $choices; do
        case $choice in
            1) selected_tools="$selected_tools claude" ;;
            2) selected_tools="$selected_tools openclaw" ;;
            3) selected_tools="$selected_tools codex" ;;
            4) selected_tools="$selected_tools gemini" ;;
            5) selected_tools="$selected_tools continue" ;;
            6) selected_tools="$selected_tools windsurf" ;;
            7) selected_tools="$selected_tools cursor" ;;
            8) selected_tools="$selected_tools copilot" ;;
            9) selected_tools="$selected_tools opencode" ;;
        esac
    done

    if [ -z "$selected_tools" ]; then
        echo -e "${RED}未选择任何工具${NC}"
        exit 1
    fi

    echo ""
    for tool in $selected_tools; do
        install_tool "$tool"
    done

    echo -e "${GREEN}安装完成！${NC}"
}

# 主逻辑
main() {
    local cmd="${1:-}"

    case "$cmd" in
        "")
            interactive_install
            ;;
        help|--help|-h)
            show_help
            ;;
        init|setup)
            do_setup
            ;;
        up|upgrade|update)
            do_upgrade
            ;;
        rm)
            shift
            if [ -z "$1" ]; then
                # 无参数时卸载 skills 本身
                do_self_uninstall
            else
                # 有参数时从指定工具移除
                for tool in "$@"; do
                    uninstall_tool "$tool"
                done
            fi
            ;;
        ls|status|st)
            show_status
            ;;
        all)
            install_all
            ;;
        clear|none|clean)
            uninstall_all
            ;;
        *)
            # 检查是否是有效的工具名
            if find_tool_config "$cmd" > /dev/null 2>&1; then
                for tool in "$@"; do
                    install_tool "$tool"
                done
            else
                echo -e "${RED}未知命令: $cmd${NC}"
                show_help
                exit 1
            fi
            ;;
    esac
}

# 自动检查并创建全局命令
auto_link_global_cmd() {
    # 只在已安装目录中运行时才自动创建
    if [ "$SCRIPT_DIR" != "$OPEN_SKILLS_DIR" ]; then
        return
    fi

    # 检查 skills 命令是否存在
    if command -v skills &> /dev/null; then
        return
    fi

    # 自动创建全局命令
    local target="$BIN_DIR/$CMD_NAME"
    local source="$OPEN_SKILLS_DIR/install.sh"

    if ln -s "$source" "$target" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 已自动创建全局命令: skills"
    elif sudo ln -s "$source" "$target" 2>/dev/null; then
        echo -e "${GREEN}✓${NC} 已自动创建全局命令: skills (sudo)"
    fi
}

# 运行自动检查
auto_link_global_cmd

main "$@"

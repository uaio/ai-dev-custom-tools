#!/bin/bash

# AI Dev Custom Tools 远程安装脚本
# 仓库地址: https://github.com/uaio/ai-dev-custom-tools.git
#
# 使用方式:
#   curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- [工具名] [子目录]
#   curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- claude
#   curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- claude skills
#   curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- codex agents

set -e

# 仓库信息
REPO_URL="https://github.com/uaio/ai-dev-custom-tools"
REPO_RAW="https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main"
REPO_API="https://api.github.com/repos/uaio/ai-dev-custom-tools/contents"

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 工具目录映射
declare -A TOOL_DIRS=(
    ["claude"]="$HOME/.claude/skills"
    ["codex"]="$HOME/.codex/skills"
    ["opencode"]="$HOME/.opencode/skill"
    ["openclaw"]="$HOME/.openclaw/skills"
    ["gemini"]="$HOME/.gemini/skills"
    ["cursor"]="$HOME/.cursor/skills"
)

# 工具名称映射（用于显示）
declare -A TOOL_NAMES=(
    ["claude"]="Claude Code"
    ["codex"]="OpenAI Codex"
    ["opencode"]="OpenCode"
    ["openclaw"]="OpenClaw"
    ["gemini"]="Gemini CLI"
    ["cursor"]="Cursor"
)

# 下载文件/目录的函数
download_from_github() {
    local path="$1"      # 仓库中的路径，如 "skills/new-demand"
    local target="$2"    # 本地目标路径

    # 使用 GitHub API 获取内容
    local api_url="${REPO_API}/${path}"

    # 获取目录内容
    local content
    content=$(curl -s "$api_url")

    # 检查是否是文件
    if echo "$content" | grep -q '"type":"file"'; then
        # 是文件，直接下载
        local download_url
        download_url=$(echo "$content" | grep -o '"download_url":"[^"]*"' | cut -d'"' -f4)
        if [ -n "$download_url" ]; then
            curl -sL "$download_url" -o "$target"
            return 0
        fi
    fi

    # 是目录，递归处理
    mkdir -p "$target"

    # 解析目录内容
    echo "$content" | grep -oE '"name":"[^"]*"|"type":"[^"]*"|"path":"[^"]*"' | \
    paste - - - | while read -r line; do
        local name type item_path
        name=$(echo "$line" | grep -oE '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        type=$(echo "$line" | grep -oE '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
        item_path=$(echo "$line" | grep -oE '"path":"[^"]*"' | cut -d'"' -f4)

        if [ -n "$name" ] && [ -n "$type" ]; then
            if [ "$type" = "dir" ]; then
                download_from_github "$item_path" "$target/$name"
            else
                local download_url="${REPO_RAW}/${item_path}"
                curl -sL "$download_url" -o "$target/$name"
            fi
        fi
    done
}

# 获取仓库目录列表
list_repo_dirs() {
    local content
    content=$(curl -s "${REPO_API}")

    echo "仓库根目录下的可用目录:"
    echo "$content" | grep -oE '"name":"[^"]*"|"type":"[^"]*"' | \
    paste - - | while read -r line; do
        local name type
        name=$(echo "$line" | grep -oE '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        type=$(echo "$line" | grep -oE '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
        if [ "$type" = "dir" ] && [ -n "$name" ] && [[ ! "$name" =~ ^\. ]]; then
            echo "  - $name"
        fi
    done
}

# 安装函数
install() {
    local tool="$1"
    local subdir="${2:-skills}"

    # 检查工具是否支持
    if [[ ! -v "TOOL_DIRS[$tool]" ]]; then
        echo -e "${RED}错误: 不支持的工具 '$tool'${NC}"
        echo -e "支持的工具: ${!TOOL_DIRS[@]}"
        exit 1
    fi

    local target_dir="${TOOL_DIRS[$tool]}"
    local tool_name="${TOOL_NAMES[$tool]}"

    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}   AI Dev Custom Tools 安装脚本${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    echo -e "${YELLOW}目标工具:${NC} $tool_name"
    echo -e "${YELLOW}安装目录:${NC} $target_dir"
    echo -e "${YELLOW}复制内容:${NC} $subdir/"
    echo ""

    # 创建目标目录
    mkdir -p "$target_dir"

    # 创建临时目录
    local temp_dir
    temp_dir=$(mktemp -d)
    trap "rm -rf $temp_dir" EXIT

    echo -e "${BLUE}正在从 GitHub 下载...${NC}"

    # 获取仓库中指定目录的内容
    local api_url="${REPO_API}/${subdir}"
    local content
    content=$(curl -s "$api_url")

    # 检查目录是否存在
    if echo "$content" | grep -q '"message":"Not Found"'; then
        echo -e "${RED}错误: 仓库中不存在目录 '$subdir'${NC}"
        list_repo_dirs
        exit 1
    fi

    # 下载目录内容
    echo "$content" | grep -oE '"name":"[^"]*"|"type":"[^"]*"|"path":"[^"]*"' | \
    paste - - - | while read -r line; do
        local name type item_path
        name=$(echo "$line" | grep -oE '"name":"[^"]*"' | head -1 | cut -d'"' -f4)
        type=$(echo "$line" | grep -oE '"type":"[^"]*"' | head -1 | cut -d'"' -f4)
        item_path=$(echo "$line" | grep -oE '"path":"[^"]*"' | cut -d'"' -f4)

        if [ -n "$name" ] && [ -n "$type" ]; then
            echo -e "  ${GREEN}→${NC} 下载: $name"

            if [ "$type" = "dir" ]; then
                # 递归下载目录
                mkdir -p "$target_dir/$name"
                download_from_github "$item_path" "$target_dir/$name"
            else
                # 下载文件
                local download_url="${REPO_RAW}/${item_path}"
                curl -sL "$download_url" -o "$target_dir/$name"
            fi
        fi
    done

    echo ""
    echo -e "${GREEN}======================================${NC}"
    echo -e "${GREEN}   安装完成！${NC}"
    echo -e "${GREEN}======================================${NC}"
    echo ""
    echo -e "已安装到: ${YELLOW}$target_dir${NC}"
}

# 安装到所有工具
install_all() {
    local subdir="${1:-skills}"

    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}   AI Dev Custom Tools 安装脚本${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
    echo -e "${YELLOW}安装到所有支持的 AI 工具${NC}"
    echo -e "${YELLOW}复制内容:${NC} $subdir/"
    echo ""

    for tool in "${!TOOL_DIRS[@]}"; do
        echo -e "${BLUE}--- 安装到 ${TOOL_NAMES[$tool]} ---${NC}"
        install "$tool" "$subdir"
        echo ""
    done
}

# 显示帮助
show_help() {
    echo "AI Dev Custom Tools - 远程安装脚本"
    echo ""
    echo "用法:"
    echo "  curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- [工具] [子目录]"
    echo ""
    echo "参数:"
    echo "  工具      目标 AI 工具名称（见下表）"
    echo "  子目录    要复制的仓库子目录，默认为 'skills'"
    echo ""
    echo "支持的工具:"
    echo "  claude     Claude Code      → ~/.claude/skills/"
    echo "  codex      OpenAI Codex     → ~/.codex/skills/"
    echo "  opencode   OpenCode         → ~/.opencode/skill/"
    echo "  openclaw   OpenClaw         → ~/.openclaw/skills/"
    echo "  gemini     Gemini CLI       → ~/.gemini/skills/"
    echo "  cursor     Cursor           → ~/.cursor/skills/"
    echo "  all        安装到所有工具"
    echo ""
    echo "示例:"
    echo "  # 安装 skills 目录到 Claude Code"
    echo "  curl -fsSL ... | bash -s -- claude"
    echo ""
    echo "  # 安装 skills 目录到所有工具"
    echo "  curl -fsSL ... | bash -s -- all"
    echo ""
    echo "  # 安装 agents 目录到 Codex"
    echo "  curl -fsSL ... | bash -s -- codex agents"
    echo ""
    echo "  # 安装 prompts 目录到 Gemini"
    echo "  curl -fsSL ... | bash -s -- gemini prompts"
}

# 主逻辑
main() {
    local tool="${1:-help}"
    local subdir="$2"

    case "$tool" in
        help|--help|-h)
            show_help
            ;;
        all)
            install_all "${subdir:-skills}"
            ;;
        list)
            list_repo_dirs
            ;;
        *)
            if [[ -v "TOOL_DIRS[$tool]" ]]; then
                install "$tool" "${subdir:-skills}"
            else
                echo -e "${RED}未知工具: $tool${NC}"
                echo ""
                show_help
                exit 1
            fi
            ;;
    esac
}

main "$@"

# AI Dev Custom Tools

自定义 AI 开发工具集合，为 Claude Code、OpenAI Codex、OpenCode、OpenClaw、Gemini CLI、Cursor、GitHub Copilot 等 AI 编程助手提供增强功能。

## 一键安装（远程）

不需要 clone 仓库，直接运行：

```bash
# 安装 skills 到 Claude Code
curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- claude

# 安装 skills 到所有工具
curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- all

# 安装指定子目录到指定工具
curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- codex agents
curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- gemini prompts
```

## 支持的工具

| 工具名 | 名称 | 安装目录 |
|--------|------|----------|
| `claude` | Claude Code | `~/.claude/skills/` |
| `codex` | OpenAI Codex | `~/.codex/skills/` |
| `opencode` | OpenCode | `~/.opencode/skill/` |
| `openclaw` | OpenClaw | `~/.openclaw/skills/` |
| `gemini` | Gemini CLI | `~/.gemini/skills/` |
| `cursor` | Cursor | `~/.cursor/skills/` |

## 用法

```bash
curl -fsSL https://raw.githubusercontent.com/uaio/ai-dev-custom-tools/main/install.sh | bash -s -- [工具] [子目录]
```

| 参数 | 说明 | 默认值 |
|------|------|--------|
| 工具 | 目标 AI 工具名称，或 `all` 安装到所有工具 | 必填 |
| 子目录 | 仓库中要复制的子目录 | `skills` |

### 示例

```bash
# 安装默认目录(skills)到 Claude Code
curl -fsSL ... | bash -s -- claude

# 安装到所有工具
curl -fsSL ... | bash -s -- all

# 安装 agents 目录到 Codex
curl -fsSL ... | bash -s -- codex agents

# 安装 prompts 目录到 Gemini
curl -fsSL ... | bash -s -- gemini prompts

# 查看帮助
curl -fsSL ... | bash -s -- help

# 查看仓库可用目录
curl -fsSL ... | bash -s -- list
```

## 仓库目录结构

```
ai-dev-custom-tools/
├── skills/          # Skills 自定义技能（默认安装）
│   └── new-demand/  # 需求追踪管理
├── agents/          # Agents 配置（可选安装）
├── prompts/         # Prompts 模板（可选安装）
└── install.sh       # 安装脚本
```

## 包含的工具

### custom:new-demand

需求追踪管理工具，支持：
- 自动生成带时间标号的需求标题
- 创建结构化的任务列表
- 任务状态追踪和更新
- 进度汇总和归档

**使用方式：**
```
/new-demand [需求描述]
```

## 本地安装（可选）

如果想先 clone 再安装：

```bash
git clone https://github.com/uaio/ai-dev-custom-tools.git
cd ai-dev-custom-tools
./install.sh claude          # 安装 skills 到 Claude Code
./install.sh codex agents    # 安装 agents 到 Codex
./install.sh all             # 安装 skills 到所有工具
```

## 贡献

欢迎提交 Issue 和 Pull Request！

## License

MIT

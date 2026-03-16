# open-skills

跨平台 AI 工具 Skills 管理器，通过软链接让多个 AI 编程助手共享同一份 skills。

## 快速开始

```bash
# 一键安装（自动安装到所有工具）
curl -fsSL https://raw.githubusercontent.com/uaio/open-skills/main/install.sh | bash -s -- init
```

## 命令

```
skills <命令> [工具...]

命令:
  init          首次安装
  up            更新版本
  rm            卸载 skills 本身
  ls            查看状态
  all           一键安装
  clear         移除软链接
  <工具>        安装到指定工具
  rm <工具>     从指定工具移除
```

## 支持的工具

```
claude  openclaw  codex  gemini  continue  windsurf  cursor  copilot  opencode
```

- `skills all` 一键安装到 `~/.claude/skills`、`~/.agents/skills`、`~/.openclaw/skills`
- 所有工具都能兼容这三个目录

## 示例

```bash
skills init          # 首次安装
skills all           # 一键安装
skills claude        # 单独安装到 Claude
skills openclaw      # 单独安装到 OpenClaw
skills codex         # 单独安装到 Codex
skills rm codex      # 从 Codex 移除
skills ls            # 查看状态
```

## 手动配置全局命令

```bash
# 方法 1: PATH
export PATH="$HOME/.open-skills:$PATH"

# 方法 2: alias
alias skills='bash $HOME/.open-skills/install.sh'

# 方法 3: 软链接
sudo ln -s $HOME/.open-skills/install.sh /usr/local/bin/skills
```

## License

MIT

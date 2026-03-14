# 设计文档：custom:project-init

## 概述

`custom:project-init` 是一个元 skill，用于自动分析项目结构并生成 `project-structure` skill。

## 命名约定

| 名称 | 类型 | 说明 |
|------|------|------|
| `custom:project-init` | 元 skill | 本 skill，用于生成项目结构说明 |
| `project-structure` | 生成的 skill | 描述具体项目的结构，放在项目 `.claude/skills/` 下 |

## 元 skill 规格

### 基本信息

- **名称**：`custom:project-init`
- **触发方式**：`/project-init` 或 "初始化项目结构"
- **参数**：无（自动检测）
- **位置**：`skills/project-init/SKILL.md`

### 执行流程

```
1. 智能检测技术栈
   ├── 检测 package.json → Node.js/前端项目
   ├── 检测 go.mod → Go 项目
   ├── 检测 requirements.txt / pyproject.toml → Python 项目
   ├── 检测 Cargo.toml → Rust 项目
   └── 检测 pom.xml / build.gradle → Java 项目

2. 扫描项目目录结构
   ├── 排除 node_modules/、.git/、dist/、build/ 等
   └── 识别核心目录（src/、app/、lib/、api/ 等）

3. 识别核心模块
   ├── 根据 src/ 或 app/ 下的子目录划分
   └── 识别常见模式（auth、api、components、utils 等）

4. 生成 project-structure skill
   └── 输出到 .claude/skills/project-structure/

5. 检查 CLAUDE.md / AGENTS.md
   ├── 对比已有内容与生成的 skill
   ├── 列出重复项
   └── 提示用户是否精简

6. 用户确认精简
   └── 删除或改为引用 skill
```

### 智能检测规则

| 文件 | 技术栈 | 框架识别 |
|------|--------|----------|
| package.json | Node.js | 检测 dependencies 中的 react、vue、next、express 等 |
| go.mod | Go | 检测 module 和 require |
| requirements.txt | Python | 检测 django、flask、fastapi 等 |
| Cargo.toml | Rust | 检测 dependencies |
| pom.xml | Java | 检测 spring-boot 等 |

### 排除目录

```
node_modules/
.git/
dist/
build/
.out/
.next/
coverage/
vendor/
__pycache__/
*.egg-info/
```

## 生成的 skill 规格

### 目录结构

```
.claude/skills/project-structure/
├── SKILL.md              # 主索引（精简）
├── tech-stack.md         # 技术栈 + 依赖说明
├── commands.md           # 常用命令
├── conventions.md        # 编码规范 + 注意事项
└── modules/              # 核心模块说明
    ├── [模块名].md
    └── ...
```

### SKILL.md 模板

```markdown
---
name: project-structure
description: 本项目结构说明。Use when 需要了解项目结构、模块说明、技术栈、开发规范时。触发词：项目结构、目录结构、技术栈、模块说明。
---

# 项目结构：{项目名}

## 技术栈

{技术栈简述}，详见 [tech-stack.md](./tech-stack.md)

## 核心模块

| 模块 | 说明 |
|------|------|
| {模块1} | {简述}，详见 [modules/{模块1}.md](./modules/{模块1}.md) |
| {模块2} | {简述}，详见 [modules/{模块2}.md](./modules/{模块2}.md) |

## 常用命令

详见 [commands.md](./commands.md)

## 开发规范

详见 [conventions.md](./conventions.md)
```

### tech-stack.md 模板

```markdown
# 技术栈

## 运行环境

- Node.js: {version}
- 包管理器: {npm/yarn/pnpm}

## 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| react | {version} | UI 框架 |
| ... | ... | ... |

## 开发依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
| typescript | {version} | 类型检查 |
| ... | ... | ... |
```

### commands.md 模板

```markdown
# 常用命令

## 开发

\`\`\`bash
npm run dev      # 启动开发服务器
\`\`\`

## 构建

\`\`\`bash
npm run build    # 构建生产版本
\`\`\`

## 测试

\`\`\`bash
npm test         # 运行测试
\`\`\`

## 其他

\`\`\`bash
npm run lint     # 代码检查
\`\`\`
```

### conventions.md 模板

```markdown
# 开发规范

## 代码风格

- {规范说明}

## 目录约定

- `src/components/` - 可复用组件
- `src/pages/` - 页面组件
- ...

## 注意事项

- {注意事项}
```

### modules/*.md 模板

```markdown
# 模块：{模块名}

## 目录结构

\`\`\`
{模块名}/
├── file1.ts
├── file2.ts
└── subdir/
\`\`\`

## 职责

{模块职责说明}

## 关键文件

| 文件 | 说明 |
|------|------|
| {file} | {说明} |

## 依赖关系

- 依赖于：{其他模块}
- 被依赖：{其他模块}
```

## CLAUDE.md / AGENTS.md 精简逻辑

### 检测重复内容

1. 读取 CLAUDE.md / AGENTS.md 内容
2. 与生成的 skill 内容对比
3. 识别以下类型的重复：
   - 技术栈说明
   - 目录结构说明
   - 常用命令
   - 编码规范

### 精简方式

| 重复类型 | 处理方式 |
|----------|----------|
| 技术栈 | 删除，改为引用 `project-structure` |
| 目录结构 | 删除，改为引用 |
| 常用命令 | 删除，改为引用 |
| 编码规范 | 保留项目特有的，通用规范删除 |

### 精简后的引用示例

```markdown
## 项目结构

详见 `.claude/skills/project-structure/`

## 开发命令

详见 `.claude/skills/project-structure/commands.md`
```

## 用户交互流程

```
用户: /project-init

AI: 正在分析项目结构...
    - 检测到技术栈: React + TypeScript
    - 识别到 5 个核心模块: auth, api, components, hooks, utils

    已生成 project-structure skill 到 .claude/skills/project-structure/

    检测到 CLAUDE.md 中以下内容与 skill 重复：
    1. 技术栈说明（第 10-25 行）
    2. 目录结构说明（第 30-50 行）

    是否精简 CLAUDE.md？[Y/n]
用户: Y

AI: 已精简 CLAUDE.md，删除重复内容并添加引用。
    完成！
```

## 文件清单

| 文件 | 说明 |
|------|------|
| `skills/project-init/SKILL.md` | 元 skill 主文件 |

## 与现有 skill 的关系

| skill | 关系 |
|-------|------|
| `custom:new-demand` | 同为元 skill，生成需求追踪 skill |
| `project-structure` | 本 skill 生成的目标 skill |

---
name: custom:project-init
description: 自动分析项目结构并生成 project-structure skill。Use when 用户想初始化项目结构说明、生成项目结构文档、或说"初始化项目结构""生成项目结构""project init"时。
argument-hint: [项目路径，默认当前目录]
context: fork
---

# 元 Skill：生成项目结构说明

## 用途

自动分析当前项目，生成 `project-structure` skill 到项目的 `.claude/skills/` 目录下。

## 严格执行流程

### 第一步：智能检测技术栈

检测项目根目录下的配置文件：

| 文件 | 技术栈 | 框架识别方式 |
|------|--------|--------------|
| package.json | Node.js | 检测 dependencies 中的 react、vue、next、express、nestjs 等 |
| go.mod | Go | 读取 module 和 require |
| requirements.txt / pyproject.toml | Python | 检测 django、flask、fastapi 等 |
| Cargo.toml | Rust | 读取 dependencies |
| pom.xml / build.gradle | Java | 检测 spring-boot 等 |

### 第二步：扫描项目目录结构

1. 列出项目目录树
2. 排除以下目录：
   - node_modules/
   - .git/
   - dist/
   - build/
   - .out/
   - .next/
   - coverage/
   - vendor/
   - __pycache__/
   - *.egg-info/
   - .claude/（已生成的 skill 目录）

### 第三步：识别核心模块

根据 src/ 或 app/ 下的子目录划分模块，识别常见模式：
- auth / authentication → 认证模块
- api / routes / controllers → API 层
- components / ui → 组件
- hooks / composables → Hooks
- utils / lib / common → 工具函数
- services / business → 业务逻辑
- models / entities → 数据模型
- stores / state / redux → 状态管理
- pages / views → 页面

### 第四步：生成 project-structure skill

在项目的 `.claude/skills/project-structure/` 目录下生成：

```
project-structure/
├── SKILL.md              # 主索引（精简）
├── tech-stack.md         # 技术栈 + 依赖说明
├── commands.md           # 常用命令
├── conventions.md        # 编码规范 + 注意事项
└── modules/              # 核心模块说明
    ├── [模块名].md
    └── ...
```

#### SKILL.md 模板

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
{modules_table}

## 常用命令

详见 [commands.md](./commands.md)

## 开发规范

详见 [conventions.md](./conventions.md)
```

#### tech-stack.md 模板

```markdown
# 技术栈

## 运行环境

{runtime_info}

## 核心依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
{core_deps}

## 开发依赖

| 依赖 | 版本 | 用途 |
|------|------|------|
{dev_deps}
```

#### commands.md 模板

```markdown
# 常用命令

## 开发

{dev_commands}

## 构建

{build_commands}

## 测试

{test_commands}

## 其他

{other_commands}
```

#### conventions.md 模板

```markdown
# 开发规范

## 代码风格

{code_style}

## 目录约定

{dir_conventions}

## 注意事项

{notes}
```

#### modules/*.md 模板

```markdown
# 模块：{模块名}

## 目录结构

{dir_structure}

## 职责

{responsibility}

## 关键文件

| 文件 | 说明 |
|------|------|
{key_files}

## 依赖关系

- 依赖于：{dependencies}
- 被依赖：{dependents}
```

### 第五步：检查 CLAUDE.md / AGENTS.md

1. 读取项目根目录的 CLAUDE.md 和 AGENTS.md（如存在）
2. 与生成的 skill 内容对比
3. 识别以下类型的重复：
   - 技术栈说明
   - 目录结构说明
   - 常用命令
   - 编码规范

### 第六步：提示用户精简

输出类似：

```
已生成 project-structure skill 到 .claude/skills/project-structure/

检测到 CLAUDE.md 中以下内容与 skill 重复：
1. 技术栈说明（第 X-Y 行）
2. 目录结构说明（第 X-Y 行）

是否精简 CLAUDE.md？[Y/n]
```

用户确认后：
- 删除重复内容
- 添加引用指向 project-structure skill

精简后的引用格式：

```markdown
## 项目结构

详见 `.claude/skills/project-structure/`

## 开发命令

详见 `.claude/skills/project-structure/commands.md`
```

## 示例交互

```
用户: /project-init

AI: 正在分析项目结构...

    ✓ 检测到技术栈: React + TypeScript + Vite
    ✓ 识别到 4 个核心模块: components, hooks, api, utils

    正在生成 project-structure skill...

    ✓ 已生成到 .claude/skills/project-structure/
      - SKILL.md
      - tech-stack.md
      - commands.md
      - conventions.md
      - modules/components.md
      - modules/hooks.md
      - modules/api.md
      - modules/utils.md

    检测到 CLAUDE.md 中以下内容与 skill 重复：
    1. 技术栈说明（第 5-15 行）
    2. 目录结构说明（第 20-35 行）

    是否精简 CLAUDE.md？[Y/n]

用户: Y

AI: ✓ 已精简 CLAUDE.md，删除重复内容并添加引用。

    完成！现在可以通过以下方式使用：
    - 说"查看项目结构"加载 project-structure skill
    - 说"技术栈""常用命令""开发规范"查看具体内容
```

## 注意事项

1. 如果 `.claude/skills/project-structure/` 已存在，先询问用户是否覆盖
2. 模块识别基于常见命名约定，可能不完全准确，生成后用户可手动调整
3. conventions.md 中的规范需要根据项目实际情况推断，可能需要用户补充

## 验收标准

执行完成后必须满足：

- [ ] `.claude/skills/project-structure/` 目录已创建
- [ ] SKILL.md 包含完整的 frontmatter（name、description + 触发词）
- [ ] tech-stack.md 列出了核心依赖及其用途
- [ ] commands.md 包含开发、构建、测试三类命令
- [ ] 至少识别并生成了 1 个 modules/*.md 文件
- [ ] 如存在 CLAUDE.md/AGENTS.md，已提示用户精简重复内容

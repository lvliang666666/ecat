# Git 提交规范

> 定义提交信息格式、分支命名、危险操作边界。与 iteration-workflow.md（批次流程）、
> versioning.md（发版流程）配合使用。

## 提交信息（Conventional Commits）

格式：`<type>(<scope>): <subject>`

| type | 用途 |
|------|------|
| feat | 新功能 |
| fix | Bug 修复 |
| docs | 仅文档 |
| style | 格式调整（不影响逻辑） |
| refactor | 既非新增也非修复 |
| perf | 性能优化 |
| test | 测试相关 |
| chore | 构建/依赖/配置 |
| release | 版本发布 |

规则：

- subject 一行以内，不加句号，中文英文均可（跟随仓库既有惯例）
- scope 可选，用模块名（如 `chat` / `db` / `ui`），新项目前几个提交定下常用 scope 后保持一致
- **一个提交一件事**：功能、格式化、修复不混在一个提交里
- 特殊格式：
  - 合并提交：`merge: 合并<批次主题>（一句话列要点）`
  - 发版提交：`release: 发布 v<版本号>`

## 分支命名

| 分支 | 用途 | 生命周期 |
|------|------|---------|
| `main` | 主分支，始终可构建可发布 | 永久，所有 tag 打在 main |
| `feat/<主题>` | 新功能批次 | 合并后删除 |
| `fix/<主题>` | 修复批次 | 合并后删除 |

- 小改动（单文件、<20 行）可直接提交 main，不强制开分支
- 分支名用批次主题，不用条目堆砌（见 iteration-workflow.md）

## 提交纪律

- 提交前 `git status` 确认没有意外文件混入
- 不提交：构建产物、密钥、临时文件（确认 .gitignore 覆盖）
- 提交前验证必须全绿（验证标准见 code-discipline）
- 合并方式：批次分支一律 `--no-ff`，保留合并点

## 危险操作（必须单独确认，即使被催促）

- `git push --force` / `reset --hard` / `clean -f`
- 删除分支、删除 tag、移动已有 tag
- 修改 git config
- 丢弃工作区改动（`checkout -- <file>`）

替代习惯：force push 优先用 `--force-with-lease`（远程有新提交时拒绝，防误覆盖）。

## 反模式（禁止）

- ❌ "update code" / "修改" 这类无信息提交信息
- ❌ 一个提交混功能 + 格式化 + 修复
- ❌ 提交前不跑验证
- ❌ fast-forward 合并批次（丢失批次边界）

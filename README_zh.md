<div align="center">
  <h1>datapowers 📊</h1>
  <p><b>AI 智能体的数据挖掘超级大国 (Data Mining Superpowers for AI Agents)</b></p>
  
  <p>
    <a href="https://github.com/zpower426/datapowers/blob/main/LICENSE"><img src="https://img.shields.io/badge/License-MIT-yellow.svg" alt="License: MIT"></a>
    <a href="README.md"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
    <a href="https://claude.ai"><img src="https://img.shields.io/badge/Claude%20Code-Friendly-blue" alt="Claude Code Friendly"></a>
    <a href="https://github.com/obra/superpowers"><img src="https://img.shields.io/badge/%E7%81%B5%E6%84%9F%E6%9D%A5%E6%BA%90-superpowers-orange" alt="灵感来源 superpowers"></a>
  </p>
</div>

---

`datapowers` 是一套专为 Claude Code、Gemini CLI 及自主智能体打造的专业数据挖掘与机器学习工作流协议。它将软件工程的严谨性（TDD）与数据科学的「统计主权」完美融合——将泄漏防护、三层验证和基于证据的交付作为流水线中不可绕过的强制关卡。

## 🔍 为什么选择 datapowers？

**统计严谨性高于模型指标 (Statistical Integrity > Model Metrics)。** `datapowers` 不是提示词集合，它是一套**审计协议**。

- **🛡️ 泄漏防护** — 在任何评估开始之前，从源头上对时间序列和预处理中的特征泄漏进行系统性审计。
- **⚖️ 三层验证** — 物理层（Schema）、逻辑层（业务规则）和统计层（分布漂移）关卡阻止在脏数据上训练。
- **🚫 消除点估计幻觉** — 对所有报告结果强制要求置信区间和显著性检验。
- **🧠 假设驱动** — 强制在接触原始数据前定义可证伪的目标和基准预期。

---

## ⚙️ 工作原理：技能加载流程

`datapowers` 采用**基于 Hook 的按需加载**架构，灵感来源于 [superpowers](https://github.com/obra/superpowers)。

```
会话启动
     │
     ▼
hooks/session-start 触发
     │
     ├── 读取 skills/using-datapowers/SKILL.md
     │
     └── 作为会话上下文注入（EXTREMELY_IMPORTANT 标签）
               │
               ▼
         智能体现在了解：
         • 全部 20 个可用技能
         • 每个技能的触发关键词
         • 何时调用哪个技能
               │
               ▼
         分析师提出问题
               │
               ▼
         智能体匹配触发词 → 调用 Skill 工具
               │
               ├── 加载 skills/<name>/SKILL.md（铁律、硬关卡、执行程序）
               │
               └── 按需加载补充文件：
                   • 参考文档（如 assertion-anti-patterns.md）
                   • 压力测试场景（test-pressure-1.md，...）
                   • 智能体提示模板（analyst-prompt.md，...）
                   • 实用脚本（pipeline-pollution-detection.sh）
```

**核心设计原则：**
- **`using-datapowers` 始终加载** — 它是所有其他技能的路由表。
- **其他技能按需加载** — 避免不必要的上下文膨胀。
- **补充文件按范围加载** — 每个技能只加载自身所需的文件。
- **会话状态持久化于 `artifacts/analysis_manifest.json`** — 智能体可随时恢复任意会话，不丢失上下文。

---

## 📋 技能清单 (Skills Reference)

全部 20 个技能，按阶段组织。

### 第 0 阶段 — 入口与状态

| 技能 | 使用时机 | 核心产出 |
|------|----------|----------|
| `using-datapowers` | 会话启动时自动加载 | 路由表：所有技能 + 触发关键词 |
| `analysis-manifest` | 会话启动；「我们在哪一步？」；头脑风暴后 | `artifacts/analysis_manifest.json` — 会话状态的单一事实来源 |

### 第 1 阶段 — 设计

| 技能 | 使用时机 | 核心产出 |
|------|----------|----------|
| `brainstorming` | 「分析 X」、「设计规格」、「提假设」 | `docs/datapowers/specs/` 设计文档，含 ≥3 个可证伪假设 |
| `writing-analysis-plans` | 头脑风暴通过后 | `docs/datapowers/plans/` 计划，任务粒度 15–30 分钟，无占位符 |

### 第 2 阶段 — 数据理解

| 技能 | 使用时机 | 核心产出 |
|------|----------|----------|
| `data-profiling` | 新数据集；分发子智能体前 | `artifacts/data_profile.md` — 高密度无 PII 画像 |
| `data-exploration` | 首次探索数据集；执行 EDA | `docs/datapowers/eda/` 报告；泄漏候选列表 |
| `data-validation` | 任何模型训练或特征工程前 | Pandera 验证报告；BLOCK / PROCEED 裁决 |

### 第 3 阶段 — 特征工程与建模

| 技能 | 使用时机 | 核心产出 |
|------|----------|----------|
| `leakage-guard` | 时间序列数据集；特征工程评审前 | BLOCKED / NEEDS\_HUMAN\_REVIEW / APPROVED 裁决 |
| `feature-engineering` | 构建或变换特征 | 已拟合的转换器存入 `artifacts/`；特征注册表更新 |
| `test-driven-data-science` | 任何 `model.fit()` 调用前 | 三层断言结果；CRITICAL 失败阻断训练 |
| `model-selection` | 选择候选模型 | 基准对比表；Optuna HPO 结果（≥50 次试验） |
| `model-evaluation` | 最终测试集评估 | Bootstrap 置信区间；SHAP 摘要；测试集一次性使用关卡 |

### 第 4 阶段 — 执行与审查

| 技能 | 使用时机 | 核心产出 |
|------|----------|----------|
| `executing-plans` | 「开始任务」、「执行计划」 | 每个任务两阶段审查：统计正确性 → 代码质量 |
| `subagent-driven-analysis` | 多任务并行分析 | 并行分析子智能体，独立上下文，审查关卡 |
| `requesting-statistical-review` | 「审计结果」、「显著性」、任务完成后 | 统计审查裁决：APPROVED / ISSUES FOUND / BLOCKED |
| `debugging-pipelines` | 流水线报错；模型行为异常；性能下降 | 根因调查日志；PSI 漂移报告 |

### 第 5 阶段 — 交付

| 技能 | 使用时机 | 核心产出 |
|------|----------|----------|
| `verification-before-delivery` | 「完成了」、「交付」、任何交付前 | 产物完整性检查单；可重现性确认 |
| `report-writing` | 最终利益相关者报告 | 含可重现性头信息、置信区间和显著性检验的报告 |
| `finishing-an-analysis-branch` | 分析完成；准备交付 | 提交 / PR / 归档选项；Manifest 门控交付 |

### 元技能

| 技能 | 使用时机 | 核心产出 |
|------|----------|----------|
| `writing-data-skills` | 「新建技能」、「添加技能」、「贡献技能」 | 通过统计压力测试（3 个场景）的新 SKILL.md |

---

## 🚀 核心工作流 (The Core Workflow)

```
brainstorming → writing-analysis-plans
      │
      ▼
data-profiling → data-exploration → data-validation
      │
      ▼
leakage-guard → feature-engineering → test-driven-data-science
      │
      ▼
model-selection → model-evaluation
      │
      ▼
executing-plans（每个任务含 requesting-statistical-review）
      │
      ▼
verification-before-delivery → report-writing → finishing-an-analysis-branch
```

**在任意步骤：** `analysis-manifest` 追踪已完成的阶段。`debugging-pipelines` 处理任何意外失败。`subagent-driven-analysis` 可并行化独立任务。

---

## 🛠️ 安装

### Claude Code

```bash
# 安装插件
/plugin install https://github.com/zpower426/datapowers

# 或克隆后本地安装
git clone https://github.com/zpower426/datapowers
cd datapowers
/plugin install .
```

工作原理：`.claude-plugin/plugin.json` 注册 hooks 目录。每次会话启动时，`hooks/session-start` 自动触发，将 `using-datapowers` 技能内容注入会话上下文。

### Gemini CLI

```bash
gemini extensions install https://github.com/zpower426/datapowers
```

`GEMINI.md` 文件和 `gemini-extension.json` 清单负责技能路径注册。

### OpenCode

```bash
git clone https://github.com/zpower426/datapowers ~/.opencode/plugins/datapowers
```

`.opencode/plugins/datapowers.js` 插件通过系统提示注入引导上下文，并自动注册技能目录。

### Cursor / Codex

参见 `.cursor-plugin/plugin.json` 和 `.codex/INSTALL.md`。

---

## ⚖️ 铁律 (Iron Laws)

| 领域 | 铁律 |
| :--- | :--- |
| **EDA** | **无探索，不建模 (NO MODELING WITHOUT EDA)** |
| **验证** | **无验证，不训练 (NO TRAINING WITHOUT DATA QUALITY VALIDATION)** |
| **泄漏** | **任何转换器不得在训练/测试集划分前拟合于完整数据集** |
| **评估** | **测试集仅在最终评估时使用一次** |
| **交付** | **无置信区间和显著性检验，不交付结论** |
| **审查** | **统计审计永远先于代码质量审查** |

---

## 📈 Star 历史

[![Star History Chart](https://api.star-history.com/svg?repos=zpower426/datapowers&type=Date)](https://star-history.com/#zpower426/datapowers&Date)

## 🤝 贡献

欢迎贡献！请先阅读 `writing-data-skills` 技能——每个新技能在合并前必须通过**统计压力测试**（均衡数据、1:100 极端不均衡、n < 200 小样本）。

<a href="https://github.com/zpower426/datapowers/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=zpower426/datapowers" />
</a>

## ❤️ 致谢

`datapowers` 深受 **Jesse Vincent (@obra)** 发起的 **[superpowers](https://github.com/obra/superpowers)** 项目的启发，并站在其肩膀上构建。

基于 Hook 的按需技能加载架构、铁律模式和硬关卡设计均来自 `superpowers` 家族——在此基础上针对数据科学的统计严谨性需求进行了专项扩展。

## 📜 开源协议

[MIT License](LICENSE)

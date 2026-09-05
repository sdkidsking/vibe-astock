# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概况

A股短线每日复盘看板：拉取涨停池/龙虎榜/板块资金 → 纯计算派生情绪指标 → LangGraph 五分析师 → 裁判收敛为结构化研判。

- 定位红线：不推荐个股、不给买卖点位，只做客观陈述。
- 个人交易数据（journal/trades）禁止进入任何 AI prompt，有测试锁住。

## 常用命令（Windows，Git Bash 下）

```bash
# 激活环境后（.venv\Scripts\activate）：
python server.py              # Web 后端，端口 8910（VIBE_PORT 覆盖），服务 frontend/dist
python main.py [YYYY-MM-DD]   # CLI 直接跑当日复盘；只能跑已收盘场次
python -m pytest -q           # 全部测试（均为 unit）
python -m pytest tests/test_core_logic.py -k "test_name"   # 跑单个测试

# 前端（改前端后必须重新 build，否则 server 服务旧产物/503）：
cd frontend && npm run build  # = tsc -b && vite build，类型检查即唯一前端质量门槛
npm run dev -- --port 5910 --strictPort   # dev server，/api 代理到 127.0.0.1:8910
```

## 硬约束

- `vr/` 是原样并入的上游 Vibe-Research 后端，日后更新是纯拷贝覆盖 —— **不要改成包内相对 import**。
- tests/conftest.py autouse 拦截 socket.connect（禁网）：新测试必须 monkeypatch 数据源，否则当场报错。
- 仓库无 formatter/linter 配置，沿续现状：Python 用 `from __future__ import annotations`、全量类型标注、`@dataclass(frozen=True)`、中文注释写"为什么"；TS 用 strict + 路径别名 `@/ → src/`、不用 React.FC。

## 高危坑

- **绝不能安装旧 `py_mini_racer`**：会与 mini-racer 装进同一目录互相覆盖，表现为"板块资金/资金轮动"静默空白（sectors: []）。修复命令见 requirements.txt 注释。
- Windows 下环境变量不能前缀写在命令里（`FOO=1 python x.py` 无效），先 `$env:FOO=1` 或分开设置。
- `.gitignore` 里 `.venv` 故意不带斜杠（防符号链接变 gitlink），别"顺手修正"。

## LLM 配置（双后端）

1. OpenAI 兼容：`~/.config/mimo/mimo.env` 读 `MIMO_API_KEY / MIMO_BASE_URL / MIMO_MODEL`
2. 本机 CLI 免 key：`VIBE_LLM_CLI=claude`

## Git

- 单分支 main，直接推 origin；**upstream（simonlin1212/vibe-astock）只读，禁止 push**。
- 提交风格：conventional 前缀 + 中文主题（`feat:` `fix:` `docs:` `ui:`）。
- 运行时数据在 `~/.duanxian-agents/` 与 `~/.vibe-research/`，`.env` 一律不进 git。

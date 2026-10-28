# IDCX AI Chat

多模型 AI 聊天平台：一个界面切换 OpenAI、Anthropic Claude、Google Gemini、
OpenAI 兼容 API 与统一 AI Gateway。Next.js App Router + React 19 + TypeScript +
Tailwind CSS v4，深海军蓝 + 蓝/青强调色，响应式（含手机端抽屉侧边栏）。

> **诚实状态**：本项目第一阶段已实现完整 UI、流式聊天、多轮对话、模型注册表、
> 统一服务端调用、后台与设置页、Supabase SQL 迁移。但**没有真实服务商密钥时，
> 不会返回真实回答**——会明确返回 `MODEL_NOT_CONFIGURED`。真实 OpenAI / Claude /
> Gemini 调用**尚未用真实密钥验证**（见“尚未完成”）。

## 快速启动（本地）

```bash
cd idcx-ai-chat
npm install
cp .env.example .env.local   # 只填你用的 key，不要提交 .env.local
npm run dev
# 打开 http://localhost:3000 ，聊天在 /chat，后台在 /admin，设置在 /settings
```

生产构建 / 启动：

```bash
npm run build
npm run start   # 默认 http://localhost:3000
```

## 需要填写的环境变量

见 `.env.example`。最少填一个即可开始真实聊天：

| 变量 | 用途 |
|---|---|
| `OPENAI_API_KEY` | OpenAI 模型 |
| `ANTHROPIC_API_KEY` | Claude 模型 |
| `GOOGLE_GENERATIVE_AI_API_KEY` | Gemini 模型 |
| `OPENAI_COMPATIBLE_BASE_URL` + `OPENAI_COMPATIBLE_API_KEY` | 自定义 OpenAI 兼容服务（必须是公开 https 地址，内网地址会被 SSRF 校验拒绝） |
| `AI_GATEWAY_URL` + `AI_GATEWAY_API_KEY` | 统一网关模式（Mode A） |
| `IDCX_DEFAULT_MODEL` | 默认模型 modelId，默认 `openai-gpt-5-mini` |
| `NEXT_PUBLIC_SUPABASE_URL` / `NEXT_PUBLIC_SUPABASE_ANON_KEY` / `SUPABASE_SERVICE_ROLE_KEY` | Supabase（可选；缺失时为演示模式） |
| `IDCX_MOCK_MODEL=1` | **仅测试**的 Mock 模型，生产绝不要开启 |

注册表里的模型 ID 是**可配置示例**，不是“保证可用”的承诺：
服务商会改名、下线模型，请在服务商文档/控制台确认后，用
`OPENAI_MODEL` / `ANTHROPIC_MODEL` / `GOOGLE_MODEL` 等环境变量覆盖，
或直接改 `lib/ai/registry.ts`。

## 目录结构

```
app/
  page.tsx                 # 首页（品牌介绍 + 入口）
  chat/page.tsx            # 聊天主页
  chat/[id]/page.tsx       # 按会话 ID 打开聊天（与 localStorage 会话对应）
  settings/page.tsx        # 设置 / 演示模式说明 / .env 指引
  admin/page.tsx           # 模型管理（演示切换、连接测试、用量）
  api/
    chat/route.ts          # POST 流式聊天（SSE，60s 超时，限流，大小限制）
    models/route.ts        # GET 公开注册表（无密钥）；POST 演示切换
    models/test/route.ts   # POST 配置状态检查（不返回密钥，不做计费调用）
    conversations/route.ts # 演示：返回空结构 + 诚实说明
    usage/route.ts         # 本地内存用量汇总（无费用估算）
components/chat/ChatClient.tsx  # 侧边栏、模型选择器、消息、输入框、流式渲染
lib/ai/
  types.ts registry.ts router.ts
  providers/openai.ts anthropic.ts google.ts openai-compatible.ts gateway.ts
lib/security.ts            # SSRF 校验、密钥掩码、限流
lib/usage.ts               # 本地内存用量日志（演示）
lib/supabase/client.ts     # 缺 env 时返回 null 的安全客户端
lib/supabase/server.ts     # 服务端 service-role 客户端（不进浏览器）
supabase/migrations/0001_init.sql  # profiles / conversations / messages / model_configs / usage_logs + RLS
```

## Supabase 手动配置步骤（未自动完成，需要你操作）

1. 在 Supabase 新建项目，记下 Project URL 与 anon key、service_role key。
2. 在 Supabase SQL Editor 里执行 `supabase/migrations/0001_init.sql`。
3. 在 Authentication → Providers 里启用 Email（或你需要的登录方式）。
4. 把三个 key 填入 `.env.local`（service_role key 只放服务端，绝不放前端代码）。
5. **管理员标志尚未实现**：迁移文件里已注明——如需真正的管理员写权限，
   请先给 `profiles` 加 `is_admin boolean`，再按文件末尾注释启用对应的 RLS 策略。
   在此之前，`/admin` 的切换只是演示，不写数据库。
6. 会话持久化到 Supabase 需要再接 Supabase Auth + 把 ChatClient 的
   localStorage 读写换成 Supabase 查询（已在代码与迁移中预留结构，未接线）。

## 部署

### Vercel
1. 把本仓库推到 Git，Vercel Import 该项目。
2. 在 Vercel → Settings → Environment Variables 里填与 `.env.example` 相同的变量。
3. Deploy。不要把 `.env.local` 提交到 Git。

### VPS / Docker（建议）
- VPS：`npm install && npm run build && npm run start`，用 systemd / PM2 托管，
  前面放 Nginx 反向代理 + HTTPS，环境变量放在 systemd EnvironmentFile 或 PM2 ecosystem 里。
- Docker：仓库已提供 `Dockerfile` + `.dockerignore`（`node:24-alpine` 多阶段构建，
  运行时以 `npm run start` 启动并注入环境变量）：
  ```bash
  docker build -t idcx-ai-chat .
  docker run -p 3000:3000 --env-file .env.local idcx-ai-chat
  ```
  注意：该 Dockerfile 是在初始交付后补加的，编写环境没有 Docker，因此
  `docker build` 尚未实测，上生产前请先实际构建并跑一次 `/` 与 `/api/models`。

## 测试（本次交付实际执行过的命令与结果）

```bash
npx tsc --noEmit
npm run lint
npm run build
npm run start   # 或 IDCX_MOCK_MODEL=1 npm run start（测试 Mock 流式）
curl -s http://localhost:3000/
curl -s http://localhost:3000/chat
curl -s http://localhost:3000/api/models
# 无 key 的错误路径：
curl -s -X POST http://localhost:3000/api/chat -H 'Content-Type: application/json' \
  -d '{"modelId":"openai-gpt-5-mini","messages":[{"role":"user","content":"hi"}]}'
# Mock 流式路径（需 IDCX_MOCK_MODEL=1 启动）：
curl -s -N -X POST http://localhost:3000/api/chat -H 'Content-Type: application/json' \
  -d '{"modelId":"mock-test","messages":[{"role":"user","content":"hello mock"}]}'
```

具体结果见交付报告（构建、类型检查、lint、curl 输出）。每次改代码后请重新跑
`npx tsc --noEmit && npm run build`。

## 常见问题排查

| 现象 | 原因 / 做法 |
|---|---|
| `MODEL_NOT_CONFIGURED` | 该模型服务商的 Key / 网关未在服务器 env 配置。检查 `.env.local` 并重启。 |
| 模型在选择器里灰色不可用 | `enabled=false` 或未配置，二者任一都会禁用发送。 |
| 自定义地址被拒绝 | 必须是公开 https 地址；http、localhost、内网段会被 SSRF 校验拒绝。 |
| 429 Too many requests | 本地内存限流：每 IP 每分钟 30 次，生产请用网关/WAF 限流替代。 |
| 聊天记录重启/换设备后不见 | 演示模式只用 localStorage，换浏览器即不见；接 Supabase 后才持久化。 |
| 构建时提示 Next.js 安全版本 | 请保持 `next` 在 15.5.x 的最新补丁版（本项目已用 15.5.9）。 |

## 安全要点（已实现）

- API Key 只在服务端读取；`/api/models`、`/api/models/test` 永远不返回完整密钥。
- `/api/chat` 只接受注册表里的 `modelId`，不信任前端传来的服务商信息。
- 请求体大小、消息条数与单条长度、60s 超时、Abort 取消、简单限流均已实现。
- 错误返回经过清洗，不输出堆栈与密钥。
- 自定义 Endpoint 只允许公开 https 地址。

## 尚未完成 / 未验证（诚实清单）

- ❌ 真实 OpenAI / Claude / Gemini 调用：**未验证**，因为没有提供任何真实 API Key。
  代码按 Vercel AI SDK v5 的公开接口编写，构建与 Mock 流式已通过，但真实服务商
  的模型 ID、参数与流式细节仍需持 key 实测后确认。
- ❌ Supabase Auth 登录/注册页面、会话落库、RLS 实测：SQL 已提供，Auth 未接线，
  应用在无 env 时明确为演示模式。
- ❌ 后台持久化与真实管理员权限：`/admin` 切换为演示行为；`is_admin` 标志待实现。
- ❌ 单元测试套件：未接入测试运行器；`tests/smoke.test.ts` 只是手动检查清单，
  本次验证用的是真实服务器 + curl。
- ⚠️ Dockerfile 已补加，但 `docker build` 未实测（编写环境无 Docker），上生产前需实测。
- ❌ CI、图片/多模态输入、工具调用：未实现；注册表里对应能力标记为 false，
  不宣称支持。
- ❌ 成本统计：只统计服务商返回的 token（无则为 0），不估算、不编造费用。
- ⚠️ 限流与 SSRF 校验是本地基础实现，生产请配合网关/WAF 与 DNS 解析校验加强。

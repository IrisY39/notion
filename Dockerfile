# syntax=docker/dockerfile:1

########## 1️⃣  构建阶段 #######################################################
FROM node:20-slim AS builder
WORKDIR /app

# ① 只复制包描述文件，安装依赖，命中 npm 缓存
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm,id=npm-cache \
    npm ci --ignore-scripts --omit-dev

# ② 复制源代码，构建
COPY . .
RUN --mount=type=cache,target=/root/.npm,id=npm-cache \
    npm run build

# ③ 将包链接到全局，方便运行阶段直接用可执行文件
RUN --mount=type=cache,target=/root/.npm,id=npm-cache \
    npm link

########## 2️⃣  运行阶段 #######################################################
FROM node:20-slim

# OpenAPI JSON（可选，给 swagger 用）
COPY scripts/notion-openapi.json /usr/local/scripts/

# 拷贝全局包文件和可执行脚本
COPY --from=builder /usr/local/lib/node_modules/@notionhq/notion-mcp-server \
                     /usr/local/lib/node_modules/@notionhq/notion-mcp-server
COPY --from=builder /usr/local/bin/notion-mcp-server \
                     /usr/local/bin/notion-mcp-server

# 自定义请求头（如需在 Notion API 加额外 header）
ENV OPENAPI_MCP_HEADERS="{}"

# 服务器监听端口
ENV PORT=3000
EXPOSE ${PORT}

# 启动：打开 SSE (--enable-stream) 让 Kelivo 不会“transport disconnected”
ENTRYPOINT ["notion-mcp-server", "--port", "${PORT}", "--enable-stream"]

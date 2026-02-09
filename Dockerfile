# syntax=docker/dockerfile:1
FROM node:20-slim AS builder
WORKDIR /app

COPY package*.json ./
RUN npm ci --ignore-scripts --omit-dev     # ← 不再挂缓存

COPY . .
RUN npm run build

RUN npm link                               # ← 同样去掉 --mount

FROM node:20-slim
COPY scripts/notion-openapi.json /usr/local/scripts/
COPY --from=builder /usr/local/lib/node_modules/@notionhq/notion-mcp-server /usr/local/lib/node_modules/@notionhq/notion-mcp-server
COPY --from=builder /usr/local/bin/notion-mcp-server /usr/local/bin/notion-mcp-server

ENV OPENAPI_MCP_HEADERS="{}"

# 进程默认监听 3000，Railway 注入 $PORT 时会覆盖
ENV PORT=3000
EXPOSE 3000

# 启动：始终用 $PORT；本地 docker run 没 $PORT 时退回 3000
ENTRYPOINT ["sh", "-c", "notion-mcp-server --port ${PORT:-3000} --enable-stream"]


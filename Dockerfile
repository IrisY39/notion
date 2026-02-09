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

ENV PORT=3000            # 明写 3000
EXPOSE 3000
ENTRYPOINT ["notion-mcp-server", "--port", "3000", "--enable-stream"]

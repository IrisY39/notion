# syntax=docker/dockerfile:1
FROM node:20-slim AS builder
WORKDIR /app
COPY package*.json ./
RUN --mount=type=cache,target=/root/.npm \
    npm ci --ignore-scripts --omit-dev
COPY . .
RUN --mount=type=cache,target=/root/.npm npm run build
RUN --mount=type=cache,target=/root/.npm npm link

FROM node:20-slim
COPY scripts/notion-openapi.json /usr/local/scripts/
COPY --from=builder /usr/local/lib/node_modules/@notionhq/notion-mcp-server /usr/local/lib/node_modules/@notionhq/notion-mcp-server
COPY --from=builder /usr/local/bin/notion-mcp-server /usr/local/bin/notion-mcp-server

ENV OPENAPI_MCP_HEADERS="{}"
ENV PORT=3000
EXPOSE ${PORT}
ENTRYPOINT ["notion-mcp-server", "--port", "${PORT}", "--enable-stream"]

# Stage 1: Build the offline web application
FROM oven/bun:1.4.2 AS client-build
WORKDIR /client
COPY client/package.json client/bun.lock ./
RUN bun install --frozen-lockfile --ignore-scripts
COPY client/ ./
COPY docs/third-party-notices.md /docs/third-party-notices.md
RUN bun run build

# Stage 2: Serve the static application with Nginx
FROM nginx:alpine
COPY --from=client-build /client/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

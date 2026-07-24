# syntax = docker/dockerfile:1

# ---- Build stage ----
ARG NODE_VERSION=20.19.0
FROM node:${NODE_VERSION}-slim AS build

WORKDIR /app

COPY --link package.json package-lock.json ./
RUN npm install --production=false --legacy-peer-deps

COPY --link . .

# Strip devDependencies (mocha, eslint, etc.) before the final copy.
RUN npm prune --production --legacy-peer-deps

# ---- Runtime stage ----
FROM node:${NODE_VERSION}-slim AS runtime

LABEL org.opencontainers.image.title="CardMesh rest-api"

WORKDIR /app
ENV NODE_ENV=production

# Non-root, unprivileged runtime user - this is an internal-only service
# reached over the private Docker network, but it still shouldn't run as root.
RUN groupadd --system --gid 1001 nodeapp \
  && useradd --system --uid 1001 --gid nodeapp --home /app --shell /usr/sbin/nologin nodeapp

# Only copy what the running app actually needs - no tests/, no docs/, no
# .github/, no lockfiles left lying around in the final layer.
COPY --from=build --chown=nodeapp:nodeapp /app/node_modules ./node_modules
COPY --from=build --chown=nodeapp:nodeapp /app/src ./src
COPY --from=build --chown=nodeapp:nodeapp /app/app.js ./app.js
COPY --from=build --chown=nodeapp:nodeapp /app/server.js ./server.js
COPY --from=build --chown=nodeapp:nodeapp /app/package.json ./package.json

USER nodeapp

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD node -e "require('http').get('http://localhost:8080/api/v1/health', r => process.exit(r.statusCode < 500 ? 0 : 1)).on('error', () => process.exit(1))"

CMD [ "node", "server.js", "--omit=dev" ]

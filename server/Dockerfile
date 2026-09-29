# syntax=docker/dockerfile:1

# One image for both processes: the API is the default command, and the worker
# runs the same image as `node dist/worker.js` (see `pnpm start:worker`).

FROM node:24-slim AS base
WORKDIR /app
RUN npm install --global pnpm@12.8.1

FROM base AS build
COPY package.json pnpm-lock.yaml ./
# pnpm 12 treats unapproved dependency build scripts as an error; the project
# intentionally ignores them (transitive native/optional accelerators), so the
# strict check is turned off and installs behave as they did before pnpm 12.
RUN pnpm install --frozen-lockfile --config.strict-dep-builds=false
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN pnpm run build

FROM base AS runtime
ENV NODE_ENV=production
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod --config.strict-dep-builds=false
COPY --from=build /app/dist ./dist
EXPOSE 3000
USER node
CMD ["node", "dist/main.js"]

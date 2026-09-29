# syntax=docker/dockerfile:1

# One image for both processes: the API is the default command, and the worker
# runs the same image as `node dist/worker.js` (see `pnpm start:worker`).

FROM node:24-slim AS base
WORKDIR /app
RUN npm install --global pnpm@12.8.1

FROM base AS build
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile
COPY tsconfig.json tsconfig.build.json ./
COPY src ./src
RUN pnpm run build

FROM base AS runtime
ENV NODE_ENV=production
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
RUN pnpm install --frozen-lockfile --prod
COPY --from=build /app/dist ./dist
EXPOSE 3000
USER node
CMD ["node", "dist/main.js"]

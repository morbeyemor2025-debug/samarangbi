# ── Stage 1 : Build ──────────────────────────────────────────────────────────
FROM node:20-alpine AS builder

# Active pnpm via corepack (inclus dans Node 20)
RUN corepack enable && corepack prepare pnpm@10.4.1 --activate

WORKDIR /app

# Copier les fichiers de dépendances en premier (cache Docker)
COPY package.json pnpm-lock.yaml ./
COPY patches/ ./patches/

# Installer toutes les dépendances (dev incluses pour le build)
RUN pnpm install --frozen-lockfile

# Copier le reste du code source
COPY . .

# Build frontend (Vite) + backend (esbuild)
RUN pnpm run build

# ── Stage 2 : Production ─────────────────────────────────────────────────────
FROM node:20-alpine AS runner

RUN corepack enable && corepack prepare pnpm@10.4.1 --activate

WORKDIR /app

# Copier uniquement ce qui est nécessaire en production
COPY package.json pnpm-lock.yaml ./
COPY patches/ ./patches/

# Installer uniquement les dépendances de production
RUN pnpm install --frozen-lockfile --prod

# Copier le build depuis le stage précédent
COPY --from=builder /app/dist ./dist

# Port Railway (Railway injecte $PORT automatiquement)
ENV NODE_ENV=production
EXPOSE 3000

CMD ["node", "dist/index.js"]

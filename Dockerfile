# OpenReply — self-host image (web + worker share this image)
FROM node:22-slim
WORKDIR /app

# openssl + ca-certificates required by Prisma engines
RUN apt-get update \
    && apt-get install -y --no-install-recommends openssl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

ENV NEXT_TELEMETRY_DISABLED=1

# Install all deps (devDeps needed for `next build` and for `tsx` at worker runtime)
COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Dummy values so `prisma generate` / `next build` don't choke on missing env at build time.
# Real values are injected at runtime via the compose `environment:` block.
ENV DATABASE_URL="postgresql://build:build@localhost:5432/build" \
    NEXTAUTH_URL="http://localhost:3000" \
    NEXTAUTH_SECRET="build-time-placeholder-secret-000" \
    ENCRYPTION_KEY="0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef" \
    INSTAGRAM_APP_ID="build" INSTAGRAM_APP_SECRET="build" \
    FACEBOOK_APP_SECRET="build" WEBHOOK_VERIFY_TOKEN="build" \
    REDIS_URL="redis://localhost:6379"

RUN npm run build

EXPOSE 3000
CMD ["npm", "run", "start"]

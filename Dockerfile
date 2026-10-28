# IDCX AI Chat — VPS / Docker deployment
# Build:   docker build -t idcx-ai-chat .
# Run:     docker run -p 3000:3000 --env-file .env.local idcx-ai-chat
# API keys and Supabase credentials are injected at runtime via environment
# variables only; never bake them into the image (see .env.example).
# Note: this Dockerfile was added after the initial delivery and its
# `docker build` step has NOT been verified in this environment (no Docker
# daemon available here). Verify with a real build before production use.

FROM node:24-alpine AS builder
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:24-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
ENV PORT=3000
ENV HOSTNAME=0.0.0.0
# next start needs the built output, public assets, and installed deps.
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
USER node
EXPOSE 3000
CMD ["npm", "start"]

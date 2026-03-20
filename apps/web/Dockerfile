FROM node:20-slim AS build

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .

# VITE_* vars must be present at build time — they get baked into the bundle
ARG VITE_SUPABASE_URL
ARG VITE_SUPABASE_ANON_KEY
ARG VITE_API_URL=http://localhost:8000
ENV VITE_SUPABASE_URL=$VITE_SUPABASE_URL
ENV VITE_SUPABASE_ANON_KEY=$VITE_SUPABASE_ANON_KEY
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

FROM node:20-slim
RUN npm install -g serve
COPY --from=build /app/dist /app
EXPOSE 3000
CMD ["serve", "-s", "/app", "-l", "3000"]

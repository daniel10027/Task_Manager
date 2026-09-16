# ---- Stage 1: build the static assets ----
FROM node:20-alpine AS build
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY . .

# Baked into the static bundle at build time (Vite env vars don't exist at
# container runtime). Leave unset for docker-compose, where the app calls a
# relative /api path that nginx.conf proxies to the `backend` service.
# For a standalone deploy against a real backend origin (e.g. Cloud Run),
# pass it explicitly:
#   docker build --build-arg VITE_API_URL=https://api.example.com -t frontend .
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL

RUN npm run build

# ---- Stage 2: serve with nginx ----
FROM nginx:alpine AS runtime

COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

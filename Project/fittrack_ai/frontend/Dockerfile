# Build stage
FROM node:22-alpine AS build

WORKDIR /app

COPY fittrack-frontend/package*.json ./

RUN npm ci

COPY fittrack-frontend/ .

ARG VITE_API_URL
ARG VITE_KEEP_ALIVE_MINUTES=10
ENV VITE_API_URL=$VITE_API_URL
ENV VITE_KEEP_ALIVE_MINUTES=$VITE_KEEP_ALIVE_MINUTES

RUN npm run build

# Runtime stage
FROM nginx:alpine

COPY --from=build /app/dist /usr/share/nginx/html

COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

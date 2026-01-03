# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:3.19.0 AS build

WORKDIR /app

# Copy dependency definitions
COPY pubspec.yaml pubspec.lock ./

# Install dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Build for web
RUN flutter build web --release --no-tree-shake-icons

# Stage 2: Serve with Nginx
FROM nginx:alpine

# Copy build artifacts
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy custom Nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]

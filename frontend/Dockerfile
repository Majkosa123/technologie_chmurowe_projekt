# frontend/Dockerfile
FROM node:16-alpine AS build
WORKDIR /app

# Copy package files
COPY package*.json ./
RUN npm ci --only=production

# Copy source code
COPY . .

# Build arguments for React app
ARG REACT_APP_KEYCLOAK_URL
ARG REACT_APP_KEYCLOAK_REALM
ARG REACT_APP_KEYCLOAK_CLIENT_ID
ARG REACT_APP_API_URL

# Set environment variables for build
ENV REACT_APP_KEYCLOAK_URL=$REACT_APP_KEYCLOAK_URL
ENV REACT_APP_KEYCLOAK_REALM=$REACT_APP_KEYCLOAK_REALM
ENV REACT_APP_KEYCLOAK_CLIENT_ID=$REACT_APP_KEYCLOAK_CLIENT_ID
ENV REACT_APP_API_URL=$REACT_APP_API_URL

# Build the app
RUN npm run build

# Production stage
FROM nginx:alpine

# Copy custom nginx config
COPY nginx.conf /etc/nginx/nginx.conf

# Copy built app
COPY --from=build /app/build /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]

FROM node:16-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production && npm cache clean --force
COPY . .

FROM node:16-alpine
WORKDIR /app
COPY --from=build /app .
EXPOSE 5001
CMD ["node", "server.js"]
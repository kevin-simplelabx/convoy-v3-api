FROM node:20-alpine
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm install --omit=dev && npm cache clean --force
COPY . .
ENV NODE_ENV=production PORT=4000
EXPOSE 4000
USER node
CMD ["node", "server.js"]

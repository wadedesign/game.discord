# Stage 1: Build the Next.js app and compile TypeScript
FROM node:18-alpine AS builder

WORKDIR /app

# Install Python and build dependencies required for node-gyp
RUN apk add --no-cache python3 make g++ pkgconfig pixman-dev cairo-dev pango-dev jpeg-dev giflib-dev librsvg-dev

# Install dependencies
COPY package*.json ./
RUN npm ci --silent

# Copy the rest of the app's source code, including .env.local
COPY . .

# Build the Next.js app and TypeScript files
RUN npm run build


# Stage 2: Run the app and updater
FROM node:18-alpine

WORKDIR /app

# Install runtime dependencies along with Python and other build tools
RUN apk add --no-cache python3 make g++ pkgconfig pixman-dev cairo-dev pango-dev jpeg-dev giflib-dev librsvg-dev

# Install production dependencies, including tsx
COPY package*.json ./
RUN npm ci --only=production && npm install tsx --global

# Copy built assets from the builder stage
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/public ./public
COPY --from=builder /app/scripts ./scripts

# Copy the .env file
COPY .env .env

# Expose the port the app runs on
EXPOSE 4596

# Start the Next.js app, then delay running the updater script using tsx
CMD ["sh", "-c", "npm start & sleep 5 && tsx scripts/run-updater.ts"]

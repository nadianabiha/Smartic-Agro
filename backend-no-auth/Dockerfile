# Stage 1: Base image with Node.js
FROM node:18-alpine AS base

# Install Python for ML service
RUN apk add --no-cache python3 py3-pip

# Stage 2: Dependencies
FROM base AS dependencies

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy all dependencies for development build
RUN npm ci

# Stage 3: Build (if needed)
FROM base AS build

WORKDIR /app

# Copy dependencies from dependencies stage
COPY --from=dependencies /app/node_modules ./node_modules

# Copy application code
COPY . .

# Stage 4: Production
FROM base AS production

WORKDIR /app

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Copy production dependencies
COPY --from=dependencies /app/node_modules ./node_modules

# Copy application code
COPY --chown=nodejs:nodejs . .

# Install Python dependencies for ML service
RUN pip3 install --no-cache-dir pandas numpy scikit-learn joblib --break-system-packages

# Set user
USER nodejs

# Expose port
EXPOSE 5010

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
    CMD node -e "require('http').get('http://localhost:5010/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"

# Start application
CMD ["node", "src/server.js"]

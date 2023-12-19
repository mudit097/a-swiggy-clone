# Use Node.js 16 slim as the base image
FROM node:16

# Set working directory
WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN npm install

# Copy application code and build React app
COPY . .
RUN npm run build

# Expose port 3000
EXPOSE 3000

# Start Node.js server serving the React app
CMD ["npm", "start"]

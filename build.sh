#!/bin/bash

# Netlify build script
echo "🚀 Starting Netlify build..."

# Install dependencies
echo "📦 Installing dependencies..."
npm install

# Create public directory if it doesn't exist
mkdir -p public

# Copy admin files to public
if [ -d "public/admin" ]; then
    echo "📁 Admin files already exist"
else
    echo "📁 Creating admin directory..."
    mkdir -p public/admin
fi

echo "✅ Build completed successfully!" 
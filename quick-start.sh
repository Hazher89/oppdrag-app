#!/bin/bash

echo "🚀 DriveDispatch Backend Quick Start"
echo "====================================="

# Check if Node.js is installed
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js v16 or higher."
    echo "Download from: https://nodejs.org/"
    exit 1
fi

# Check if npm is installed
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed. Please install npm."
    exit 1
fi

echo "✅ Node.js and npm are installed"

# Check if MongoDB is running
if ! pgrep -x "mongod" > /dev/null; then
    echo "⚠️  MongoDB is not running. Please start MongoDB first:"
    echo "   macOS: brew services start mongodb/brew/mongodb-community"
    echo "   Linux: sudo systemctl start mongodb"
    echo "   Windows: Start MongoDB service from Services"
    echo ""
    read -p "Press Enter after starting MongoDB..."
fi

echo "✅ MongoDB is running"

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -ne 0 ]; then
    echo "❌ Failed to install dependencies"
    exit 1
fi

echo "✅ Dependencies installed"

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "🔧 Creating .env file..."
    cp env.example .env
    
    # Generate a random JWT secret
    JWT_SECRET=$(openssl rand -base64 32)
    sed -i.bak "s/your-super-secret-jwt-key-change-this-in-production/$JWT_SECRET/" .env
    
    echo "✅ .env file created with secure JWT secret"
else
    echo "✅ .env file already exists"
fi

# Set up database
echo "🗄️  Setting up database..."
node setup.js

if [ $? -ne 0 ]; then
    echo "❌ Failed to set up database"
    exit 1
fi

echo "✅ Database setup completed"

# Create uploads directory
echo "📁 Creating upload directories..."
mkdir -p uploads/pdfs
mkdir -p uploads/chat

echo "✅ Upload directories created"

echo ""
echo "🎉 Setup completed successfully!"
echo ""
echo "📋 Next steps:"
echo "1. Start the server: npm start"
echo "2. Access admin panel: http://localhost:3000/admin"
echo "3. Login with sample admin: +1987654321 / admin123456"
echo "4. Update iOS app API URL to: http://localhost:3000/api/v1"
echo ""
echo "📱 Sample accounts created:"
echo "   Admin: +1987654321 / admin123456"
echo "   Driver: +1555123456 / driver123456"
echo ""
echo "🔒 Security reminder: Change default passwords in production!" 
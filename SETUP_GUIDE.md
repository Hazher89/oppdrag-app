# 🚀 DriveDispatch Complete Setup Guide

This guide will help you set up the complete DriveDispatch system with both the iOS app and backend server.

## 📋 Prerequisites

### For Backend Server:
- **Node.js** (v16 or higher) - [Download here](https://nodejs.org/)
- **MongoDB** (v4.4 or higher) - [Download here](https://www.mongodb.com/try/download/community)
- **Git** - [Download here](https://git-scm.com/)

### For iOS App:
- **Xcode** (v14 or higher) - [Download from App Store](https://apps.apple.com/us/app/xcode/id497799835)
- **macOS** (for iOS development)
- **Apple Developer Account** (optional, for App Store distribution)

## 🛠️ Step 1: Backend Server Setup

### 1.1 Install MongoDB

**macOS (using Homebrew):**
```bash
brew tap mongodb/brew
brew install mongodb-community
brew services start mongodb/brew/mongodb-community
```

**Windows:**
1. Download MongoDB Community Server from the official website
2. Run the installer and follow the setup wizard
3. Start MongoDB service

**Linux (Ubuntu):**
```bash
sudo apt update
sudo apt install mongodb
sudo systemctl start mongodb
sudo systemctl enable mongodb
```

### 1.2 Set Up Backend Server

1. **Navigate to backend directory:**
   ```bash
   cd backend
   ```

2. **Install dependencies:**
   ```bash
   npm install
   ```

3. **Create environment file:**
   ```bash
   cp env.example .env
   ```

4. **Edit `.env` file:**
   ```env
   # Server Configuration
   PORT=3000
   NODE_ENV=development
   
   # Database
   MONGODB_URI=mongodb://localhost:27017/drivedispatch
   
   # JWT Secret (generate a strong secret)
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   
   # Optional: Super Admin credentials
   SUPER_ADMIN_PHONE=+1234567890
   SUPER_ADMIN_NAME=Super Admin
   SUPER_ADMIN_PASSWORD=admin123456
   SUPER_ADMIN_EMAIL=admin@drivedispatch.com
   ```

5. **Set up database:**
   ```bash
   node setup.js
   ```

6. **Start the server:**
   ```bash
   npm start
   ```

   The server will start on `http://localhost:3000`

### 1.3 Verify Backend Setup

1. **Check server health:**
   ```bash
   curl http://localhost:3000/health
   ```

2. **Access admin interface:**
   - Open browser: `http://localhost:3000/admin`
   - Login with sample admin credentials:
     - Phone: `+1987654321`
     - Password: `admin123456`

## 📱 Step 2: iOS App Setup

### 2.1 Open Project in Xcode

1. **Open Xcode**
2. **Open the project:**
   - File → Open
   - Navigate to your project folder
   - Select `Oppdrag.xcodeproj`

### 2.2 Configure API Endpoints

1. **Open `APIService.swift`**
2. **Update the base URL:**
   ```swift
   // Change from demo data to your server
   static let baseURL = "http://localhost:3000/api/v1"
   ```

   **For production:**
   ```swift
   static let baseURL = "https://your-domain.com/api/v1"
   ```

### 2.3 Test the App

1. **Select a simulator or device**
2. **Build and run the app** (⌘+R)
3. **Test with sample credentials:**
   - Driver: `+1555123456` / `driver123456`
   - Admin: `+1987654321` / `admin123456`

## 🌐 Step 3: Admin Web Interface

### 3.1 Access Admin Panel

1. **Open browser:** `http://localhost:3000/admin`
2. **Login with admin credentials:**
   - Phone: `+1987654321`
   - Password: `admin123456`

### 3.2 Admin Features

- **Dashboard:** View statistics and recent assignments
- **Assignments:** Create, edit, and manage driver assignments
- **Drivers:** Add and manage driver accounts
- **Reports:** View performance analytics

### 3.3 Create Your First Assignment

1. **Go to Assignments tab**
2. **Click "New Assignment"**
3. **Fill in the details:**
   - Title: "Sample Delivery"
   - Description: "Deliver package to customer"
   - Driver: Select a driver
   - Priority: Medium
   - Upload PDF file (optional)
4. **Click "Create Assignment"**

## 🔧 Step 4: Production Deployment

### 4.1 Backend Deployment

**Option A: VPS/Cloud Server**

1. **Set up a VPS** (DigitalOcean, AWS, etc.)
2. **Install Node.js and MongoDB**
3. **Upload backend files**
4. **Configure environment variables**
5. **Set up PM2 for process management:**
   ```bash
   npm install -g pm2
   pm2 start server.js --name drivedispatch
   pm2 startup
   pm2 save
   ```

**Option B: Heroku**

1. **Create Heroku account**
2. **Install Heroku CLI**
3. **Deploy:**
   ```bash
   heroku create your-app-name
   heroku config:set MONGODB_URI=your-mongodb-uri
   heroku config:set JWT_SECRET=your-jwt-secret
   git push heroku main
   ```

### 4.2 iOS App Production

1. **Update API base URL** to your production server
2. **Configure push notifications** (optional)
3. **Test thoroughly**
4. **Archive and distribute**

## 📊 Step 5: User Management

### 5.1 Create Company Admin

1. **Login to admin panel**
2. **Go to Drivers tab**
3. **Click "Add Driver"**
4. **Create admin account:**
   - Name: "Company Admin"
   - Phone: Your phone number
   - Role: Admin
   - Set permissions

### 5.2 Add Drivers

1. **Use admin panel** or **API calls**
2. **Required fields:**
   - Name
   - Phone number
   - Password
   - License number (optional)
   - Vehicle ID (optional)

### 5.3 Send Assignments

1. **Create assignment** via admin panel
2. **Upload PDF files** for detailed instructions
3. **Set pickup/delivery times**
4. **Assign to specific driver**
5. **Driver receives notification** on iOS app

## 🔒 Step 6: Security & Best Practices

### 6.1 Environment Security

- **Change default passwords**
- **Use strong JWT secrets**
- **Enable HTTPS in production**
- **Regular security updates**

### 6.2 Database Security

- **Enable MongoDB authentication**
- **Regular backups**
- **Monitor access logs**

### 6.3 API Security

- **Rate limiting enabled**
- **Input validation**
- **CORS configuration**
- **File upload restrictions**

## 📱 Step 7: Mobile App Features

### 7.1 Driver Features

- **View assignments** with PDF details
- **Update status** (pending → in progress → completed)
- **Real-time chat** with admins
- **Location tracking**
- **Push notifications**

### 7.2 Admin Features

- **Create assignments** with PDF uploads
- **Monitor driver progress**
- **View reports and analytics**
- **Manage users and permissions**

## 🆘 Troubleshooting

### Common Issues

1. **MongoDB Connection Error**
   ```bash
   # Check if MongoDB is running
   brew services list | grep mongodb
   # Start if needed
   brew services start mongodb/brew/mongodb-community
   ```

2. **Port Already in Use**
   ```bash
   # Find process using port 3000
   lsof -i :3000
   # Kill process
   kill -9 <PID>
   ```

3. **iOS App Can't Connect**
   - Check if server is running
   - Verify API base URL
   - Check network connectivity
   - Test with Postman

4. **File Upload Issues**
   - Check upload directory permissions
   - Verify file size limits
   - Ensure proper file types

### Getting Help

1. **Check server logs** for error details
2. **Test API endpoints** with Postman
3. **Verify database connectivity**
4. **Check iOS app console** for errors

## 📈 Next Steps

### Advanced Features

1. **Push Notifications**
   - Configure Firebase
   - Set up notification service

2. **Real-time Tracking**
   - Implement location services
   - Add map integration

3. **Advanced Analytics**
   - Custom reports
   - Performance metrics
   - Route optimization

4. **Multi-company Support**
   - Company isolation
   - Super admin features

### Maintenance

1. **Regular backups**
2. **Security updates**
3. **Performance monitoring**
4. **User training**

---

## 🎉 Congratulations!

You now have a complete driver assignment management system with:

✅ **Backend API Server** with authentication and file management  
✅ **iOS Mobile App** for drivers  
✅ **Admin Web Interface** for management  
✅ **Real-time Chat** system  
✅ **PDF Assignment** support  
✅ **User Management** with roles and permissions  
✅ **Reports and Analytics**  

**Ready to manage your drivers efficiently! 🚛📱**

---

*For support or questions, check the troubleshooting section or review the code documentation.* 
# 🚛 DriveDispatch - Complete Driver Assignment Management System

A professional driver assignment management system that replaces Connecteam with a modern, feature-rich solution for managing drivers, assignments, and real-time communication.

## ✨ Features

### 📱 iOS Mobile App (for Drivers)
- **Phone-based authentication** with secure login
- **Assignment management** with PDF file support
- **Real-time chat** with admins and other drivers
- **Status updates** (pending → in progress → completed)
- **Location tracking** and arrival time management
- **Push notifications** for new assignments
- **Offline support** with local data persistence

### 🌐 Admin Web Interface (for Windows PCs)
- **Modern dashboard** with real-time statistics
- **Assignment creation** with PDF upload support
- **Driver management** with role-based permissions
- **Real-time monitoring** of driver progress
- **Reports and analytics** with performance metrics
- **Bulk operations** for efficient management

### 🔧 Backend API Server
- **RESTful API** with comprehensive endpoints
- **WebSocket support** for real-time features
- **File upload system** for PDF assignments
- **JWT authentication** with role-based access
- **MongoDB database** with optimized schemas
- **Security features** (rate limiting, validation, CORS)

## 🚀 Quick Start

### 1. Backend Setup (5 minutes)

```bash
# Navigate to backend directory
cd backend

# Run quick start script (macOS/Linux)
./quick-start.sh

# Or manual setup
npm install
cp env.example .env
node setup.js
npm start
```

### 2. iOS App Setup

1. **Open `Oppdrag.xcodeproj`** in Xcode
2. **Update API URL** in `APIService.swift`:
   ```swift
   static let baseURL = "http://localhost:3000/api/v1"
   ```
3. **Build and run** the app (⌘+R)

### 3. Admin Access

- **URL:** `http://localhost:3000/admin`
- **Login:** `+1987654321` / `admin123456`

## 📋 System Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   iOS App       │    │  Admin Web      │    │  Backend API    │
│   (Drivers)     │    │  Interface      │    │  Server         │
│                 │    │  (Admins)       │    │                 │
├─────────────────┤    ├─────────────────┤    ├─────────────────┤
│ • Authentication│    │ • Dashboard     │    │ • REST API      │
│ • Assignments   │    │ • User Mgmt     │    │ • WebSockets    │
│ • Chat System   │    │ • Reports       │    │ • File Upload   │
│ • PDF Viewer    │    │ • Analytics     │    │ • Auth System   │
│ • Notifications │    │ • Bulk Ops      │    │ • Database      │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                                │                       │
                                └───────────────────────┘
                                        MongoDB
```

## 🔐 User Roles & Permissions

### Super Admin
- Full system access
- Manage all companies and users
- System-wide analytics

### Company Admin
- Manage company drivers
- Create and assign tasks
- View company reports
- PDF file management

### Driver
- View assigned tasks
- Update task status
- Real-time chat
- Location sharing

## 📁 Project Structure

```
DriveDispatch/
├── Oppdrag/                    # iOS App
│   ├── ContentView.swift       # Main app interface
│   ├── AuthenticationManager.swift
│   ├── AssignmentsManager.swift
│   ├── ChatManager.swift
│   └── APIService.swift
├── backend/                    # Node.js Server
│   ├── server.js              # Main server file
│   ├── models/                # Database models
│   ├── routes/                # API endpoints
│   ├── middleware/            # Auth & validation
│   ├── public/admin/          # Admin web interface
│   └── uploads/               # File storage
├── SETUP_GUIDE.md             # Detailed setup instructions
└── README.md                  # This file
```

## 🛠️ Technology Stack

### Frontend
- **iOS:** SwiftUI, PDFKit, Core Data
- **Web Admin:** HTML5, CSS3, JavaScript, Bootstrap 5

### Backend
- **Runtime:** Node.js with Express.js
- **Database:** MongoDB with Mongoose
- **Real-time:** Socket.io for WebSockets
- **File Upload:** Multer with local/S3 storage
- **Authentication:** JWT with bcrypt

### DevOps
- **Process Manager:** PM2 (production)
- **Security:** Helmet, CORS, Rate limiting
- **Validation:** Express-validator

## 📊 Key Features Explained

### PDF Assignment System
- **Upload PDFs** via admin interface
- **Secure storage** with access control
- **Mobile viewing** with PDFKit
- **Version control** for updates

### Real-time Chat
- **WebSocket connection** for instant messaging
- **File sharing** in conversations
- **Read receipts** and typing indicators
- **Conversation management**

### Location Tracking
- **GPS integration** for driver location
- **Real-time updates** to admins
- **Arrival time estimation**
- **Route optimization** (future)

### Admin Dashboard
- **Real-time statistics** and metrics
- **Driver performance** analytics
- **Assignment status** monitoring
- **Custom reports** generation

## 🔧 Configuration

### Environment Variables
```env
# Server
PORT=3000
NODE_ENV=development

# Database
MONGODB_URI=mongodb://localhost:27017/drivedispatch

# Security
JWT_SECRET=your-secure-jwt-secret

# File Storage
STORAGE_TYPE=local  # or 's3' for AWS
```

### iOS App Configuration
```swift
// APIService.swift
static let baseURL = "http://localhost:3000/api/v1"
static let useDemoData = false  // Set to true for testing
```

## 🚀 Deployment Options

### Development
```bash
# Backend
cd backend && npm start

# iOS
Open in Xcode and run on simulator/device
```

### Production
```bash
# Backend (with PM2)
npm install -g pm2
pm2 start server.js --name drivedispatch
pm2 startup && pm2 save

# iOS
Archive and distribute via App Store or TestFlight
```

## 📈 Performance & Scalability

### Optimizations
- **Database indexing** on frequently queried fields
- **File compression** for PDF uploads
- **Connection pooling** for database
- **Caching strategies** for static data

### Monitoring
- **Health check endpoint** (`/health`)
- **Error logging** and tracking
- **Performance metrics** collection
- **Real-time monitoring** dashboard

## 🔒 Security Features

### Authentication & Authorization
- **JWT tokens** with expiration
- **Role-based access control**
- **Password hashing** with bcrypt
- **Session management**

### API Security
- **Rate limiting** to prevent abuse
- **Input validation** and sanitization
- **CORS configuration** for web access
- **File upload restrictions**

### Data Protection
- **Encrypted storage** for sensitive data
- **Secure file access** with authentication
- **Audit logging** for user actions
- **Backup and recovery** procedures

## 📱 Mobile App Features

### Core Functionality
- **Offline-first design** with local storage
- **Push notifications** for assignments
- **Background location** updates
- **PDF document** viewing and management

### User Experience
- **Intuitive interface** with SwiftUI
- **Dark mode support** for drivers
- **Accessibility features** for all users
- **Multi-language support** (future)

## 🌐 Web Admin Features

### Management Tools
- **Drag-and-drop** assignment creation
- **Bulk operations** for efficiency
- **Advanced filtering** and search
- **Export capabilities** for reports

### Analytics Dashboard
- **Real-time metrics** and KPIs
- **Performance tracking** by driver
- **Assignment completion** rates
- **Custom report** generation

## 🆘 Support & Troubleshooting

### Common Issues
1. **MongoDB connection** - Check if service is running
2. **Port conflicts** - Verify port 3000 is available
3. **File uploads** - Check directory permissions
4. **iOS connectivity** - Verify API URL and network

### Getting Help
- **Check logs** for detailed error messages
- **Test API endpoints** with Postman
- **Verify database** connectivity
- **Review setup guide** for configuration

## 🎯 Use Cases

### Perfect For:
- **Delivery companies** managing drivers
- **Logistics firms** with route optimization
- **Service businesses** with field workers
- **Transportation companies** with fleet management

### Key Benefits:
- **Real-time communication** between office and field
- **Efficient assignment** management
- **Document sharing** with PDF support
- **Performance tracking** and analytics
- **Cost reduction** through automation

## 🔄 Future Enhancements

### Planned Features
- **Route optimization** with AI
- **Advanced analytics** with machine learning
- **Multi-language support** for global teams
- **Integration APIs** for third-party systems
- **Mobile app** for Android devices

### Scalability Improvements
- **Microservices architecture** for large deployments
- **Cloud-native** deployment options
- **Advanced caching** with Redis
- **Load balancing** for high traffic

---

## 🎉 Ready to Get Started?

1. **Follow the setup guide** in `SETUP_GUIDE.md`
2. **Run the quick start script** for automated setup
3. **Test with sample accounts** provided
4. **Customize for your business** needs

**Transform your driver management today! 🚛✨**

---

*DriveDispatch - Professional driver assignment management system* 
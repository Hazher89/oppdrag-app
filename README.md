# DriveDispatch Backend Server

A complete Node.js backend server for the DriveDispatch driver assignment management system.

## 🚀 Features

- **User Authentication**: Phone number-based login with JWT tokens
- **Role-Based Access Control**: Driver, Admin, and Super Admin roles
- **Assignment Management**: Create, assign, and track driver assignments
- **PDF File Upload**: Secure PDF file handling for assignments
- **Real-time Chat**: WebSocket-based chat system
- **Admin Dashboard**: Comprehensive admin interface with reports
- **Push Notifications**: Device token management for notifications
- **File Management**: Secure file upload and storage
- **API Security**: Rate limiting, validation, and authentication

## 📋 Prerequisites

- Node.js (v16 or higher)
- MongoDB (v4.4 or higher)
- npm or yarn

## 🛠️ Installation

1. **Clone the repository**
   ```bash
   cd backend
   ```

2. **Install dependencies**
   ```bash
   npm install
   ```

3. **Set up environment variables**
   ```bash
   cp env.example .env
   ```
   
   Edit `.env` file with your configuration:
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

4. **Set up the database**
   ```bash
   node setup.js
   ```

5. **Start the server**
   ```bash
   npm start
   ```

## 📱 API Endpoints

### Authentication
- `POST /api/v1/auth/register` - Register new user
- `POST /api/v1/auth/login` - User login
- `GET /api/v1/auth/me` - Get current user
- `PUT /api/v1/auth/profile` - Update profile
- `POST /api/v1/auth/logout` - Logout

### Assignments
- `POST /api/v1/assignments` - Create assignment (Admin)
- `GET /api/v1/assignments` - Get assignments
- `GET /api/v1/assignments/:id` - Get assignment details
- `PUT /api/v1/assignments/:id/status` - Update assignment status
- `PUT /api/v1/assignments/:id` - Update assignment (Admin)
- `DELETE /api/v1/assignments/:id` - Delete assignment (Admin)
- `POST /api/v1/assignments/:id/location` - Update location (Driver)

### Chat
- `GET /api/v1/chat/conversations` - Get conversations
- `POST /api/v1/chat/conversations` - Create conversation
- `GET /api/v1/chat/conversations/:id/messages` - Get messages
- `POST /api/v1/chat/conversations/:id/messages` - Send message
- `PUT /api/v1/chat/conversations/:id/read` - Mark as read
- `GET /api/v1/chat/users` - Get available users

### Admin
- `GET /api/v1/admin/users` - Get all users
- `POST /api/v1/admin/users` - Create user
- `PUT /api/v1/admin/users/:id` - Update user
- `DELETE /api/v1/admin/users/:id` - Delete user
- `GET /api/v1/admin/dashboard` - Get dashboard stats
- `GET /api/v1/admin/reports` - Get reports
- `POST /api/v1/admin/bulk-assign` - Bulk assign assignments

### Users
- `GET /api/v1/users/drivers` - Get drivers
- `GET /api/v1/users/:id` - Get user details
- `PUT /api/v1/users/:id/device-token` - Update device token
- `PUT /api/v1/users/:id/password` - Change password
- `GET /api/v1/users/search` - Search users

## 🔐 User Roles & Permissions

### Super Admin
- Full system access
- Can manage all companies and users
- All permissions enabled

### Admin
- Company-specific access
- Can manage users within their company
- Can create/edit/delete assignments
- Can view reports and analytics

### Driver
- View and update their own assignments
- Update assignment status and location
- Participate in chat conversations
- Update their profile

## 📁 File Structure

```
backend/
├── models/           # Database models
│   ├── User.js
│   ├── Assignment.js
│   └── Chat.js
├── routes/           # API routes
│   ├── auth.js
│   ├── assignments.js
│   ├── chat.js
│   ├── admin.js
│   └── users.js
├── middleware/       # Middleware functions
│   └── auth.js
├── uploads/          # File uploads
│   ├── pdfs/         # Assignment PDFs
│   └── chat/         # Chat files
├── server.js         # Main server file
├── setup.js          # Database setup script
├── package.json
└── README.md
```

## 🗄️ Database Schema

### User Model
- Phone number (unique identifier)
- Name, email, password
- Role (driver/admin/super_admin)
- Company ID
- Permissions array
- Device token for notifications
- Driver-specific fields (license, vehicle)

### Assignment Model
- Title, description
- Driver and assigner references
- Status tracking
- Location data (pickup/delivery)
- Time scheduling
- PDF file information
- Notes and completion data

### Chat Model
- Participants array
- Message history
- File attachments
- Read status tracking
- Conversation metadata

## 🔧 Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `PORT` | Server port | 3000 |
| `NODE_ENV` | Environment | development |
| `MONGODB_URI` | MongoDB connection | localhost:27017/drivedispatch |
| `JWT_SECRET` | JWT signing secret | Required |
| `STORAGE_TYPE` | File storage type | local |
| `AWS_*` | AWS S3 configuration | Optional |

### File Upload Configuration

The server supports both local file storage and AWS S3:

**Local Storage (Default)**
- Files stored in `uploads/` directory
- Accessible via HTTP URLs
- Suitable for development and small deployments

**AWS S3 Storage**
- Set `STORAGE_TYPE=s3` in environment
- Configure AWS credentials
- Better for production deployments

## 🚀 Deployment

### Development
```bash
npm run dev
```

### Production
```bash
npm start
```

### Docker (Optional)
```bash
docker build -t drivedispatch-backend .
docker run -p 3000:3000 drivedispatch-backend
```

## 📊 Monitoring & Logging

The server includes:
- Request logging
- Error tracking
- Performance monitoring
- Health check endpoint (`/health`)

## 🔒 Security Features

- JWT-based authentication
- Password hashing with bcrypt
- Rate limiting
- Input validation
- CORS protection
- Helmet security headers
- File upload restrictions

## 📱 iOS App Integration

To connect your iOS app:

1. Update the API base URL in your iOS app
2. Ensure the server is accessible from mobile devices
3. Configure push notifications (optional)
4. Test authentication flow

## 🆘 Troubleshooting

### Common Issues

1. **MongoDB Connection Error**
   - Ensure MongoDB is running
   - Check connection string in `.env`

2. **JWT Secret Error**
   - Set a strong JWT_SECRET in `.env`
   - Restart server after changes

3. **File Upload Issues**
   - Check upload directory permissions
   - Verify file size limits
   - Ensure proper file types

4. **CORS Errors**
   - Configure CORS settings for your domain
   - Check client-side API calls

### Support

For issues and questions:
1. Check the logs for error details
2. Verify environment configuration
3. Test API endpoints with Postman
4. Review database connectivity

## 📈 Performance Optimization

- Database indexing on frequently queried fields
- File upload size limits
- Rate limiting to prevent abuse
- Efficient query patterns
- Connection pooling

## 🔄 Updates & Maintenance

- Regular security updates
- Database backups
- Log rotation
- Performance monitoring
- Dependency updates

---

**DriveDispatch Backend** - Professional driver assignment management system 
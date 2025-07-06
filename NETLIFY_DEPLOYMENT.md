# 🚀 Netlify Deployment Guide

## Quick Deploy to Netlify

### Option 1: Deploy via Netlify UI (Recommended)

1. **Go to [netlify.com](https://netlify.com)** and sign up/login
2. **Click "New site from Git"**
3. **Connect your GitHub account** and select your repository
4. **Configure build settings:**
   - **Build command:** `npm install`
   - **Publish directory:** `public`
   - **Functions directory:** `functions`
5. **Set Environment Variables:**
   ```
   MONGODB_URI=mongodb+srv://your-username:your-password@your-cluster.mongodb.net/drivedispatch
   JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
   NODE_ENV=production
   ```
6. **Click "Deploy site"**

### Option 2: Deploy via Netlify CLI

```bash
# Install Netlify CLI
npm install -g netlify-cli

# Login to Netlify
netlify login

# Initialize and deploy
netlify init
netlify deploy --prod
```

## Environment Variables

Set these in Netlify Dashboard → Site Settings → Environment Variables:

### Required:
- `MONGODB_URI` - Your MongoDB connection string
- `JWT_SECRET` - Secret key for JWT tokens

### Optional:
- `EMAIL_HOST` - SMTP server for email notifications
- `EMAIL_USER` - Email username
- `EMAIL_PASS` - Email password
- `TWILIO_ACCOUNT_SID` - Twilio account SID for SMS
- `TWILIO_AUTH_TOKEN` - Twilio auth token
- `TWILIO_PHONE_NUMBER` - Twilio phone number
- `AWS_ACCESS_KEY_ID` - AWS access key for file uploads
- `AWS_SECRET_ACCESS_KEY` - AWS secret key
- `AWS_REGION` - AWS region
- `AWS_S3_BUCKET` - S3 bucket name

## Database Setup

### MongoDB Atlas (Recommended)
1. Go to [mongodb.com](https://mongodb.com)
2. Create free cluster
3. Get connection string
4. Add to Netlify environment variables

### Local MongoDB (Development)
Use local MongoDB for testing, but Atlas for production.

## Access Your App

After deployment, you'll get a URL like: `https://your-app-name.netlify.app`

- **Main Site:** `https://your-app-name.netlify.app`
- **Admin Panel:** `https://your-app-name.netlify.app/admin/`
- **API Health:** `https://your-app-name.netlify.app/health`
- **API Endpoints:** `https://your-app-name.netlify.app/api/v1/`

## Default Admin Credentials

- **Phone:** `+1234567890`
- **Password:** `admin123456`

## Troubleshooting

### Common Issues:

1. **Build Fails:**
   - Check Node.js version (should be 18+)
   - Verify all dependencies are in package.json

2. **Database Connection Error:**
   - Verify MONGODB_URI is correct
   - Check MongoDB Atlas network access

3. **Function Timeout:**
   - Netlify functions have 10-second timeout
   - Optimize database queries

4. **CORS Issues:**
   - Update iOS app with new Netlify URL
   - Check CORS configuration

### Support:
- Netlify Docs: [docs.netlify.com](https://docs.netlify.com)
- MongoDB Atlas: [docs.atlas.mongodb.com](https://docs.atlas.mongodb.com)

## Cost

**Netlify Free Tier Includes:**
- ✅ 100GB bandwidth/month
- ✅ 300 build minutes/month
- ✅ 125K function invocations/month
- ✅ Custom domains
- ✅ SSL certificates
- ✅ Form handling

**Perfect for your app!** 🎉 
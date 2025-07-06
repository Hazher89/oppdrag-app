const nodemailer = require('nodemailer');

class EmailService {
  constructor() {
    // Initialize email transporter
    this.transporter = null;
    this.initializeTransporter();
  }

  // Initialize email transporter
  initializeTransporter() {
    // For development/demo, use Gmail or a test service
    // In production, you might want to use a service like SendGrid, Mailgun, etc.
    
    if (process.env.EMAIL_HOST && process.env.EMAIL_USER && process.env.EMAIL_PASS) {
      // Production email configuration
      this.transporter = nodemailer.createTransporter({
        host: process.env.EMAIL_HOST,
        port: process.env.EMAIL_PORT || 587,
        secure: process.env.EMAIL_SECURE === 'true',
        auth: {
          user: process.env.EMAIL_USER,
          pass: process.env.EMAIL_PASS
        }
      });
    } else {
      // Demo mode - create a test account
      this.transporter = nodemailer.createTransporter({
        host: 'smtp.ethereal.email',
        port: 587,
        secure: false,
        auth: {
          user: 'test@example.com',
          pass: 'testpass'
        }
      });
    }
  }

  // Generate a 6-digit verification code
  generateVerificationCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  // Send verification code via email
  async sendVerificationCode(email, code, type = 'verification') {
    try {
      const subject = this.getEmailSubject(type);
      const htmlContent = this.getEmailHTML(code, type);
      const textContent = this.getEmailText(code, type);

      const mailOptions = {
        from: process.env.EMAIL_FROM || 'noreply@drivedispatch.com',
        to: email,
        subject: subject,
        text: textContent,
        html: htmlContent
      };

      if (this.transporter) {
        // Send via configured email service
        const info = await this.transporter.sendMail(mailOptions);
        console.log(`📧 Email sent to ${email}: ${info.messageId}`);
        return true;
      } else {
        // Demo mode - just log the message
        console.log(`📧 DEMO EMAIL to ${email}:`);
        console.log(`Subject: ${subject}`);
        console.log(`Content: ${textContent}`);
        console.log(`🔑 Verification Code: ${code}`);
        return true;
      }
    } catch (error) {
      console.error('Email sending error:', error);
      return false;
    }
  }

  // Get appropriate email subject based on type
  getEmailSubject(type) {
    switch (type) {
      case 'registration':
        return 'DriveDispatch - Registration Verification Code';
      case 'login':
        return 'DriveDispatch - Login Verification Code';
      case 'password_reset':
        return 'DriveDispatch - Password Reset Code';
      default:
        return 'DriveDispatch - Verification Code';
    }
  }

  // Get HTML email content
  getEmailHTML(code, type) {
    const action = type === 'registration' ? 'registration' : 
                   type === 'login' ? 'login' : 
                   type === 'password_reset' ? 'password reset' : 'verification';
    
    return `
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="utf-8">
        <title>DriveDispatch Verification</title>
        <style>
          body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #007bff; color: white; padding: 20px; text-align: center; }
          .content { padding: 20px; background: #f8f9fa; }
          .code { font-size: 24px; font-weight: bold; text-align: center; padding: 20px; background: white; margin: 20px 0; border-radius: 5px; }
          .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h1>🚗 DriveDispatch</h1>
          </div>
          <div class="content">
            <h2>Your Verification Code</h2>
            <p>You requested a verification code for ${action}. Use the code below to complete your ${action}:</p>
            <div class="code">${code}</div>
            <p><strong>This code is valid for 10 minutes.</strong></p>
            <p>If you didn't request this code, please ignore this email.</p>
          </div>
          <div class="footer">
            <p>© 2025 DriveDispatch. All rights reserved.</p>
          </div>
        </div>
      </body>
      </html>
    `;
  }

  // Get plain text email content
  getEmailText(code, type) {
    const action = type === 'registration' ? 'registration' : 
                   type === 'login' ? 'login' : 
                   type === 'password_reset' ? 'password reset' : 'verification';
    
    return `
DriveDispatch Verification Code

You requested a verification code for ${action}. Use the code below to complete your ${action}:

${code}

This code is valid for 10 minutes.

If you didn't request this code, please ignore this email.

© 2025 DriveDispatch. All rights reserved.
    `;
  }

  // Validate email format
  validateEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
}

module.exports = new EmailService(); 
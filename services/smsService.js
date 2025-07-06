const twilio = require('twilio');

class SMSService {
  constructor() {
    // Initialize Twilio client if credentials are available
    this.twilioClient = null;
    if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
      this.twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
    }
  }

  // Generate a 6-digit verification code
  generateVerificationCode() {
    return Math.floor(100000 + Math.random() * 900000).toString();
  }

  // Send verification code via SMS
  async sendVerificationCode(phoneNumber, code, type = 'verification') {
    try {
      const message = this.getSMSMessage(code, type);
      
      if (this.twilioClient) {
        // Send via Twilio (production)
        await this.twilioClient.messages.create({
          body: message,
          from: process.env.TWILIO_PHONE_NUMBER,
          to: phoneNumber
        });
        console.log(`SMS sent to ${phoneNumber} via Twilio`);
      } else {
        // Demo mode - just log the message
        console.log(`📱 DEMO SMS to ${phoneNumber}: ${message}`);
        console.log(`🔑 Verification Code: ${code}`);
      }
      
      return true;
    } catch (error) {
      console.error('SMS sending error:', error);
      return false;
    }
  }

  // Get appropriate SMS message based on type
  getSMSMessage(code, type) {
    switch (type) {
      case 'registration':
        return `Your DriveDispatch registration code is: ${code}. Valid for 10 minutes.`;
      case 'login':
        return `Your DriveDispatch login code is: ${code}. Valid for 10 minutes.`;
      case 'password_reset':
        return `Your DriveDispatch password reset code is: ${code}. Valid for 10 minutes.`;
      default:
        return `Your DriveDispatch verification code is: ${code}. Valid for 10 minutes.`;
    }
  }

  // Validate phone number format
  validatePhoneNumber(phoneNumber) {
    // Basic validation - you can make this more sophisticated
    const phoneRegex = /^\+?[1-9]\d{1,14}$/;
    return phoneRegex.test(phoneNumber.replace(/\s/g, ''));
  }

  // Format phone number for display
  formatPhoneNumber(phoneNumber) {
    // Remove all non-digit characters except +
    const cleaned = phoneNumber.replace(/[^\d+]/g, '');
    
    // If it doesn't start with +, assume it's a local number
    if (!cleaned.startsWith('+')) {
      return `+${cleaned}`;
    }
    
    return cleaned;
  }
}

module.exports = new SMSService(); 
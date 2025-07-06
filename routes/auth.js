const express = require('express');
const jwt = require('jsonwebtoken');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middleware/auth');
const emailService = require('../services/emailService');

const router = express.Router();

// Generate JWT Token
const generateToken = (userId) => {
  return jwt.sign({ userId }, process.env.JWT_SECRET, { expiresIn: '7d' });
};

// @route   POST /api/v1/auth/register
// @desc    Register a new user
// @access  Public
router.post('/register', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('name').isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('companyId').notEmpty().withMessage('Company ID is required'),
  body('role').isIn(['driver', 'admin']).withMessage('Role must be driver or admin')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, name, password, companyId, role, phoneNumber, licenseNumber } = req.body;

    // Check if user already exists
    let user = await User.findOne({ email });
    if (user) {
      return res.status(400).json({ error: 'User with this email already exists' });
    }

    // Create new user
    user = new User({
      email,
      name,
      password,
      companyId,
      role,
      phoneNumber,
      licenseNumber
    });

    await user.save();

    // Generate token
    const token = generateToken(user._id);

    res.status(201).json({
      message: 'User registered successfully',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        companyId: user.companyId
      }
    });

  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/auth/login
// @desc    Login user
// @access  Public
router.post('/login', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('password').notEmpty().withMessage('Password is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, password, deviceToken } = req.body;

    // Find user
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(400).json({ error: 'Account is deactivated' });
    }

    // Check password
    const isMatch = await user.comparePassword(password);
    if (!isMatch) {
      return res.status(400).json({ error: 'Invalid credentials' });
    }

    // Update device token and last login
    if (deviceToken) {
      user.deviceToken = deviceToken;
    }
    user.lastLogin = new Date();
    await user.save();

    // Generate token
    const token = generateToken(user._id);

    res.json({
      message: 'Login successful',
      token,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        role: user.role,
        companyId: user.companyId,
        permissions: user.permissions
      }
    });

  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/auth/me
// @desc    Get current user
// @access  Private
router.get('/me', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    res.json({
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        companyId: user.companyId,
        permissions: user.permissions,
        licenseNumber: user.licenseNumber,
        vehicleId: user.vehicleId,
        profileImage: user.profileImage
      }
    });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   PUT /api/v1/auth/profile
// @desc    Update user profile
// @access  Private
router.put('/profile', auth, [
  body('name').optional().isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
  body('email').optional().isEmail().withMessage('Valid email is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { name, email, phoneNumber, licenseNumber, vehicleId } = req.body;

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Update fields
    if (name) user.name = name;
    if (email) user.email = email;
    if (phoneNumber) user.phoneNumber = phoneNumber;
    if (licenseNumber) user.licenseNumber = licenseNumber;
    if (vehicleId) user.vehicleId = vehicleId;

    await user.save();

    res.json({
      message: 'Profile updated successfully',
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        phoneNumber: user.phoneNumber,
        role: user.role,
        companyId: user.companyId,
        licenseNumber: user.licenseNumber,
        vehicleId: user.vehicleId
      }
    });

  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/auth/logout
// @desc    Logout user (clear device token)
// @access  Private
router.post('/logout', auth, async (req, res) => {
  try {
    const user = await User.findById(req.user.id);
    if (user) {
      user.deviceToken = null;
      await user.save();
    }

    res.json({ message: 'Logged out successfully' });

  } catch (error) {
    console.error('Logout error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/auth/forgot-password
// @desc    Request password reset
// @access  Public
router.post('/forgot-password', [
  body('email').isEmail().withMessage('Valid email is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'No account found with this email' });
    }

    if (!user.isActive) {
      return res.status(400).json({ error: 'Account is deactivated' });
    }

    // Generate a simple 6-digit reset code
    const resetCode = Math.floor(100000 + Math.random() * 900000).toString();
    
    // Store reset code and expiry (10 minutes from now)
    user.resetCode = resetCode;
    user.resetCodeExpiry = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes
    await user.save();

    // Send email with reset code
    const emailSent = await emailService.sendVerificationCode(email, resetCode, 'password_reset');
    
    if (!emailSent) {
      return res.status(500).json({ error: 'Failed to send reset code' });
    }

    res.json({
      message: 'Password reset code sent to your email',
      expiresIn: '10 minutes'
    });

  } catch (error) {
    console.error('Forgot password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/auth/reset-password
// @desc    Reset password with code
// @access  Public
router.post('/reset-password', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('resetCode').notEmpty().withMessage('Reset code is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('Password must be at least 6 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, resetCode, newPassword } = req.body;

    // Find user by email
    const user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'No account found with this email' });
    }

    if (!user.isActive) {
      return res.status(400).json({ error: 'Account is deactivated' });
    }

    // Check if reset code exists and is valid
    if (!user.resetCode || user.resetCode !== resetCode) {
      return res.status(400).json({ error: 'Invalid reset code' });
    }

    // Check if reset code has expired
    if (!user.resetCodeExpiry || user.resetCodeExpiry < new Date()) {
      return res.status(400).json({ error: 'Reset code has expired' });
    }

    // Update password
    user.password = newPassword;
    user.resetCode = null;
    user.resetCodeExpiry = null;
    await user.save();

    res.json({ message: 'Password reset successfully' });

  } catch (error) {
    console.error('Reset password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/auth/send-verification-code
// @desc    Send verification code for registration or login
// @access  Public
router.post('/send-verification-code', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('type').isIn(['registration', 'login']).withMessage('Type must be registration or login')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, type } = req.body;

    // Validate email format
    if (!emailService.validateEmail(email)) {
      return res.status(400).json({ error: 'Invalid email format' });
    }

    // Check if user exists for login verification
    if (type === 'login') {
      const user = await User.findOne({ email });
      if (!user) {
        return res.status(404).json({ error: 'No account found with this email' });
      }
      if (!user.isActive) {
        return res.status(400).json({ error: 'Account is deactivated' });
      }
    }

    // Check if user already exists for registration
    if (type === 'registration') {
      const existingUser = await User.findOne({ email });
      if (existingUser) {
        return res.status(400).json({ error: 'User with this email already exists' });
      }
    }

    // Generate verification code
    const verificationCode = emailService.generateVerificationCode();
    const expiryTime = new Date(Date.now() + 10 * 60 * 1000); // 10 minutes

    // Store verification code
    if (type === 'login') {
      // Update existing user with verification code
      const user = await User.findOne({ email });
      user.verificationCode = verificationCode;
      user.verificationCodeExpiry = expiryTime;
      await user.save();
    } else {
      // Create temporary user record for registration
      const tempUser = new User({
        email: email,
        verificationCode: verificationCode,
        verificationCodeExpiry: expiryTime,
        isActive: false // Will be activated after verification
      });
      await tempUser.save();
    }

    // Send email
    const emailSent = await emailService.sendVerificationCode(email, verificationCode, type);
    
    if (!emailSent) {
      return res.status(500).json({ error: 'Failed to send verification code' });
    }

    res.json({
      message: `Verification code sent to ${email}`,
      email: email,
      type: type,
      expiresIn: '10 minutes'
    });

  } catch (error) {
    console.error('Send verification code error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/auth/verify-code
// @desc    Verify code and complete registration or login
// @access  Public
router.post('/verify-code', [
  body('email').isEmail().withMessage('Valid email is required'),
  body('verificationCode').notEmpty().withMessage('Verification code is required'),
  body('type').isIn(['registration', 'login']).withMessage('Type must be registration or login')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { email, verificationCode, type, name, password, companyId, role, phoneNumber, licenseNumber } = req.body;

    // Find user
    let user = await User.findOne({ email });
    if (!user) {
      return res.status(404).json({ error: 'No account found with this email' });
    }

    // Check if verification code is valid
    if (!user.verificationCode || user.verificationCode !== verificationCode) {
      return res.status(400).json({ error: 'Invalid verification code' });
    }

    // Check if verification code has expired
    if (!user.verificationCodeExpiry || user.verificationCodeExpiry < new Date()) {
      return res.status(400).json({ error: 'Verification code has expired' });
    }

    if (type === 'registration') {
      // Complete registration
      if (!name || !password || !companyId || !role) {
        return res.status(400).json({ error: 'Missing required registration fields' });
      }

      // Update user with registration data
      user.name = name;
      user.password = password;
      user.companyId = companyId;
      user.role = role;
      user.phoneNumber = phoneNumber;
      user.licenseNumber = licenseNumber;
      user.isActive = true;
      user.isEmailVerified = true;
      user.verificationCode = null;
      user.verificationCodeExpiry = null;

      await user.save();

      // Generate token
      const token = generateToken(user._id);

      res.json({
        message: 'Registration completed successfully',
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          companyId: user.companyId,
          isEmailVerified: true
        }
      });

    } else if (type === 'login') {
      // Complete login
      user.isEmailVerified = true;
      user.verificationCode = null;
      user.verificationCodeExpiry = null;
      user.lastLogin = new Date();
      await user.save();

      // Generate token
      const token = generateToken(user._id);

      res.json({
        message: 'Login successful',
        token,
        user: {
          id: user._id,
          name: user.name,
          email: user.email,
          role: user.role,
          companyId: user.companyId,
          permissions: user.permissions,
          isEmailVerified: true
        }
      });
    }

  } catch (error) {
    console.error('Verify code error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 
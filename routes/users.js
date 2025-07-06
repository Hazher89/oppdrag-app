const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const { auth } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/v1/users/drivers
// @desc    Get all drivers for company
// @access  Private
router.get('/drivers', auth, async (req, res) => {
  try {
    const drivers = await User.find({
      companyId: req.user.companyId,
      role: 'driver',
      isActive: true
    })
    .select('name phoneNumber licenseNumber vehicleId lastLogin')
    .sort({ name: 1 });

    res.json({ drivers });

  } catch (error) {
    console.error('Get drivers error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/users/:id
// @desc    Get user by ID
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const user = await User.findById(req.params.id).select('-password');
    
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if user belongs to same company
    if (user.companyId !== req.user.companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json({ user });

  } catch (error) {
    console.error('Get user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   PUT /api/v1/users/:id/device-token
// @desc    Update device token for push notifications
// @access  Private
router.put('/:id/device-token', auth, [
  body('deviceToken').notEmpty().withMessage('Device token is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { deviceToken } = req.body;

    // Users can only update their own device token
    if (req.params.id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    user.deviceToken = deviceToken;
    await user.save();

    res.json({ message: 'Device token updated successfully' });

  } catch (error) {
    console.error('Update device token error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   PUT /api/v1/users/:id/password
// @desc    Change password
// @access  Private
router.put('/:id/password', auth, [
  body('currentPassword').notEmpty().withMessage('Current password is required'),
  body('newPassword').isLength({ min: 6 }).withMessage('New password must be at least 6 characters')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { currentPassword, newPassword } = req.body;

    // Users can only change their own password
    if (req.params.id !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Verify current password
    const isMatch = await user.comparePassword(currentPassword);
    if (!isMatch) {
      return res.status(400).json({ error: 'Current password is incorrect' });
    }

    // Update password
    user.password = newPassword;
    await user.save();

    res.json({ message: 'Password changed successfully' });

  } catch (error) {
    console.error('Change password error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/users/search
// @desc    Search users by name or phone number
// @access  Private
router.get('/search', auth, async (req, res) => {
  try {
    const { q, role } = req.query;

    if (!q || q.length < 2) {
      return res.status(400).json({ error: 'Search query must be at least 2 characters' });
    }

    let query = {
      companyId: req.user.companyId,
      isActive: true,
      $or: [
        { name: { $regex: q, $options: 'i' } },
        { phoneNumber: { $regex: q, $options: 'i' } }
      ]
    };

    if (role) {
      query.role = role;
    }

    const users = await User.find(query)
      .select('name phoneNumber role licenseNumber vehicleId')
      .limit(10);

    res.json({ users });

  } catch (error) {
    console.error('Search users error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 
const express = require('express');
const { body, validationResult } = require('express-validator');
const User = require('../models/User');
const Assignment = require('../models/Assignment');
const { auth, requireAdmin, requireSuperAdmin, requirePermission } = require('../middleware/auth');

const router = express.Router();

// @route   GET /api/v1/admin/users
// @desc    Get all users (Admin only)
// @access  Private (Admin only)
router.get('/users', auth, requirePermission('manage_users'), async (req, res) => {
  try {
    const { role, status, page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    let query = { companyId: req.user.companyId };

    // Super admins can see all users
    if (req.user.role === 'super_admin') {
      delete query.companyId;
    }

    // Apply filters
    if (role) query.role = role;
    if (status !== undefined) query.isActive = status === 'active';

    const users = await User.find(query)
      .select('-password')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await User.countDocuments(query);

    res.json({
      users,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(total / limit),
        hasNext: skip + users.length < total,
        hasPrev: page > 1
      }
    });

  } catch (error) {
    console.error('Get users error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/admin/users
// @desc    Create new user (Admin only)
// @access  Private (Admin only)
router.post('/users', auth, requirePermission('manage_users'), [
  body('phoneNumber').isMobilePhone().withMessage('Valid phone number is required'),
  body('name').isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('role').isIn(['driver', 'admin']).withMessage('Role must be driver or admin'),
  body('email').optional().isEmail().withMessage('Valid email is required'),
  body('licenseNumber').optional().isString().withMessage('License number must be a string'),
  body('vehicleId').optional().isString().withMessage('Vehicle ID must be a string'),
  body('permissions').optional().isArray().withMessage('Permissions must be an array')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      phoneNumber,
      name,
      password,
      role,
      email,
      licenseNumber,
      vehicleId,
      permissions
    } = req.body;

    // Check if user already exists
    const existingUser = await User.findOne({ phoneNumber });
    if (existingUser) {
      return res.status(400).json({ error: 'User with this phone number already exists' });
    }

    // Create new user
    const user = new User({
      phoneNumber,
      name,
      password,
      role,
      email,
      licenseNumber,
      vehicleId,
      companyId: req.user.companyId,
      permissions: permissions || []
    });

    await user.save();

    res.status(201).json({
      message: 'User created successfully',
      user: {
        id: user._id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        role: user.role,
        email: user.email,
        licenseNumber: user.licenseNumber,
        vehicleId: user.vehicleId,
        permissions: user.permissions,
        isActive: user.isActive
      }
    });

  } catch (error) {
    console.error('Create user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   PUT /api/v1/admin/users/:id
// @desc    Update user (Admin only)
// @access  Private (Admin only)
router.put('/users/:id', auth, requirePermission('manage_users'), [
  body('name').optional().isLength({ min: 2 }).withMessage('Name must be at least 2 characters'),
  body('email').optional().isEmail().withMessage('Valid email is required'),
  body('role').optional().isIn(['driver', 'admin']).withMessage('Role must be driver or admin'),
  body('licenseNumber').optional().isString().withMessage('License number must be a string'),
  body('vehicleId').optional().isString().withMessage('Vehicle ID must be a string'),
  body('permissions').optional().isArray().withMessage('Permissions must be an array'),
  body('isActive').optional().isBoolean().withMessage('isActive must be a boolean')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if user belongs to same company (unless super admin)
    if (req.user.role !== 'super_admin' && user.companyId !== req.user.companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Update fields
    const updateFields = ['name', 'email', 'role', 'licenseNumber', 'vehicleId', 'permissions', 'isActive'];
    updateFields.forEach(field => {
      if (req.body[field] !== undefined) {
        user[field] = req.body[field];
      }
    });

    await user.save();

    res.json({
      message: 'User updated successfully',
      user: {
        id: user._id,
        name: user.name,
        phoneNumber: user.phoneNumber,
        role: user.role,
        email: user.email,
        licenseNumber: user.licenseNumber,
        vehicleId: user.vehicleId,
        permissions: user.permissions,
        isActive: user.isActive
      }
    });

  } catch (error) {
    console.error('Update user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   DELETE /api/v1/admin/users/:id
// @desc    Delete user (Admin only)
// @access  Private (Admin only)
router.delete('/users/:id', auth, requirePermission('manage_users'), async (req, res) => {
  try {
    const user = await User.findById(req.params.id);
    if (!user) {
      return res.status(404).json({ error: 'User not found' });
    }

    // Check if user belongs to same company (unless super admin)
    if (req.user.role !== 'super_admin' && user.companyId !== req.user.companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Check if user has active assignments
    const activeAssignments = await Assignment.countDocuments({
      driverId: user._id,
      status: { $in: ['pending', 'accepted', 'in_progress'] }
    });

    if (activeAssignments > 0) {
      return res.status(400).json({ 
        error: 'Cannot delete user with active assignments. Please reassign or complete assignments first.' 
      });
    }

    await User.findByIdAndDelete(req.params.id);

    res.json({ message: 'User deleted successfully' });

  } catch (error) {
    console.error('Delete user error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/admin/dashboard
// @desc    Get admin dashboard stats
// @access  Private (Admin only)
router.get('/dashboard', auth, requireAdmin, async (req, res) => {
  try {
    const companyId = req.user.companyId;

    // Get counts
    const totalDrivers = await User.countDocuments({ 
      companyId, 
      role: 'driver', 
      isActive: true 
    });

    const totalAdmins = await User.countDocuments({ 
      companyId, 
      role: 'admin', 
      isActive: true 
    });

    const totalAssignments = await Assignment.countDocuments({ companyId });
    const pendingAssignments = await Assignment.countDocuments({ 
      companyId, 
      status: 'pending' 
    });
    const inProgressAssignments = await Assignment.countDocuments({ 
      companyId, 
      status: 'in_progress' 
    });
    const completedAssignments = await Assignment.countDocuments({ 
      companyId, 
      status: 'completed' 
    });

    // Get recent assignments
    const recentAssignments = await Assignment.find({ companyId })
      .populate('driverId', 'name phoneNumber')
      .sort({ createdAt: -1 })
      .limit(5);

    // Get assignments by status
    const assignmentsByStatus = await Assignment.aggregate([
      { $match: { companyId } },
      { $group: { _id: '$status', count: { $sum: 1 } } }
    ]);

    // Get assignments by priority
    const assignmentsByPriority = await Assignment.aggregate([
      { $match: { companyId } },
      { $group: { _id: '$priority', count: { $sum: 1 } } }
    ]);

    res.json({
      stats: {
        totalDrivers,
        totalAdmins,
        totalAssignments,
        pendingAssignments,
        inProgressAssignments,
        completedAssignments
      },
      recentAssignments,
      assignmentsByStatus,
      assignmentsByPriority
    });

  } catch (error) {
    console.error('Dashboard error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/admin/reports
// @desc    Get assignment reports
// @access  Private (Admin only)
router.get('/reports', auth, requirePermission('view_reports'), async (req, res) => {
  try {
    const { startDate, endDate, driverId } = req.query;
    const companyId = req.user.companyId;

    let matchQuery = { companyId };

    // Add date filter
    if (startDate && endDate) {
      matchQuery.createdAt = {
        $gte: new Date(startDate),
        $lte: new Date(endDate)
      };
    }

    // Add driver filter
    if (driverId) {
      matchQuery.driverId = driverId;
    }

    // Get assignment statistics
    const assignmentStats = await Assignment.aggregate([
      { $match: matchQuery },
      {
        $group: {
          _id: null,
          totalAssignments: { $sum: 1 },
          completedAssignments: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          cancelledAssignments: {
            $sum: { $cond: [{ $eq: ['$status', 'cancelled'] }, 1, 0] }
          },
          averageCompletionTime: {
            $avg: {
              $cond: [
                { $eq: ['$status', 'completed'] },
                { $subtract: ['$actualDeliveryTime', '$actualPickupTime'] },
                null
              ]
            }
          }
        }
      }
    ]);

    // Get driver performance
    const driverPerformance = await Assignment.aggregate([
      { $match: matchQuery },
      {
        $group: {
          _id: '$driverId',
          totalAssignments: { $sum: 1 },
          completedAssignments: {
            $sum: { $cond: [{ $eq: ['$status', 'completed'] }, 1, 0] }
          },
          averageCompletionTime: {
            $avg: {
              $cond: [
                { $eq: ['$status', 'completed'] },
                { $subtract: ['$actualDeliveryTime', '$actualPickupTime'] },
                null
              ]
            }
          }
        }
      },
      {
        $lookup: {
          from: 'users',
          localField: '_id',
          foreignField: '_id',
          as: 'driver'
        }
      },
      { $unwind: '$driver' },
      {
        $project: {
          driverName: '$driver.name',
          driverPhone: '$driver.phoneNumber',
          totalAssignments: 1,
          completedAssignments: 1,
          completionRate: {
            $multiply: [
              { $divide: ['$completedAssignments', '$totalAssignments'] },
              100
            ]
          },
          averageCompletionTime: 1
        }
      }
    ]);

    res.json({
      assignmentStats: assignmentStats[0] || {
        totalAssignments: 0,
        completedAssignments: 0,
        cancelledAssignments: 0,
        averageCompletionTime: 0
      },
      driverPerformance
    });

  } catch (error) {
    console.error('Reports error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/admin/bulk-assign
// @desc    Bulk assign assignments to drivers
// @access  Private (Admin only)
router.post('/bulk-assign', auth, requirePermission('create_assignments'), [
  body('assignments').isArray().withMessage('Assignments must be an array'),
  body('assignments.*.title').notEmpty().withMessage('Title is required'),
  body('assignments.*.description').notEmpty().withMessage('Description is required'),
  body('assignments.*.driverId').isMongoId().withMessage('Valid driver ID is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { assignments } = req.body;
    const createdAssignments = [];

    for (const assignmentData of assignments) {
      // Check if driver exists and is active
      const driver = await User.findById(assignmentData.driverId);
      if (!driver || driver.role !== 'driver' || !driver.isActive) {
        continue; // Skip invalid drivers
      }

      // Check if driver belongs to same company
      if (driver.companyId !== req.user.companyId) {
        continue; // Skip drivers from other companies
      }

      const assignment = new Assignment({
        ...assignmentData,
        assignedBy: req.user.id,
        companyId: req.user.companyId,
        scheduledPickupTime: assignmentData.scheduledPickupTime ? new Date(assignmentData.scheduledPickupTime) : null,
        scheduledDeliveryTime: assignmentData.scheduledDeliveryTime ? new Date(assignmentData.scheduledDeliveryTime) : null,
        priority: assignmentData.priority || 'medium'
      });

      await assignment.save();
      createdAssignments.push(assignment);
    }

    res.status(201).json({
      message: `${createdAssignments.length} assignments created successfully`,
      assignments: createdAssignments
    });

  } catch (error) {
    console.error('Bulk assign error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 
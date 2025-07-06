const express = require('express');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { body, validationResult } = require('express-validator');
const Assignment = require('../models/Assignment');
const User = require('../models/User');
const { auth, requireAdmin, requirePermission } = require('../middleware/auth');

const router = express.Router();

// Configure multer for file uploads
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadDir = 'uploads/pdfs';
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    cb(null, 'assignment-' + uniqueSuffix + path.extname(file.originalname));
  }
});

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 10 * 1024 * 1024 // 10MB limit
  },
  fileFilter: (req, file, cb) => {
    if (file.mimetype === 'application/pdf') {
      cb(null, true);
    } else {
      cb(new Error('Only PDF files are allowed'), false);
    }
  }
});

// @route   POST /api/v1/assignments
// @desc    Create a new assignment
// @access  Private (Admin only)
router.post('/', auth, requirePermission('create_assignments'), upload.single('pdfFile'), [
  body('title').notEmpty().withMessage('Title is required'),
  body('description').notEmpty().withMessage('Description is required'),
  body('driverId').isMongoId().withMessage('Valid driver ID is required'),
  body('scheduledPickupTime').optional().isISO8601().withMessage('Valid pickup time is required'),
  body('scheduledDeliveryTime').optional().isISO8601().withMessage('Valid delivery time is required'),
  body('priority').optional().isIn(['low', 'medium', 'high', 'urgent']).withMessage('Valid priority is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const {
      title,
      description,
      driverId,
      scheduledPickupTime,
      scheduledDeliveryTime,
      priority,
      pickupLocation,
      deliveryLocation,
      notes,
      estimatedDuration,
      distance
    } = req.body;

    // Check if driver exists and is active
    const driver = await User.findById(driverId);
    if (!driver || driver.role !== 'driver' || !driver.isActive) {
      return res.status(400).json({ error: 'Invalid or inactive driver' });
    }

    // Check if driver belongs to same company
    if (driver.companyId !== req.user.companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Create assignment
    const assignment = new Assignment({
      title,
      description,
      driverId,
      assignedBy: req.user.id,
      companyId: req.user.companyId,
      scheduledPickupTime: scheduledPickupTime ? new Date(scheduledPickupTime) : null,
      scheduledDeliveryTime: scheduledDeliveryTime ? new Date(scheduledDeliveryTime) : null,
      priority: priority || 'medium',
      pickupLocation: pickupLocation ? JSON.parse(pickupLocation) : null,
      deliveryLocation: deliveryLocation ? JSON.parse(deliveryLocation) : null,
      notes,
      estimatedDuration: estimatedDuration ? parseInt(estimatedDuration) : null,
      distance: distance ? parseFloat(distance) : null
    });

    // Handle PDF file upload
    if (req.file) {
      assignment.pdfFile = {
        filename: req.file.filename,
        originalName: req.file.originalname,
        url: `${req.protocol}://${req.get('host')}/uploads/pdfs/${req.file.filename}`,
        size: req.file.size
      };
    }

    await assignment.save();

    // Populate driver details
    await assignment.populate('driverId', 'name phoneNumber');

    res.status(201).json({
      message: 'Assignment created successfully',
      assignment
    });

  } catch (error) {
    console.error('Create assignment error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/assignments
// @desc    Get assignments (filtered by role)
// @access  Private
router.get('/', auth, async (req, res) => {
  try {
    const { status, priority, page = 1, limit = 20 } = req.query;
    const skip = (page - 1) * limit;

    let query = { companyId: req.user.companyId };

    // Drivers can only see their own assignments
    if (req.user.role === 'driver') {
      query.driverId = req.user.id;
    }

    // Apply filters
    if (status) query.status = status;
    if (priority) query.priority = priority;

    const assignments = await Assignment.find(query)
      .populate('driverId', 'name phoneNumber')
      .populate('assignedBy', 'name')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(parseInt(limit));

    const total = await Assignment.countDocuments(query);

    res.json({
      assignments,
      pagination: {
        current: parseInt(page),
        total: Math.ceil(total / limit),
        hasNext: skip + assignments.length < total,
        hasPrev: page > 1
      }
    });

  } catch (error) {
    console.error('Get assignments error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   GET /api/v1/assignments/:id
// @desc    Get assignment by ID
// @access  Private
router.get('/:id', auth, async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id)
      .populate('driverId', 'name phoneNumber licenseNumber vehicleId')
      .populate('assignedBy', 'name');

    if (!assignment) {
      return res.status(404).json({ error: 'Assignment not found' });
    }

    // Check access permissions
    if (req.user.role === 'driver' && assignment.driverId.toString() !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (assignment.companyId !== req.user.companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    res.json({ assignment });

  } catch (error) {
    console.error('Get assignment error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   PUT /api/v1/assignments/:id/status
// @desc    Update assignment status
// @access  Private
router.put('/:id/status', auth, [
  body('status').isIn(['pending', 'accepted', 'in_progress', 'completed', 'cancelled']).withMessage('Valid status is required'),
  body('notes').optional().isString().withMessage('Notes must be a string')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { status, notes } = req.body;

    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ error: 'Assignment not found' });
    }

    // Check access permissions
    if (req.user.role === 'driver' && assignment.driverId.toString() !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    if (assignment.companyId !== req.user.companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Update status
    assignment.status = status;
    
    // Update timestamps based on status
    if (status === 'in_progress' && !assignment.actualPickupTime) {
      assignment.actualPickupTime = new Date();
    } else if (status === 'completed' && !assignment.actualDeliveryTime) {
      assignment.actualDeliveryTime = new Date();
    }

    // Add notes if provided
    if (notes) {
      if (req.user.role === 'driver') {
        assignment.driverNotes = notes;
      } else {
        assignment.notes = notes;
      }
    }

    await assignment.save();

    res.json({
      message: 'Assignment status updated successfully',
      assignment
    });

  } catch (error) {
    console.error('Update assignment status error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   PUT /api/v1/assignments/:id
// @desc    Update assignment (Admin only)
// @access  Private (Admin only)
router.put('/:id', auth, requirePermission('edit_assignments'), upload.single('pdfFile'), [
  body('title').optional().notEmpty().withMessage('Title cannot be empty'),
  body('description').optional().notEmpty().withMessage('Description cannot be empty'),
  body('priority').optional().isIn(['low', 'medium', 'high', 'urgent']).withMessage('Valid priority is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ error: 'Assignment not found' });
    }

    if (assignment.companyId !== req.user.companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Update fields
    const updateFields = ['title', 'description', 'priority', 'scheduledPickupTime', 'scheduledDeliveryTime', 'notes', 'estimatedDuration', 'distance'];
    updateFields.forEach(field => {
      if (req.body[field] !== undefined) {
        if (field === 'scheduledPickupTime' || field === 'scheduledDeliveryTime') {
          assignment[field] = req.body[field] ? new Date(req.body[field]) : null;
        } else if (field === 'estimatedDuration') {
          assignment[field] = req.body[field] ? parseInt(req.body[field]) : null;
        } else if (field === 'distance') {
          assignment[field] = req.body[field] ? parseFloat(req.body[field]) : null;
        } else {
          assignment[field] = req.body[field];
        }
      }
    });

    // Handle location updates
    if (req.body.pickupLocation) {
      assignment.pickupLocation = JSON.parse(req.body.pickupLocation);
    }
    if (req.body.deliveryLocation) {
      assignment.deliveryLocation = JSON.parse(req.body.deliveryLocation);
    }

    // Handle new PDF file upload
    if (req.file) {
      // Delete old file if exists
      if (assignment.pdfFile && assignment.pdfFile.filename) {
        const oldFilePath = path.join('uploads/pdfs', assignment.pdfFile.filename);
        if (fs.existsSync(oldFilePath)) {
          fs.unlinkSync(oldFilePath);
        }
      }

      assignment.pdfFile = {
        filename: req.file.filename,
        originalName: req.file.originalname,
        url: `${req.protocol}://${req.get('host')}/uploads/pdfs/${req.file.filename}`,
        size: req.file.size
      };
    }

    await assignment.save();

    res.json({
      message: 'Assignment updated successfully',
      assignment
    });

  } catch (error) {
    console.error('Update assignment error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   DELETE /api/v1/assignments/:id
// @desc    Delete assignment (Admin only)
// @access  Private (Admin only)
router.delete('/:id', auth, requirePermission('delete_assignments'), async (req, res) => {
  try {
    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ error: 'Assignment not found' });
    }

    if (assignment.companyId !== req.user.companyId) {
      return res.status(403).json({ error: 'Access denied' });
    }

    // Delete PDF file if exists
    if (assignment.pdfFile && assignment.pdfFile.filename) {
      const filePath = path.join('uploads/pdfs', assignment.pdfFile.filename);
      if (fs.existsSync(filePath)) {
        fs.unlinkSync(filePath);
      }
    }

    await Assignment.findByIdAndDelete(req.params.id);

    res.json({ message: 'Assignment deleted successfully' });

  } catch (error) {
    console.error('Delete assignment error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

// @route   POST /api/v1/assignments/:id/location
// @desc    Update current location (Driver only)
// @access  Private
router.post('/:id/location', auth, [
  body('lat').isFloat().withMessage('Valid latitude is required'),
  body('lng').isFloat().withMessage('Valid longitude is required')
], async (req, res) => {
  try {
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({ errors: errors.array() });
    }

    const { lat, lng } = req.body;

    const assignment = await Assignment.findById(req.params.id);
    if (!assignment) {
      return res.status(404).json({ error: 'Assignment not found' });
    }

    // Only driver can update location
    if (assignment.driverId.toString() !== req.user.id) {
      return res.status(403).json({ error: 'Access denied' });
    }

    assignment.currentLocation = {
      coordinates: { lat: parseFloat(lat), lng: parseFloat(lng) },
      timestamp: new Date()
    };

    await assignment.save();

    res.json({
      message: 'Location updated successfully',
      location: assignment.currentLocation
    });

  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({ error: 'Server error' });
  }
});

module.exports = router; 
const mongoose = require('mongoose');

const assignmentSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true
  },
  description: {
    type: String,
    required: true
  },
  driverId: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  assignedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  companyId: {
    type: String,
    required: true
  },
  status: {
    type: String,
    enum: ['pending', 'accepted', 'in_progress', 'completed', 'cancelled'],
    default: 'pending'
  },
  priority: {
    type: String,
    enum: ['low', 'medium', 'high', 'urgent'],
    default: 'medium'
  },
  // Location details
  pickupLocation: {
    address: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  deliveryLocation: {
    address: String,
    coordinates: {
      lat: Number,
      lng: Number
    }
  },
  // Time details
  scheduledPickupTime: {
    type: Date
  },
  scheduledDeliveryTime: {
    type: Date
  },
  actualPickupTime: {
    type: Date
  },
  actualDeliveryTime: {
    type: Date
  },
  // PDF file details
  pdfFile: {
    filename: String,
    originalName: String,
    url: String,
    size: Number,
    uploadedAt: {
      type: Date,
      default: Date.now
    }
  },
  // Additional details
  notes: {
    type: String
  },
  estimatedDuration: {
    type: Number // in minutes
  },
  distance: {
    type: Number // in kilometers
  },
  // Driver feedback
  driverNotes: {
    type: String
  },
  completionNotes: {
    type: String
  },
  // Tracking
  currentLocation: {
    coordinates: {
      lat: Number,
      lng: Number
    },
    timestamp: Date
  },
  // Notifications
  notificationsSent: {
    assignment: { type: Boolean, default: false },
    reminder: { type: Boolean, default: false },
    completion: { type: Boolean, default: false }
  }
}, {
  timestamps: true
});

// Indexes for better query performance
assignmentSchema.index({ driverId: 1, status: 1 });
assignmentSchema.index({ companyId: 1, status: 1 });
assignmentSchema.index({ scheduledPickupTime: 1 });
assignmentSchema.index({ createdAt: -1 });

// Virtual for assignment duration
assignmentSchema.virtual('duration').get(function() {
  if (this.actualPickupTime && this.actualDeliveryTime) {
    return this.actualDeliveryTime - this.actualPickupTime;
  }
  return null;
});

// Method to update status
assignmentSchema.methods.updateStatus = function(newStatus) {
  this.status = newStatus;
  if (newStatus === 'completed' && !this.actualDeliveryTime) {
    this.actualDeliveryTime = new Date();
  }
  return this.save();
};

module.exports = mongoose.model('Assignment', assignmentSchema); 
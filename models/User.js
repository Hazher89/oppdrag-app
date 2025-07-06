const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema({
  email: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    lowercase: true
  },
  name: {
    type: String,
    required: true,
    trim: true
  },
  phoneNumber: {
    type: String,
    trim: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  role: {
    type: String,
    enum: ['driver', 'admin', 'super_admin'],
    default: 'driver'
  },
  companyId: {
    type: String,
    required: true
  },
  isActive: {
    type: Boolean,
    default: true
  },
  deviceToken: {
    type: String
  },
  lastLogin: {
    type: Date
  },
  profileImage: {
    type: String
  },
  resetCode: {
    type: String
  },
  resetCodeExpiry: {
    type: Date
  },
  // Email verification fields
  verificationCode: {
    type: String
  },
  verificationCodeExpiry: {
    type: Date
  },
  isEmailVerified: {
    type: Boolean,
    default: false
  },
  // Driver specific fields
  licenseNumber: {
    type: String
  },
  vehicleId: {
    type: String
  },
  // Admin specific fields
  permissions: [{
    type: String,
    enum: ['create_assignments', 'edit_assignments', 'delete_assignments', 'manage_users', 'view_reports']
  }]
}, {
  timestamps: true
});

// Hash password before saving
userSchema.pre('save', async function(next) {
  if (!this.isModified('password')) return next();
  
  try {
    const salt = await bcrypt.genSalt(10);
    this.password = await bcrypt.hash(this.password, salt);
    next();
  } catch (error) {
    next(error);
  }
});

// Compare password method
userSchema.methods.comparePassword = async function(candidatePassword) {
  return bcrypt.compare(candidatePassword, this.password);
};

// Remove password from JSON response
userSchema.methods.toJSON = function() {
  const user = this.toObject();
  delete user.password;
  return user;
};

module.exports = mongoose.model('User', userSchema); 
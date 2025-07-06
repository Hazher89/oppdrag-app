const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const User = require('./models/User');
require('dotenv').config();

const setupDatabase = async () => {
  try {
    console.log('🔧 Setting up DriveDispatch database...');

    // Connect to MongoDB
    await mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/drivedispatch', {
      useNewUrlParser: true,
      useUnifiedTopology: true,
    });

    console.log('✅ Connected to MongoDB');

    // Check if super admin already exists
    const existingSuperAdmin = await User.findOne({ role: 'super_admin' });
    
    if (existingSuperAdmin) {
      console.log('✅ Super admin already exists');
      return;
    }

    // Create super admin user
    const superAdminData = {
      phoneNumber: process.env.SUPER_ADMIN_PHONE || '+1234567890',
      name: process.env.SUPER_ADMIN_NAME || 'Super Admin',
      password: process.env.SUPER_ADMIN_PASSWORD || 'admin123456',
      email: process.env.SUPER_ADMIN_EMAIL || 'admin@drivedispatch.com',
      role: 'super_admin',
      companyId: 'system',
      permissions: [
        'create_assignments',
        'edit_assignments', 
        'delete_assignments',
        'manage_users',
        'view_reports'
      ],
      isActive: true
    };

    const superAdmin = new User(superAdminData);
    await superAdmin.save();

    console.log('✅ Super admin created successfully');
    console.log('📱 Phone:', superAdminData.phoneNumber);
    console.log('🔑 Password:', superAdminData.password);
    console.log('⚠️  Please change the password after first login!');

    // Create sample company admin
    const sampleAdminData = {
      phoneNumber: '+1987654321',
      name: 'Sample Admin',
      password: 'admin123456',
      email: 'sample@company.com',
      role: 'admin',
      companyId: 'sample-company-001',
      permissions: [
        'create_assignments',
        'edit_assignments',
        'manage_users',
        'view_reports'
      ],
      isActive: true
    };

    const sampleAdmin = new User(sampleAdminData);
    await sampleAdmin.save();

    console.log('✅ Sample company admin created');
    console.log('📱 Phone:', sampleAdminData.phoneNumber);
    console.log('🔑 Password:', sampleAdminData.password);

    // Create sample driver
    const sampleDriverData = {
      phoneNumber: '+1555123456',
      name: 'John Driver',
      password: 'driver123456',
      email: 'john.driver@company.com',
      role: 'driver',
      companyId: 'sample-company-001',
      licenseNumber: 'DL123456789',
      vehicleId: 'VH001',
      isActive: true
    };

    const sampleDriver = new User(sampleDriverData);
    await sampleDriver.save();

    console.log('✅ Sample driver created');
    console.log('📱 Phone:', sampleDriverData.phoneNumber);
    console.log('🔑 Password:', sampleDriverData.password);

    console.log('\n🎉 Database setup completed successfully!');
    console.log('\n📋 Next steps:');
    console.log('1. Start the server: npm start');
    console.log('2. Update the iOS app to use your server URL');
    console.log('3. Login with the sample accounts above');
    console.log('4. Create your own company and users');

  } catch (error) {
    console.error('❌ Setup failed:', error);
    process.exit(1);
  } finally {
    await mongoose.disconnect();
  }
};

// Run setup if this file is executed directly
if (require.main === module) {
  setupDatabase();
}

module.exports = setupDatabase; 
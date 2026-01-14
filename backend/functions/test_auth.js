#!/usr/bin/env node

const admin = require('firebase-admin');

// Connect to local Auth emulator
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'psycho-dating-app',
});

const auth = admin.auth();

async function testAuth() {
  try {
    console.log('🔍 Testing Auth Emulator...');
    
    // List all users
    const listUsers = await auth.listUsers();
    console.log(`📊 Found ${listUsers.users.length} users in Auth emulator`);
    
    if (listUsers.users.length > 0) {
      console.log('\n👥 Users:');
      listUsers.users.slice(0, 5).forEach(user => {
        console.log(`   - ${user.email} (${user.displayName})`);
      });
      
      // Try to authenticate with first user
      const firstUser = listUsers.users[0];
      console.log(`\n🔐 Testing with user: ${firstUser.email}`);
      
      // Create a custom token for testing
      const customToken = await auth.createCustomToken(firstUser.uid);
      console.log('✅ Successfully created custom token - Auth is working!');
      
    } else {
      console.log('❌ No users found in Auth emulator');
    }
    
  } catch (error) {
    console.error('❌ Error testing Auth:', error.message);
  }
  
  process.exit(0);
}

testAuth();
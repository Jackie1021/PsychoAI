#!/usr/bin/env node

const admin = require('firebase-admin');

// Connect to current emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'psycho-dating-app',
});

const auth = admin.auth();

async function testGetMatchesDirectly() {
  try {
    console.log('🧪 Testing getMatches function directly...');
    
    // Get our test user
    const listUsers = await auth.listUsers();
    if (listUsers.users.length === 0) {
      console.log('❌ No users found in Auth emulator');
      return;
    }
    
    const testUser = listUsers.users[0];
    console.log(`👤 Using test user: ${testUser.email}`);
    
    // Create a proper authenticated context like Flutter would
    const mockContext = {
      auth: {
        uid: testUser.uid,
        token: {}
      }
    };
    
    // Import and call the getMatches function directly
    const functions = require('./lib/index.js');
    
    console.log('🔄 Calling getMatches function...');
    
    // This mimics how Firebase Functions calls work
    const result = await functions.getMatches({}, mockContext);
    
    console.log('✅ getMatches function succeeded!');
    console.log('📊 Result:', result);
    
  } catch (error) {
    console.error('❌ Error testing getMatches:', error.message);
    if (error.stack) {
      console.error('Stack:', error.stack.split('\n').slice(0, 5).join('\n'));
    }
  }
  
  process.exit(0);
}

testGetMatchesDirectly();
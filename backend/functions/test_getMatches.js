#!/usr/bin/env node

const admin = require('firebase-admin');

// Connect to the local emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';
process.env.FIREBASE_FUNCTIONS_EMULATOR_HOST = '127.0.0.1:5002';

admin.initializeApp({
  projectId: 'psycho-dating-app',
});

const functions = admin.functions();

async function testGetMatches() {
  try {
    console.log('🔥 Testing getMatches function...');
    
    // Get first user from our data
    const db = admin.firestore();
    const usersSnapshot = await db.collection('users').limit(1).get();
    
    if (usersSnapshot.empty) {
      console.log('❌ No users found in Firestore');
      return;
    }
    
    const testUser = usersSnapshot.docs[0];
    const testUserId = testUser.id;
    const userData = testUser.data();
    
    console.log(`📱 Testing with user: ${userData.username} (${testUserId})`);
    
    // Call the getMatches function
    const getMatches = functions.httpsCallable('getMatches');
    
    console.log('⏳ Calling getMatches function...');
    const result = await getMatches();
    
    console.log('✅ getMatches function executed successfully!');
    console.log('📊 Result:', result.data);
    
  } catch (error) {
    console.error('❌ Error testing getMatches:', error);
    console.error('   Code:', error.code);
    console.error('   Message:', error.message);
    if (error.details) {
      console.error('   Details:', error.details);
    }
  }
  
  process.exit(0);
}

testGetMatches();
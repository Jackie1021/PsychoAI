#!/usr/bin/env node

const admin = require('firebase-admin');

// Connect to the CURRENT running emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'psycho-dating-app',
});

const auth = admin.auth();
const db = admin.firestore();

async function createTestUser() {
  try {
    console.log('🔧 Creating test user in current emulator...');
    
    // Create auth user
    const authUser = await auth.createUser({
      email: 'alice@test.com',
      password: 'test123456',
      displayName: 'Alice Chen',
      emailVerified: true,
    });
    
    console.log(`✅ Created auth user: ${authUser.uid}`);
    
    // Create Firestore user document  
    const userProfile = {
      uid: authUser.uid,
      username: 'Alice Chen',
      email: 'alice@test.com',
      bio: 'Artist • Writer • Mental Health Advocate',
      traits: ['Anxiety', 'OCD', 'PTSD'],
      freeText: '📚 Book lover & creative soul. Finding peace through writing and art therapy.',
      avatarUrl: `https://ui-avatars.com/api/?name=Alice%20Chen`,
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      isSuspended: false,
      reportCount: 0,
    };
    
    await db.collection('users').doc(authUser.uid).set(userProfile);
    console.log('✅ Created Firestore user document');
    
    // Verify user can authenticate
    const listUsers = await auth.listUsers();
    console.log(`📊 Total users in Auth: ${listUsers.users.length}`);
    
    console.log('\n🎉 Test user ready!');
    console.log('📧 Email: alice@test.com');
    console.log('🔑 Password: test123456');
    
  } catch (error) {
    console.error('❌ Error:', error.message);
  }
  
  process.exit(0);
}

createTestUser();
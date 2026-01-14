#!/usr/bin/env node

const admin = require('firebase-admin');

// Connect to current emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'psycho-dating-app',
});

const auth = admin.auth();
const db = admin.firestore();

const QUICK_USERS = [
  {
    email: 'bob@test.com',
    password: 'test123456',
    username: 'Bob Martinez',
    bio: 'Producer • Sound Designer • Community Builder',
    traits: ['Depression', 'ADHD']
  },
  {
    email: 'charlie@test.com',
    password: 'test123456', 
    username: 'Charlie Kim',
    bio: 'Mindfulness Coach • Yoga Instructor • Mental Health Speaker',
    traits: ['Bipolar', 'Anxiety']
  },
  {
    email: 'diana@test.com',
    password: 'test123456',
    username: 'Diana Thompson', 
    bio: 'Software Engineer • Accessibility Advocate • Tech for Good',
    traits: ['ADHD', 'Autism']
  }
];

async function createMoreUsers() {
  console.log('🚀 Creating additional test users...');
  
  for (const userData of QUICK_USERS) {
    try {
      const authUser = await auth.createUser({
        email: userData.email,
        password: userData.password,
        displayName: userData.username,
        emailVerified: true,
      });
      
      const userProfile = {
        uid: authUser.uid,
        username: userData.username,
        email: userData.email,
        bio: userData.bio,
        traits: userData.traits,
        avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.username)}`,
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isSuspended: false,
        reportCount: 0,
      };
      
      await db.collection('users').doc(authUser.uid).set(userProfile);
      console.log(`✅ ${userData.username} (${userData.email})`);
      
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log(`ℹ️ ${userData.email} already exists`);
      } else {
        console.log(`❌ Error creating ${userData.email}: ${error.message}`);
      }
    }
  }
  
  const listUsers = await auth.listUsers();
  console.log(`\n🎉 Total users: ${listUsers.users.length}`);
  console.log('\n📧 All accounts use password: test123456');
  
  process.exit(0);
}

createMoreUsers();
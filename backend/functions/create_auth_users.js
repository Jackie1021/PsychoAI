const admin = require('firebase-admin');

// Initialize with correct project ID and connect to emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'studio-291983403-af613',  // Use the project ID the app expects
});

const auth = admin.auth();
const db = admin.firestore();

// Test users data
const TEST_USERS = [
  {
    email: 'alice@test.com',
    password: 'test123456',
    username: 'Alice Chen',
    traits: ['Anxiety', 'OCD', 'PTSD'],
    freeText: '📚 Book lover & creative soul. Finding peace through writing and art therapy.',
  },
  {
    email: 'bob@test.com',
    password: 'test123456',
    username: 'Bob Martinez',
    traits: ['Depression', 'ADHD'],
    freeText: '🎵 Music producer exploring the intersection of creativity and healing.',
  },
  {
    email: 'charlie@test.com',
    password: 'test123456',
    username: 'Charlie Kim',
    traits: ['Bipolar', 'Anxiety'],
    freeText: '🧘 Mindfulness coach sharing my journey with bipolar disorder.',
  },
  {
    email: 'diana@test.com',
    password: 'test123456',
    username: 'Diana Thompson',
    traits: ['ADHD', 'Autism'],
    freeText: '💻 Software engineer celebrating neurodiversity in tech.',
  },
  {
    email: 'eve@test.com',
    password: 'test123456',
    username: 'Eve Rodriguez',
    traits: ['PTSD', 'BPD'],
    freeText: '🌱 Trauma-informed therapist and survivor.',
  },
  {
    email: 'frank@test.com',
    password: 'test123456',
    username: 'Frank Johnson',
    traits: ['OCD', 'Depression'],
    freeText: '📸 Nature photographer finding beauty in the details.',
  }
];

async function createAuthUsers() {
  console.log('🌱 Creating Firebase Auth users...');

  for (const userData of TEST_USERS) {
    try {
      // Create user in Firebase Auth
      const userRecord = await auth.createUser({
        email: userData.email,
        password: userData.password,
        displayName: userData.username,
        emailVerified: true,
      });

      console.log(`  ✅ Created auth user: ${userData.username} (${userData.email})`);

      // Create or update user document in Firestore
      await db.collection('users').doc(userRecord.uid).set({
        uid: userRecord.uid,
        username: userData.username,
        email: userData.email,
        traits: userData.traits,
        freeText: userData.freeText,
        bio: userData.freeText,
        followedBloggerIds: [],
        favoritedPostIds: [],
        favoritedConversationIds: [],
        likedPostIds: [],
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        membershipTier: 'free',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        isSuspended: false,
        reportCount: 0,
      });

      console.log(`  ✅ Created Firestore profile for: ${userData.username}`);

    } catch (error) {
      console.log(`  ⚠️  Error creating ${userData.email}: ${error.message}`);
    }
  }

  console.log('\n✨ Auth users creation complete!');
  console.log('\n📊 You can now login with:');
  TEST_USERS.forEach(user => {
    console.log(`   - ${user.email} / ${user.password}`);
  });
}

createAuthUsers()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Error creating auth users:', error);
    process.exit(1);
  });
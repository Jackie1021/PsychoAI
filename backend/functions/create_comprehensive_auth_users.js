const admin = require('firebase-admin');

// Connect to emulators with the correct project ID from the seed script
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'studio-291983403-af613',  // Same as in seed_emulator.js
});

const auth = admin.auth();

// Test users data from seed_emulator.js
const TEST_USERS = [
  {
    email: 'alice@test.com',
    password: 'test123456',
    username: 'Alice Chen',
    traits: ['Anxiety', 'OCD', 'PTSD'],
    freeText: '📚 Book lover & creative soul. Finding peace through writing and art therapy. Currently working on my first novel while managing anxiety with mindfulness practices.',
    bio: 'Artist • Writer • Mental Health Advocate'
  },
  {
    email: 'bob@test.com',
    password: 'test123456',
    username: 'Bob Martinez',
    traits: ['Depression', 'ADHD'],
    freeText: '🎵 Music producer exploring the intersection of creativity and healing. ADHD brain with a passion for electronic soundscapes and community building.',
    bio: 'Producer • Sound Designer • Community Builder'
  },
  {
    email: 'charlie@test.com',
    password: 'test123456',
    username: 'Charlie Kim',
    traits: ['Bipolar', 'Anxiety'],
    freeText: '🧘 Mindfulness coach sharing my journey with bipolar disorder. Passionate about meditation, yoga, and creating safe spaces for authentic conversations.',
    bio: 'Mindfulness Coach • Yoga Instructor • Mental Health Speaker'
  },
  {
    email: 'diana@test.com',
    password: 'test123456',
    username: 'Diana Thompson',
    traits: ['ADHD', 'Autism'],
    freeText: '💻 Software engineer celebrating neurodiversity in tech. Special interests in AI ethics and accessibility. Building tools that make the world more inclusive.',
    bio: 'Software Engineer • Accessibility Advocate • Tech for Good'
  },
  {
    email: 'eve@test.com',
    password: 'test123456',
    username: 'Eve Rodriguez',
    traits: ['PTSD', 'BPD'],
    freeText: '🌱 Trauma-informed therapist and survivor. Specializing in DBT and somatic approaches. Committed to helping others find their path to healing and growth.',
    bio: 'Therapist • Trauma Survivor • Healing Advocate'
  },
  {
    email: 'frank@test.com',
    password: 'test123456',
    username: 'Frank Johnson',
    traits: ['OCD', 'Depression'],
    freeText: '📸 Nature photographer finding beauty in the details. Using mindful photography as a tool for managing OCD while exploring the great outdoors.',
    bio: 'Photographer • Nature Enthusiast • Mental Health Warrior'
  }
];

async function createComprehensiveAuthUsers() {
  console.log('🌱 Creating comprehensive Firebase Auth users...');
  console.log('   Using project ID: studio-291983403-af613');

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

    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log(`  ✅ Auth user already exists: ${userData.username} (${userData.email})`);
      } else {
        console.log(`  ⚠️  Error creating ${userData.email}: ${error.message}`);
      }
    }
  }

  console.log('\n✨ Comprehensive auth users creation complete!');
  console.log('\n📊 You can now login with any of these rich profiles:');
  TEST_USERS.forEach(user => {
    console.log(`   - ${user.email} / ${user.password} (${user.bio})`);
  });
}

createComprehensiveAuthUsers()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Error creating comprehensive auth users:', error);
    process.exit(1);
  });
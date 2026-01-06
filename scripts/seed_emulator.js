#!/usr/bin/env node
/**
 * Seed script for Firebase Emulator
 * Creates test users and posts for development
 */

const admin = require('firebase-admin');

// Initialize Firebase Admin with emulator settings
// Use IP addresses to match emulator output (avoid potential localhost resolution issues).
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'studio-291983403-af613',
});

const db = admin.firestore();
const auth = admin.auth();

// Test users data with diverse traits and rich profiles
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
  
// Rich, authentic community posts
const SAMPLE_POSTS = [
  // Alice (Artist/Writer)
  '📝 Today marks 30 days of consistent journaling. My therapist was right - writing down the anxious thoughts helps externalize them. What grounding techniques work best for you?',
  '🎨 Finished my first painting in months today. The colors felt chaotic but somehow that matched my headspace perfectly. Art therapy is becoming my lifeline.',
  'Book recommendation: "The Body Keeps the Score" changed how I understand my PTSD triggers. Anyone else find reading about trauma both helpful and overwhelming?',
  
  // Bob (Music Producer)
  '🎵 Spent the weekend creating a 10-minute ambient track for meditation. ADHD brain + hyperfocus = unexpected productivity bursts! Sharing the link in comments.',
  'Coffee shop conversations today reminded me why community matters. Feeling grateful for spaces where we can just... exist without explanation.',
  'Question: Does anyone else use music as emotional regulation? I have different playlists for different moods/states.',
  
  // Charlie (Mindfulness Coach)
  '🧘‍♀️ Leading a mindfulness session for fellow bipolar folks tomorrow. Nervous but excited to share what\'s helped me find stability.',
  'Manic episodes used to terrify me. Now I\'m learning to surf the waves instead of fighting them. Small victories count.',
  'Reminder: Your healing journey doesn\'t need to look like anyone else\'s. Comparison is the thief of peace.',
  
  // Diana (Software Engineer)
  '💻 Working on an app feature that adds audio descriptions for images. Small steps toward a more accessible digital world.',
  'Autism masking is exhausting. Today I chose authenticity over fitting in, and it felt revolutionary.',
  'Special interest rabbit hole of the week: Byzantine mosaics. The patterns are mathematically beautiful!',
  
  // Eve (Therapist)
  '🌱 Three years into my healing journey from complex PTSD. Some days are harder than others, but progress isn\'t linear.',
  'Facilitating a DBT skills group tonight. There\'s something powerful about survivors helping other survivors.',
  'Self-care isn\'t selfish. It took me years to truly believe this. What does your self-care look like?',
  
  // Frank (Photographer)
  '📸 Captured the most incredible sunrise this morning. OCD thoughts were loud, but nature was louder.',
  'Photography taught me that sometimes the most beautiful shots come from unexpected angles. Life lesson, maybe?',
  'Mental health check-in: The intrusive thoughts are challenging today, but I\'m practicing the response prevention techniques.',
];

async function clearExistingData() {
  console.log('🧹 Clearing existing test data...');
  
  // Clear users
  const users = await db.collection('users').get();
  const userBatch = db.batch();
  users.docs.forEach(doc => userBatch.delete(doc.ref));
  await userBatch.commit();
  
  // Clear posts
  const posts = await db.collection('posts').get();
  const postBatch = db.batch();
  posts.docs.forEach(doc => postBatch.delete(doc.ref));
  await postBatch.commit();
  
  // Clear auth users
  const authUsers = await auth.listUsers();
  for (const user of authUsers.users) {
    await auth.deleteUser(user.uid);
  }
  
  console.log('✅ Cleared existing data');
}

async function createTestUsers() {
  console.log('👥 Creating test users...');
  const createdUsers = [];
  
  for (const userData of TEST_USERS) {
    try {
      // Create auth user
      const authUser = await auth.createUser({
        email: userData.email,
        password: userData.password,
        displayName: userData.username,
      });
      
      // Create Firestore user document
      // Check if document already exists (might be created by Cloud Function)
      const userRef = db.collection('users').doc(authUser.uid);
      const existingDoc = await userRef.get();
      
      const userProfile = {
        uid: authUser.uid,
        username: userData.username,
        email: userData.email,
        avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.username)}`,
        bio: userData.bio,
        traits: userData.traits,
        freeText: userData.freeText,
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        isSuspended: false,
        reportCount: 0,
        createdAt: existingDoc.exists ? existingDoc.data()?.createdAt : admin.firestore.FieldValue.serverTimestamp(),
        followedBloggerIds: [],
        favoritedPostIds: [],
        favoritedConversationIds: [],
        likedPostIds: [],
        followersCount: 0,
        followingCount: 0,
        postsCount: 0,
        privacy: {
          visibility: 'public',
        },
      };
      
      // Use merge: true to preserve existing fields and ensure bio/traits are set
      await userRef.set(userProfile, { merge: true });
      
      // Verify the document was created correctly
      const verifyDoc = await userRef.get();
      const verifyData = verifyDoc.data();
      if (!verifyData) {
        console.error(`   ✗ Error: User document for ${userData.username} is missing!`);
      } else if (!verifyData.bio || !verifyData.traits || !Array.isArray(verifyData.traits) || verifyData.traits.length === 0) {
        console.warn(`   ⚠️  Warning: User ${userData.username} may be missing bio or traits`);
        console.warn(`      Bio: "${verifyData.bio || 'missing'}"`);
        console.warn(`      Traits: ${JSON.stringify(verifyData.traits || [])}`);
        console.warn(`      Expected bio: "${userData.bio}"`);
        console.warn(`      Expected traits: ${JSON.stringify(userData.traits)}`);
      } else {
        console.log(`   ✓ Verified: ${userData.username} has bio and ${verifyData.traits.length} traits`);
      }
      
      createdUsers.push({
        uid: authUser.uid,
        username: userData.username,
        email: userData.email,
      });
      
      console.log(`   ✓ Created user: ${userData.username} (${userData.email})`);
    } catch (error) {
      console.error(`   ✗ Error creating user ${userData.username}:`, error.message);
    }
  }
  
  return createdUsers;
}

async function createTestPosts(users) {
  console.log('📝 Creating test posts...');
  
  let postCount = 0;
  
  for (let i = 0; i < users.length; i++) {
    const user = users[i];
    // Each user creates 1-2 posts
    const numPosts = Math.floor(Math.random() * 2) + 1;
    
    for (let j = 0; j < numPosts; j++) {
      const postContent = SAMPLE_POSTS[postCount % SAMPLE_POSTS.length];
      
      const postData = {
        userId: user.uid,
        text: postContent,
        media: [],
        mediaType: 'text',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'visible',
        reportCount: 0,
        likeCount: 0,
        commentCount: 0,
        favoriteCount: 0,
        isPublic: true,
      };
      
      await db.collection('posts').add(postData);
      
      // Update user's post count
      await db.collection('users').doc(user.uid).update({
        postsCount: admin.firestore.FieldValue.increment(1),
      });
      
      console.log(`   ✓ Created post by ${user.username}: ${postContent.substring(0, 40)}...`);
      postCount++;
    }
  }
  
  console.log(`✅ Created ${postCount} test posts`);
}

async function seed() {
  try {
    console.log('🌱 Starting emulator seed...\n');
    
    await clearExistingData();
    const users = await createTestUsers();
    await createTestPosts(users);
    
    console.log('\n✨ Seed complete!');
    console.log(`\n📊 Summary:`);
    console.log(`   - ${users.length} users created`);
    console.log(`   - Test credentials: any email above with password "test123456"`);
    console.log(`   - Example: alice@test.com / test123456\n`);
    
    process.exit(0);
  } catch (error) {
    console.error('❌ Seed failed:', error);
    process.exit(1);
  }
}

seed();

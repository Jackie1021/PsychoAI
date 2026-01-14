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

const RICH_USERS = [
  {
    email: 'alice@test.com',
    password: 'test123456',
    username: 'Alice Chen',
    bio: 'Art Therapist • Mental Health Advocate • Painting & Meditation Enthusiast',
    traits: ['Anxiety', 'Depression'],
    freeText: 'I believe in the healing power of creativity and mindfulness. Looking for someone who appreciates deep conversations about life, art, and personal growth.'
  },
  {
    email: 'bob@test.com',
    password: 'test123456',
    username: 'Bob Martinez',
    bio: 'Music Producer • Sound Designer • Community Builder',
    traits: ['Depression', 'ADHD'],
    freeText: 'Music is my therapy and my passion. I love creating beats that help people feel understood. Looking for a creative soul who gets the ups and downs of life.'
  },
  {
    email: 'charlie@test.com',
    password: 'test123456', 
    username: 'Charlie Kim',
    bio: 'Mindfulness Coach • Yoga Instructor • Mental Health Speaker',
    traits: ['Bipolar', 'Anxiety'],
    freeText: 'Teaching others to find peace in chaos. I understand the journey of mental health and believe in supporting each other through it all.'
  },
  {
    email: 'diana@test.com',
    password: 'test123456',
    username: 'Diana Thompson', 
    bio: 'Software Engineer • Accessibility Advocate • Tech for Good',
    traits: ['ADHD', 'Autism'],
    freeText: 'Building technology that makes the world more inclusive. Love coding, board games, and honest conversations about neurodiversity.'
  },
  {
    email: 'emma@test.com',
    password: 'test123456',
    username: 'Emma Rodriguez',
    bio: 'Creative Writer • Mental Health Blogger • Cat Mom',
    traits: ['Depression', 'Anxiety'],
    freeText: 'Words are my way of processing the world. Writing about mental health to break stigmas. Looking for someone who values emotional intelligence.'
  },
  {
    email: 'felix@test.com',
    password: 'test123456',
    username: 'Felix Wong',
    bio: 'Therapist • Rock Climber • Mindful Living Enthusiast',
    traits: ['PTSD'],
    freeText: 'Helping others heal while on my own journey. Love outdoor adventures and quiet moments equally. Seeking authentic connection.'
  },
  {
    email: 'grace@test.com',
    password: 'test123456',
    username: 'Grace Johnson',
    bio: 'Social Worker • Community Organizer • Plant Parent',
    traits: ['Anxiety', 'OCD'],
    freeText: 'Passionate about social justice and mental health awareness. Love tending to my plants and creating safe spaces for healing.'
  },
  {
    email: 'henry@test.com',
    password: 'test123456',
    username: 'Henry Park',
    bio: 'Graphic Designer • Digital Artist • Mental Health Advocate',
    traits: ['Bipolar', 'ADHD'],
    freeText: 'Creating visual stories that matter. Art helps me express what words cannot. Looking for someone who appreciates creativity and authenticity.'
  },
  {
    email: 'iris@test.com',
    password: 'test123456',
    username: 'Iris Anderson',
    bio: 'Nurse • Wellness Coach • Hiking Enthusiast',
    traits: ['Depression'],
    freeText: 'Caring for others while learning to care for myself. Nature is my sanctuary. Seeking someone who values compassion and growth.'
  },
  {
    email: 'jack@test.com',
    password: 'test123456',
    username: 'Jack Cooper',
    bio: 'Chef • Mindful Eating Advocate • Community Kitchen Volunteer',
    traits: ['Anxiety', 'ADHD'],
    freeText: 'Food is love, and cooking is meditation. Building community through shared meals. Looking for someone who appreciates simple joys.'
  },
  {
    email: 'kelly@test.com',
    password: 'test123456',
    username: 'Kelly Davis',
    bio: 'Photographer • Mental Health Storyteller • Dog Lover',
    traits: ['PTSD', 'Depression'],
    freeText: 'Capturing moments of beauty in everyday life. Using photography to tell stories of resilience and hope.'
  },
  {
    email: 'luna@test.com',
    password: 'test123456',
    username: 'Luna Garcia',
    bio: 'Meditation Teacher • Wellness Blogger • Sustainable Living Advocate',
    traits: ['Anxiety'],
    freeText: 'Teaching mindfulness and living consciously. Believe in the power of presence and authentic connection.'
  },
  {
    email: 'max@test.com',
    password: 'test123456',
    username: 'Max Taylor',
    bio: 'Video Game Developer • Accessibility Designer • Mental Health Gamer',
    traits: ['Autism', 'Anxiety'],
    freeText: 'Creating inclusive gaming experiences. Love deep dives into game mechanics and meaningful conversations about neurodiversity.'
  },
  {
    email: 'nina@test.com',
    password: 'test123456',
    username: 'Nina Patel',
    bio: 'Dance Movement Therapist • Performance Artist • Body Positivity Advocate',
    traits: ['Depression', 'ADHD'],
    freeText: 'Movement is medicine. Helping others find joy and healing through dance. Looking for someone who celebrates authenticity.'
  },
  {
    email: 'oscar@test.com',
    password: 'test123456',
    username: 'Oscar Lee',
    bio: 'Librarian • Book Club Host • Quiet Activism Enthusiast',
    traits: ['Anxiety', 'Autism'],
    freeText: 'Books are my world and sanctuary. Creating spaces for quiet connection and meaningful discussions about life and literature.'
  }
];

async function createRichTestUsers() {
  console.log('🚀 Creating rich test user environment...');
  
  let createdCount = 0;
  let existingCount = 0;
  
  for (const userData of RICH_USERS) {
    try {
      // Create auth user
      const authUser = await auth.createUser({
        email: userData.email,
        password: userData.password,
        displayName: userData.username,
        emailVerified: true,
      });
      
      // Create detailed user profile
      const userProfile = {
        uid: authUser.uid,
        username: userData.username,
        email: userData.email,
        bio: userData.bio,
        traits: userData.traits,
        freeText: userData.freeText,
        avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.username)}&size=200&background=random`,
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isSuspended: false,
        reportCount: 0,
        followersCount: Math.floor(Math.random() * 50),
        followingCount: Math.floor(Math.random() * 30),
        postsCount: Math.floor(Math.random() * 20),
        followedBloggerIds: [],
        favoritedPostIds: [],
        favoritedConversationIds: [],
        likedPostIds: [],
        privacy: {
          visibility: 'public',
        },
        verificationStatus: 'verified',
        membershipTier: Math.random() > 0.7 ? 'premium' : 'basic',
      };
      
      await db.collection('users').doc(authUser.uid).set(userProfile);
      console.log(`✅ Created: ${userData.username} (${userData.email})`);
      createdCount++;
      
    } catch (error) {
      if (error.code === 'auth/email-already-exists') {
        console.log(`ℹ️  Already exists: ${userData.email}`);
        existingCount++;
      } else {
        console.log(`❌ Error creating ${userData.email}: ${error.message}`);
      }
    }
  }
  
  // Create some sample posts for engagement
  console.log('\n📝 Creating sample posts...');
  const samplePosts = [
    {
      title: "Finding Peace in the Storm",
      content: "Today was tough, but I'm learning that it's okay to not be okay. Small steps forward.",
      mood: "reflective",
      tags: ["mentalhealth", "selfcare", "growth"]
    },
    {
      title: "Art Therapy Success",
      content: "Finished my first painting in therapy today. Amazing how colors can express what words cannot.",
      mood: "hopeful",
      tags: ["arttherapy", "creativity", "healing"]
    },
    {
      title: "Mindful Monday",
      content: "Starting the week with 10 minutes of meditation. Anyone else finding peace in small routines?",
      mood: "peaceful",
      tags: ["mindfulness", "meditation", "routine"]
    }
  ];
  
  // Get list of users to assign posts
  const allUsers = await auth.listUsers();
  const userIds = allUsers.users.slice(0, Math.min(5, allUsers.users.length)).map(u => u.uid);
  
  for (let i = 0; i < samplePosts.length && i < userIds.length; i++) {
    const post = samplePosts[i];
    const authorId = userIds[i];
    
    const postDoc = {
      ...post,
      authorId,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      likesCount: Math.floor(Math.random() * 15),
      commentsCount: Math.floor(Math.random() * 8),
      isPublic: true
    };
    
    await db.collection('posts').add(postDoc);
  }
  
  const totalUsers = await auth.listUsers();
  console.log(`\\n🎉 Virtual environment ready!`);
  console.log(`📊 Total users: ${totalUsers.users.length} (${createdCount} created, ${existingCount} existing)`);
  console.log(`📝 Sample posts created: ${Math.min(samplePosts.length, userIds.length)}`);
  console.log(`\\n🔐 All accounts use password: test123456`);
  console.log(`\\n💡 Users have diverse traits and backgrounds for rich matching:`);
  
  // Show trait distribution
  const traitCounts = {};
  RICH_USERS.forEach(user => {
    user.traits.forEach(trait => {
      traitCounts[trait] = (traitCounts[trait] || 0) + 1;
    });
  });
  
  Object.entries(traitCounts).forEach(([trait, count]) => {
    console.log(`   ${trait}: ${count} users`);
  });
  
  process.exit(0);
}

createRichTestUsers();
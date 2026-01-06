#!/bin/bash

echo "🌱 Seeding chat data for testing..."

# Make sure Firebase emulator is running
if ! nc -z localhost 8081 2>/dev/null; then
    echo "❌ Firebase emulator is not running!"
    echo "   Please run ./START_BACKEND.sh first"
    exit 1
fi

echo "✅ Firebase emulator is running"

# Create seed data script
cat > /tmp/seed_chat_data.js << 'EOF'
const admin = require('firebase-admin');

admin.initializeApp({
  projectId: 'demo-test',
});

// Connect to emulator
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8081';

const db = admin.firestore();

async function seedChatData() {
  console.log('🌱 Creating test users and conversations...');

  const testUsers = [
    {
      id: 'test_user_alice',
      name: 'Alice Wonder',
      bio: 'Love exploring new ideas and deep conversations',
      avatar: null,
      traits: ['creative', 'thoughtful', 'curious'],
    },
    {
      id: 'test_user_bob',
      name: 'Bob Builder',
      bio: 'Building dreams one brick at a time',
      avatar: null,
      traits: ['practical', 'optimistic', 'hardworking'],
    },
    {
      id: 'test_user_carol',
      name: 'Carol Singer',
      bio: 'Music is life, life is music 🎵',
      avatar: null,
      traits: ['artistic', 'passionate', 'expressive'],
    },
  ];

  // Create test users
  for (const user of testUsers) {
    await db.collection('users').doc(user.id).set({
      uid: user.id,
      name: user.name,
      bio: user.bio,
      avatar: user.avatar,
      traits: user.traits,
      freeText: user.bio,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      onlineStatus: 'online',
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log(`  ✅ Created user: ${user.name}`);
  }

  // Note: You'll need to replace 'current_user_id' with actual logged-in user ID
  console.log('\n📝 To create conversations:');
  console.log('   1. Log in to the app with your account');
  console.log('   2. Go to Match page and match with test users');
  console.log('   3. Or manually create conversations using the chat UI');
  console.log('\n💡 Test user IDs:');
  testUsers.forEach(user => {
    console.log(`   - ${user.name}: ${user.id}`);
  });

  console.log('\n✨ Seed data created successfully!');
}

seedChatData()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error('❌ Error seeding data:', error);
    process.exit(1);
  });
EOF

# Run the seed script
cd backend/functions
node /tmp/seed_chat_data.js

echo ""
echo "✅ Chat seed data created!"
echo "   Log in to the app and start chatting with test users"

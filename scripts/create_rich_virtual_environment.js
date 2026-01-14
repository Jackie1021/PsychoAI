#!/usr/bin/env node
/**
 * 创建丰富的虚拟环境
 * 包含多样化用户、真实内容、匹配关系等
 */

const admin = require('firebase-admin');

// 连接到emulator，使用正确的项目ID
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'studio-291983403-af613',  // 使用Flutter应用配置的项目ID
});

const db = admin.firestore();
const auth = admin.auth();

// 扩展的虚拟用户数据库 - 20个多样化用户
const COMPREHENSIVE_USERS = [
  // 原始核心用户
  {
    email: 'alice@test.com',
    password: 'test123456',
    username: 'Alice Chen',
    age: 28,
    location: 'San Francisco, CA',
    traits: ['Anxiety', 'OCD', 'PTSD'],
    interests: ['Writing', 'Art Therapy', 'Reading', 'Journaling'],
    freeText: '📚 Book lover & creative soul. Finding peace through writing and art therapy. Currently working on my first novel while managing anxiety with mindfulness practices.',
    bio: 'Artist • Writer • Mental Health Advocate',
    avatarColor: '#E91E63',
    membershipTier: 'premium'
  },
  {
    email: 'bob@test.com',
    password: 'test123456',
    username: 'Bob Martinez',
    age: 32,
    location: 'Los Angeles, CA',
    traits: ['Depression', 'ADHD'],
    interests: ['Music Production', 'Electronic Music', 'Community Building', 'Meditation'],
    freeText: '🎵 Music producer exploring the intersection of creativity and healing. ADHD brain with a passion for electronic soundscapes and community building.',
    bio: 'Producer • Sound Designer • Community Builder',
    avatarColor: '#2196F3',
    membershipTier: 'pro'
  },
  {
    email: 'charlie@test.com',
    password: 'test123456',
    username: 'Charlie Kim',
    age: 29,
    location: 'Seattle, WA',
    traits: ['Bipolar', 'Anxiety'],
    interests: ['Mindfulness', 'Yoga', 'Public Speaking', 'Mental Health Education'],
    freeText: '🧘 Mindfulness coach sharing my journey with bipolar disorder. Passionate about meditation, yoga, and creating safe spaces for authentic conversations.',
    bio: 'Mindfulness Coach • Yoga Instructor • Mental Health Speaker',
    avatarColor: '#4CAF50',
    membershipTier: 'premium'
  },
  {
    email: 'diana@test.com',
    password: 'test123456',
    username: 'Diana Thompson',
    age: 26,
    location: 'Austin, TX',
    traits: ['ADHD', 'Autism'],
    interests: ['Programming', 'AI Ethics', 'Accessibility', 'Byzantine Art'],
    freeText: '💻 Software engineer celebrating neurodiversity in tech. Special interests in AI ethics and accessibility. Building tools that make the world more inclusive.',
    bio: 'Software Engineer • Accessibility Advocate • Tech for Good',
    avatarColor: '#9C27B0',
    membershipTier: 'free'
  },
  {
    email: 'eve@test.com',
    password: 'test123456',
    username: 'Eve Rodriguez',
    age: 34,
    location: 'Denver, CO',
    traits: ['PTSD', 'BPD'],
    interests: ['DBT', 'Trauma Recovery', 'Group Therapy', 'Somatic Healing'],
    freeText: '🌱 Trauma-informed therapist and survivor. Specializing in DBT and somatic approaches. Committed to helping others find their path to healing and growth.',
    bio: 'Therapist • Trauma Survivor • Healing Advocate',
    avatarColor: '#FF9800',
    membershipTier: 'pro'
  },
  {
    email: 'frank@test.com',
    password: 'test123456',
    username: 'Frank Johnson',
    age: 31,
    location: 'Portland, OR',
    traits: ['OCD', 'Depression'],
    interests: ['Photography', 'Nature', 'Hiking', 'Mindful Living'],
    freeText: '📸 Nature photographer finding beauty in the details. Using mindful photography as a tool for managing OCD while exploring the great outdoors.',
    bio: 'Photographer • Nature Enthusiast • Mental Health Warrior',
    avatarColor: '#795548',
    membershipTier: 'premium'
  },

  // 新增用户 - 更多多样性
  {
    email: 'grace@test.com',
    password: 'test123456',
    username: 'Grace Liu',
    age: 25,
    location: 'New York, NY',
    traits: ['Social Anxiety', 'Perfectionism'],
    interests: ['Dance', 'Movement Therapy', 'Cultural Arts', 'Self-Expression'],
    freeText: '💃 Dance therapist using movement to heal social anxiety. Passionate about cultural fusion and helping others find their voice through creative expression.',
    bio: 'Dance Therapist • Cultural Artist • Movement Healer',
    avatarColor: '#F44336',
    membershipTier: 'free'
  },
  {
    email: 'henry@test.com',
    password: 'test123456',
    username: 'Henry Davis',
    age: 30,
    location: 'Chicago, IL',
    traits: ['Autism', 'Social Anxiety'],
    interests: ['Board Games', 'Mathematics', 'Pattern Recognition', 'Community'],
    freeText: '🎲 Math professor and board game enthusiast. Autism helps me see patterns others miss. Building inclusive gaming communities one session at a time.',
    bio: 'Mathematics Professor • Game Designer • Pattern Thinker',
    avatarColor: '#607D8B',
    membershipTier: 'premium'
  },
  {
    email: 'iris@test.com',
    password: 'test123456',
    username: 'Iris Patel',
    age: 27,
    location: 'Miami, FL',
    traits: ['Chronic Pain', 'Depression'],
    interests: ['Adaptive Sports', 'Resilience', 'Advocacy', 'Ocean Therapy'],
    freeText: '🌊 Adaptive sports coach living with chronic pain. Teaching resilience through movement and ocean therapy. Every wave teaches us something about persistence.',
    bio: 'Adaptive Sports Coach • Resilience Trainer • Ocean Lover',
    avatarColor: '#00BCD4',
    membershipTier: 'pro'
  },
  {
    email: 'jack@test.com',
    password: 'test123456',
    username: 'Jack Williams',
    age: 35,
    location: 'Boston, MA',
    traits: ['PTSD', 'Addiction Recovery'],
    interests: ['Peer Support', 'Recovery', 'Woodworking', 'Mindfulness'],
    freeText: '🔨 Carpenter in recovery, peer support specialist. PTSD led me to addiction, recovery led me to purpose. Building furniture and rebuilding lives.',
    bio: 'Carpenter • Recovery Coach • Peer Support Specialist',
    avatarColor: '#8BC34A',
    membershipTier: 'free'
  },
  {
    email: 'kate@test.com',
    password: 'test123456',
    username: 'Kate Anderson',
    age: 24,
    location: 'Nashville, TN',
    traits: ['Eating Disorder', 'Body Dysmorphia'],
    interests: ['Nutrition', 'Body Positivity', 'Songwriting', 'Self-Love'],
    freeText: '🎵 Singer-songwriter and nutrition student. Eating disorder recovery taught me to love my body as an instrument, not an ornament.',
    bio: 'Singer-Songwriter • Nutrition Student • Body Positivity Advocate',
    avatarColor: '#E91E63',
    membershipTier: 'premium'
  },
  {
    email: 'liam@test.com',
    password: 'test123456',
    username: 'Liam O\'Connor',
    age: 29,
    location: 'Phoenix, AZ',
    traits: ['ADHD', 'Rejection Sensitivity'],
    interests: ['Entrepreneurship', 'Innovation', 'Rapid Prototyping', 'Failure Celebration'],
    freeText: '🚀 Serial entrepreneur with ADHD. Rejection sensitivity drove me to create rather than conform. Failure is just iteration in disguise.',
    bio: 'Entrepreneur • Innovation Catalyst • Failure Celebrant',
    avatarColor: '#FF5722',
    membershipTier: 'pro'
  },
  {
    email: 'maya@test.com',
    password: 'test123456',
    username: 'Maya Sharma',
    age: 26,
    location: 'San Diego, CA',
    traits: ['Panic Disorder', 'Agoraphobia'],
    interests: ['Virtual Reality', 'Exposure Therapy', 'Digital Art', 'Safe Spaces'],
    freeText: '🥽 VR developer creating exposure therapy experiences. Panic disorder taught me the power of virtual safe spaces. Healing through technology.',
    bio: 'VR Developer • Digital Artist • Anxiety Tech Specialist',
    avatarColor: '#3F51B5',
    membershipTier: 'premium'
  },
  {
    email: 'noah@test.com',
    password: 'test123456',
    username: 'Noah Brown',
    age: 33,
    location: 'Atlanta, GA',
    traits: ['Bipolar', 'Creative Mania'],
    interests: ['Stand-up Comedy', 'Mental Health Humor', 'Advocacy', 'Performance'],
    freeText: '🎭 Stand-up comedian turning mental health struggles into healing laughter. Bipolar gives me material, therapy gives me perspective.',
    bio: 'Comedian • Mental Health Advocate • Laughter Therapist',
    avatarColor: '#FFEB3B',
    membershipTier: 'free'
  },
  {
    email: 'olivia@test.com',
    password: 'test123456',
    username: 'Olivia Taylor',
    age: 28,
    location: 'Minneapolis, MN',
    traits: ['OCD', 'Health Anxiety'],
    interests: ['Mindful Cleaning', 'Organization', 'Ritual Design', 'Peace Finding'],
    freeText: '🧹 Professional organizer with OCD. What others see as compulsion, I see as sacred ritual. Finding peace in perfect order.',
    bio: 'Professional Organizer • Ritual Designer • Order Seeker',
    avatarColor: '#9E9E9E',
    membershipTier: 'premium'
  },
  {
    email: 'peter@test.com',
    password: 'test123456',
    username: 'Peter Zhang',
    age: 31,
    location: 'Washington, DC',
    traits: ['Social Anxiety', 'Selective Mutism'],
    interests: ['Sign Language', 'Non-Verbal Communication', 'Advocacy', 'Silence'],
    freeText: '👐 ASL interpreter and selective mutism advocate. Sometimes the most powerful communication happens without words. Silence speaks volumes.',
    bio: 'ASL Interpreter • Communication Advocate • Silence Speaker',
    avatarColor: '#00E676',
    membershipTier: 'pro'
  },
  {
    email: 'quinn@test.com',
    password: 'test123456',
    username: 'Quinn Rivers',
    age: 27,
    location: 'Salt Lake City, UT',
    traits: ['Gender Dysphoria', 'Depression'],
    interests: ['Gender Studies', 'Transition Support', 'Community Building', 'Authenticity'],
    freeText: '🏳️‍⚧️ Transition coach and gender studies researcher. Depression clouded my identity until I found my authentic self. Now I help others find theirs.',
    bio: 'Transition Coach • Gender Researcher • Authenticity Guide',
    avatarColor: '#E1BEE7',
    membershipTier: 'premium'
  },
  {
    email: 'ruby@test.com',
    password: 'test123456',
    username: 'Ruby Martinez',
    age: 30,
    location: 'Las Vegas, NV',
    traits: ['Gambling Addiction', 'Impulse Control'],
    interests: ['Financial Recovery', 'Impulse Management', 'Risk Assessment', 'Second Chances'],
    freeText: '🎯 Financial counselor in gambling recovery. Lost everything to addiction, gained wisdom from recovery. Teaching others to bet on themselves.',
    bio: 'Financial Counselor • Recovery Specialist • Second Chance Advocate',
    avatarColor: '#D32F2F',
    membershipTier: 'free'
  },
  {
    email: 'sam@test.com',
    password: 'test123456',
    username: 'Sam Cooper',
    age: 26,
    location: 'Portland, ME',
    traits: ['Seasonal Depression', 'Light Sensitivity'],
    interests: ['Light Therapy', 'Seasonal Wellness', 'Photography', 'Mood Tracking'],
    freeText: '💡 Light therapist and seasonal wellness coach. Seasonal depression taught me to chase light, literally and metaphorically. Finding sunshine in dark seasons.',
    bio: 'Light Therapist • Seasonal Wellness Coach • Sunshine Chaser',
    avatarColor: '#FFC107',
    membershipTier: 'premium'
  },
  {
    email: 'tara@test.com',
    password: 'test123456',
    username: 'Tara Johnson',
    age: 32,
    location: 'Albuquerque, NM',
    traits: ['Chronic Fatigue', 'Autoimmune'],
    interests: ['Energy Management', 'Chronic Illness Advocacy', 'Adaptive Living', 'Spoon Theory'],
    freeText: '⚡ Chronic illness advocate and energy management coach. Chronic fatigue taught me to treasure every spoon. Making the invisible visible.',
    bio: 'Chronic Illness Advocate • Energy Coach • Spoon Theorist',
    avatarColor: '#795548',
    membershipTier: 'pro'
  }
];

// 丰富的帖子内容数据库
const RICH_POSTS = [
  // Alice的帖子
  { author: 'Alice Chen', category: 'art-therapy', content: '📝 Today marks 30 days of consistent journaling. My therapist was right - writing down the anxious thoughts helps externalize them. What grounding techniques work best for you? #AnxietySupport #MentalHealthJourney' },
  { author: 'Alice Chen', category: 'creative', content: '🎨 Finished my first painting in months today. The colors felt chaotic but somehow that matched my headspace perfectly. Art therapy is becoming my lifeline. Anyone else use creative expression for healing?' },
  { author: 'Alice Chen', category: 'books', content: 'Book recommendation: "The Body Keeps the Score" changed how I understand my PTSD triggers. Anyone else find reading about trauma both helpful and overwhelming? 📚 #TraumaRecovery #BookClub' },

  // Bob的帖子
  { author: 'Bob Martinez', category: 'music', content: '🎵 Spent the weekend creating a 10-minute ambient track for meditation. ADHD brain + hyperfocus = unexpected productivity bursts! Sharing the link in comments. #ADHDCreativity #AmbientMusic' },
  { author: 'Bob Martinez', category: 'community', content: 'Coffee shop conversations today reminded me why community matters. Feeling grateful for spaces where we can just... exist without explanation. Where do you find your people? ☕' },
  { author: 'Bob Martinez', category: 'emotional-regulation', content: 'Question: Does anyone else use music as emotional regulation? I have different playlists for different moods/states. Depression playlist hits different than anxiety playlist. 🎧' },

  // Charlie的帖子
  { author: 'Charlie Kim', category: 'mindfulness', content: '🧘‍♀️ Leading a mindfulness session for fellow bipolar folks tomorrow. Nervous but excited to share what\'s helped me find stability. The teacher is always the student. #BipolarSupport #Mindfulness' },
  { author: 'Charlie Kim', category: 'bipolar', content: 'Manic episodes used to terrify me. Now I\'m learning to surf the waves instead of fighting them. Small victories count. Today\'s victory: recognizing the signs early. 🌊' },
  { author: 'Charlie Kim', category: 'wisdom', content: 'Reminder: Your healing journey doesn\'t need to look like anyone else\'s. Comparison is the thief of peace. What does YOUR healing look like? 💚 #HealingJourney #SelfCompassion' },

  // Diana的帖子
  { author: 'Diana Thompson', category: 'tech', content: '💻 Working on an app feature that adds audio descriptions for images. Small steps toward a more accessible digital world. Tech should include everyone, not just neurotypicals. #Accessibility #TechForGood' },
  { author: 'Diana Thompson', category: 'autism', content: 'Autism masking is exhausting. Today I chose authenticity over fitting in, and it felt revolutionary. Stimming in public = self-advocacy. #AutismAwareness #Neurodiversity' },
  { author: 'Diana Thompson', category: 'special-interests', content: 'Special interest rabbit hole of the week: Byzantine mosaics. The patterns are mathematically beautiful! Anyone else have special interests that bring them joy? Share yours! 🧩✨' },

  // Eve的帖子
  { author: 'Eve Rodriguez', category: 'trauma', content: '🌱 Three years into my healing journey from complex PTSD. Some days are harder than others, but progress isn\'t linear. Celebrating small wins today. #CPTSDRecovery #HealingIsNotLinear' },
  { author: 'Eve Rodriguez', category: 'therapy', content: 'Facilitating a DBT skills group tonight. There\'s something powerful about survivors helping other survivors. Peer support hits different. 💙 #DBT #PeerSupport #TraumaInformed' },
  { author: 'Eve Rodriguez', category: 'self-care', content: 'Self-care isn\'t selfish. It took me years to truly believe this. What does your self-care look like? Mine is saying no without guilt. 🛁 #SelfCare #Boundaries' },

  // Frank的帖子
  { author: 'Frank Johnson', category: 'photography', content: '📸 Macro photography session today. OCD makes me notice details others miss - turns out that\'s my superpower. Every dewdrop tells a story. #MacroPhotography #OCDSuperpower' },
  { author: 'Frank Johnson', category: 'nature', content: 'Forest bathing helped my depression more than any medication. There\'s something about trees that puts life in perspective. When did you last hug a tree? 🌲 #ForestBathing #NatureTherapy' },
  { author: 'Frank Johnson', category: 'mindful-living', content: 'Mindful photography: using my camera to stay present. Each shot is a meditation. Depression lies, but nature tells the truth. 📷✨ #MindfulPhotography #PresentMoment' },

  // 新用户的帖子
  { author: 'Grace Liu', category: 'dance', content: '💃 Dance class tonight! Social anxiety used to keep me from moving freely. Now I dance like nobody\'s watching... because healing happens in motion. #DanceTherapy #MovementHealing' },
  { author: 'Henry Davis', category: 'gaming', content: '🎲 Board game night was amazing! Autism helps me see game patterns others miss. Found my community through cardboard and dice. Who wants to play next? #BoardGames #AutismCommunity' },
  { author: 'Iris Patel', category: 'adaptive-sports', content: '🌊 Adaptive surfing lesson today! Chronic pain doesn\'t stop the stoke. Every wave reminds me that adaptation is possible. The ocean doesn\'t discriminate. #AdaptiveSports #ChronicPain' },
  { author: 'Jack Williams', category: 'recovery', content: '🔨 365 days sober today. PTSD led to addiction, recovery led to carpentry, carpentry led to peace. Building furniture, rebuilding life. One plank at a time. #Recovery #PTSD #Sobriety' },
  { author: 'Kate Anderson', category: 'body-positivity', content: '🎵 New song about body image recovery. My eating disorder tried to silence my voice. Recovery gave it back louder than ever. Music heals what medicine can\'t touch. #BodyPositivity #EDRecovery' },
  { author: 'Liam O\'Connor', category: 'entrepreneurship', content: '🚀 Failed startup #7 today. ADHD rejection sensitivity used to devastate me. Now? Failure is just expensive education. Tomorrow I start #8. #FailForward #ADHDEntrepreneur' },
  { author: 'Maya Sharma', category: 'vr-therapy', content: '🥽 VR exposure therapy session complete! Panic disorder can\'t follow me into virtual safe spaces. Technology + therapy = transformation. The future of healing is here. #VRTherapy #PanicDisorder' },
  { author: 'Noah Brown', category: 'comedy', content: '🎭 Stand-up set tonight: "Bipolar and the Terrible, Horrible, No Good, Very Bad (but sometimes Amazing) Day." Laughter really is medicine. Who else uses humor to heal? #MentalHealthComedy #Bipolar' },
  { author: 'Olivia Taylor', category: 'organization', content: '🧹 Organized 5 homes this week. OCD isn\'t a curse when it\'s your calling. Every perfectly arranged space brings someone peace. What looks like compulsion feels like art. #OCD #ProfessionalOrganizing' },
  { author: 'Peter Zhang', category: 'communication', content: '👐 Selective mutism awareness week! Sometimes the most powerful communication happens without words. ASL taught me that silence has its own language. #SelectiveMutism #ASL #NonVerbalCommunication' },
  { author: 'Quinn Rivers', category: 'gender', content: '🏳️‍⚧️ 2 years on HRT today! Gender dysphoria tried to erase me. Transition brought me back to life. Authenticity is the best antidepressant. #TransJoy #GenderDysphoria #Authenticity' },
  { author: 'Ruby Martinez', category: 'financial-recovery', content: '🎯 6 months gambling-free! Lost my house to addiction, gained my soul through recovery. Teaching financial literacy to other addicts. Bet on yourself, not the house. #GamblingRecovery #FinancialLiteracy' },
  { author: 'Sam Cooper', category: 'seasonal-wellness', content: '💡 Light therapy session complete! Seasonal depression can\'t dim my inner light anymore. 10,000 lux of hope every morning. Chasing sunshine, finding it within. #SeasonalDepression #LightTherapy' },
  { author: 'Tara Johnson', category: 'chronic-illness', content: '⚡ Chronic fatigue flare today. 3 spoons left, using them wisely. Invisible illness, visible strength. Rest isn\'t laziness, it\'s medical necessity. #ChronicFatigue #SpoonTheory #InvisibleIllness' }
];

// 匹配关系数据
const MATCH_RELATIONSHIPS = [
  { userA: 'Alice Chen', userB: 'Frank Johnson', compatibility: 0.87, reason: 'Both creative souls dealing with anxiety/OCD, shared interest in mindfulness and art' },
  { userA: 'Alice Chen', userB: 'Kate Anderson', compatibility: 0.82, reason: 'Creative expression through writing/music, recovery journeys' },
  { userA: 'Bob Martinez', userB: 'Charlie Kim', compatibility: 0.89, reason: 'Music/mindfulness intersection, ADHD/Bipolar understanding' },
  { userA: 'Bob Martinez', userB: 'Noah Brown', compatibility: 0.85, reason: 'Creative expression (music/comedy), mental health advocacy' },
  { userA: 'Charlie Kim', userB: 'Eve Rodriguez', compatibility: 0.91, reason: 'Both therapists/coaches, deep understanding of mental health' },
  { userA: 'Diana Thompson', userB: 'Maya Sharma', compatibility: 0.88, reason: 'Tech innovation for mental health, autism/anxiety connection' },
  { userA: 'Diana Thompson', userB: 'Henry Davis', compatibility: 0.84, reason: 'Autism connection, pattern recognition, inclusive communities' },
  { userA: 'Eve Rodriguez', userB: 'Jack Williams', compatibility: 0.86, reason: 'PTSD understanding, helping others heal' },
  { userA: 'Frank Johnson', userB: 'Olivia Taylor', compatibility: 0.83, reason: 'OCD shared experience, attention to detail, mindful living' },
  { userA: 'Grace Liu', userB: 'Peter Zhang', compatibility: 0.81, reason: 'Social anxiety understanding, non-verbal communication appreciation' },
  { userA: 'Henry Davis', userB: 'Sam Cooper', compatibility: 0.79, reason: 'Pattern-focused minds, community building' },
  { userA: 'Iris Patel', userB: 'Tara Johnson', compatibility: 0.92, reason: 'Chronic illness advocacy, adaptive living, resilience' },
  { userA: 'Jack Williams', userB: 'Ruby Martinez', compatibility: 0.88, reason: 'Addiction recovery, financial healing, second chances' },
  { userA: 'Kate Anderson', userB: 'Quinn Rivers', compatibility: 0.85, reason: 'Body image/identity recovery, authenticity journey' },
  { userA: 'Liam O\'Connor', userB: 'Maya Sharma', compatibility: 0.83, reason: 'ADHD innovation, tech solutions, resilience' },
  { userA: 'Noah Brown', userB: 'Sam Cooper', compatibility: 0.80, reason: 'Creative approach to mental health, mood awareness' },
  { userA: 'Olivia Taylor', userB: 'Tara Johnson', compatibility: 0.82, reason: 'Order/energy management, mindful living approaches' },
  { userA: 'Peter Zhang', userB: 'Quinn Rivers', compatibility: 0.84, reason: 'Communication advocacy, authenticity, marginalized community support' }
];

async function createRichVirtualEnvironment() {
  console.log('🌟 Creating rich virtual environment...');
  console.log('   Project ID: psycho-dating-app');
  console.log('   Users: 20 diverse profiles');
  console.log('   Posts: 30+ authentic posts');
  console.log('   Matches: 18 relationship pairs');
  
  try {
    // 1. 清除现有数据
    console.log('\n🧹 Clearing existing data...');
    const collections = ['users', 'posts', 'matches', 'conversations', 'comments'];
    for (const collection of collections) {
      const snapshot = await db.collection(collection).get();
      const batch = db.batch();
      snapshot.docs.forEach(doc => batch.delete(doc.ref));
      if (snapshot.docs.length > 0) {
        await batch.commit();
        console.log(`   ✓ Cleared ${snapshot.docs.length} documents from ${collection}`);
      }
    }

    // 2. 创建Firebase Auth用户
    console.log('\n👥 Creating Firebase Auth users...');
    const createdUserIds = new Map();
    
    for (const userData of COMPREHENSIVE_USERS) {
      try {
        const userRecord = await auth.createUser({
          email: userData.email,
          password: userData.password,
          displayName: userData.username,
          emailVerified: true,
        });
        createdUserIds.set(userData.username, userRecord.uid);
        console.log(`   ✓ Auth user: ${userData.username}`);
      } catch (error) {
        if (error.code === 'auth/email-already-exists') {
          // 获取现有用户的UID
          const userRecord = await auth.getUserByEmail(userData.email);
          createdUserIds.set(userData.username, userRecord.uid);
          console.log(`   ✓ Auth user exists: ${userData.username}`);
        } else {
          console.log(`   ⚠️  Error creating auth user ${userData.email}: ${error.message}`);
        }
      }
    }

    // 3. 创建Firestore用户档案
    console.log('\n📝 Creating user profiles...');
    for (const userData of COMPREHENSIVE_USERS) {
      const userId = createdUserIds.get(userData.username);
      if (userId) {
        await db.collection('users').doc(userId).set({
          uid: userId,
          username: userData.username,
          email: userData.email,
          age: userData.age,
          location: userData.location,
          traits: userData.traits,
          interests: userData.interests,
          freeText: userData.freeText,
          bio: userData.bio,
          avatarColor: userData.avatarColor,
          membershipTier: userData.membershipTier,
          followedBloggerIds: [],
          favoritedPostIds: [],
          favoritedConversationIds: [],
          likedPostIds: [],
          followersCount: Math.floor(Math.random() * 50) + 10,
          followingCount: Math.floor(Math.random() * 30) + 15,
          postsCount: 0,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          lastActive: admin.firestore.FieldValue.serverTimestamp(),
          isSuspended: false,
          reportCount: 0,
        });
        console.log(`   ✓ Profile: ${userData.username}`);
      }
    }

    // 4. 创建丰富的帖子内容
    console.log('\n📱 Creating social posts...');
    const postIds = [];
    for (const post of RICH_POSTS) {
      const authorData = COMPREHENSIVE_USERS.find(u => u.username === post.author);
      const authorId = createdUserIds.get(post.author);
      
      if (authorId && authorData) {
        const postRef = db.collection('posts').doc();
        await postRef.set({
          id: postRef.id,
          authorId: authorId,
          authorUsername: post.author,
          content: post.content,
          category: post.category,
          likes: Math.floor(Math.random() * 20) + 5,
          comments: Math.floor(Math.random() * 10) + 2,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });
        postIds.push(postRef.id);
        console.log(`   ✓ Post by ${post.author}: ${post.category}`);
      }
    }

    // 5. 创建用户互动数据（点赞、收藏）
    console.log('\n💫 Creating user interactions...');
    for (const userData of COMPREHENSIVE_USERS) {
      const userId = createdUserIds.get(userData.username);
      if (userId) {
        // 随机选择一些帖子进行点赞
        const likedPosts = postIds.sort(() => 0.5 - Math.random()).slice(0, Math.floor(Math.random() * 8) + 3);
        // 随机选择一些帖子进行收藏
        const favoritedPosts = postIds.sort(() => 0.5 - Math.random()).slice(0, Math.floor(Math.random() * 5) + 2);
        
        await db.collection('users').doc(userId).update({
          likedPostIds: likedPosts,
          favoritedPostIds: favoritedPosts,
          postsCount: RICH_POSTS.filter(p => p.author === userData.username).length
        });
        console.log(`   ✓ Interactions for ${userData.username}: ${likedPosts.length} likes, ${favoritedPosts.length} favorites`);
      }
    }

    // 6. 创建匹配关系
    console.log('\n💕 Creating match relationships...');
    for (const match of MATCH_RELATIONSHIPS) {
      const userAId = createdUserIds.get(match.userA);
      const userBId = createdUserIds.get(match.userB);
      
      if (userAId && userBId) {
        const matchRef = db.collection('matches').doc();
        await matchRef.set({
          id: matchRef.id,
          userAId: userAId,
          userBId: userBId,
          userAName: match.userA,
          userBName: match.userB,
          compatibility: match.compatibility,
          reason: match.reason,
          status: 'potential', // potential, liked, matched, passed
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          algorithms: ['personality', 'interests', 'location', 'mental-health-compatibility']
        });
        console.log(`   ✓ Match: ${match.userA} ↔ ${match.userB} (${Math.round(match.compatibility * 100)}%)`);
      }
    }

    // 7. 创建一些对话记录
    console.log('\n💬 Creating sample conversations...');
    const sampleConversations = MATCH_RELATIONSHIPS.slice(0, 8); // 创建8个对话
    for (const conv of sampleConversations) {
      const userAId = createdUserIds.get(conv.userA);
      const userBId = createdUserIds.get(conv.userB);
      
      if (userAId && userBId) {
        const conversationRef = db.collection('conversations').doc();
        await conversationRef.set({
          id: conversationRef.id,
          participants: [userAId, userBId],
          participantNames: [conv.userA, conv.userB],
          lastMessage: 'Hi! I saw we matched and wanted to say hello 😊',
          lastMessageTime: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          isActive: true
        });
        console.log(`   ✓ Conversation: ${conv.userA} ↔ ${conv.userB}`);
      }
    }

    console.log('\n✨ Rich virtual environment created successfully!');
    console.log('\n📊 Summary:');
    console.log(`   👥 Users: ${COMPREHENSIVE_USERS.length} diverse profiles`);
    console.log(`   📱 Posts: ${RICH_POSTS.length} authentic social content`);
    console.log(`   💕 Matches: ${MATCH_RELATIONSHIPS.length} relationship pairs`);
    console.log(`   💬 Conversations: ${Math.min(8, MATCH_RELATIONSHIPS.length)} active chats`);
    console.log('\n🔐 Login with any of these accounts:');
    COMPREHENSIVE_USERS.slice(0, 6).forEach(user => {
      console.log(`   ${user.email} / test123456 (${user.bio})`);
    });
    console.log(`   ... and ${COMPREHENSIVE_USERS.length - 6} more!`);

  } catch (error) {
    console.error('❌ Error creating rich virtual environment:', error);
  }
}

createRichVirtualEnvironment()
  .then(() => {
    console.log('\n🎉 Virtual environment is ready!');
    console.log('🚀 Launch your app and enjoy the rich, realistic experience!');
    process.exit(0);
  })
  .catch((error) => {
    console.error('❌ Fatal error:', error);
    process.exit(1);
  });
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

// 更多虚拟用户数据
const COMPREHENSIVE_USERS = [
  {
    email: 'alice@test.com',
    username: 'Alice Chen',
    bio: '艺术治疗师 • 心理健康倡导者 • 绘画与冥想爱好者',
    traits: ['Anxiety', 'Depression'],
    freeText: '我相信创造力和正念的治愈力量。寻找能够深入探讨生活、艺术和个人成长的人。'
  },
  {
    email: 'bob@test.com',
    username: 'Bob Martinez',
    bio: '音乐制作人 • 声音设计师 • 社区建设者',
    traits: ['Depression', 'ADHD'],
    freeText: '音乐是我的治疗和激情。我喜欢创造能让人感到被理解的节拍。'
  },
  {
    email: 'charlie@test.com', 
    username: 'Charlie Kim',
    bio: '正念教练 • 瑜伽导师 • 心理健康演讲者',
    traits: ['Bipolar', 'Anxiety'],
    freeText: '在混乱中寻找平静。我理解心理健康之旅，相信互相支持。'
  },
  {
    email: 'diana@test.com',
    username: 'Diana Thompson', 
    bio: '软件工程师 • 无障碍倡导者 • 科技向善',
    traits: ['ADHD', 'Autism'],
    freeText: '构建让世界更包容的技术。喜欢编程、桌游和神经多样性的坦诚对话。'
  },
  {
    email: 'emma@test.com',
    username: 'Emma Rodriguez',
    bio: '创意写手 • 心理健康博主 • 猫妈妈',
    traits: ['Depression', 'Anxiety'],
    freeText: '用文字处理世界。写心理健康话题来打破偏见。寻找重视情商的人。'
  },
  {
    email: 'felix@test.com',
    username: 'Felix Wong',
    bio: '治疗师 • 攀岩者 • 正念生活爱好者',
    traits: ['PTSD'],
    freeText: '帮助他人康复的同时也在自己的康复路上。同样热爱户外冒险和静谧时光。'
  },
  {
    email: 'grace@test.com',
    username: 'Grace Johnson',
    bio: '社会工作者 • 社区组织者 • 植物家长',
    traits: ['Anxiety', 'OCD'],
    freeText: '对社会正义和心理健康意识充满热情。喜欢照料植物和创建康复的安全空间。'
  },
  {
    email: 'henry@test.com',
    username: 'Henry Park',
    bio: '平面设计师 • 数字艺术家 • 心理健康倡导者',
    traits: ['Bipolar', 'ADHD'],
    freeText: '创造有意义的视觉故事。艺术帮我表达言语无法表达的。寻找欣赏创造力和真实性的人。'
  },
  {
    email: 'iris@test.com',
    username: 'Iris Anderson',
    bio: '护士 • 健康教练 • 徒步爱好者',
    traits: ['Depression'],
    freeText: '在照顾他人的同时学会照顾自己。大自然是我的庇护所。寻找重视同理心和成长的人。'
  },
  {
    email: 'jack@test.com',
    username: 'Jack Cooper',
    bio: '厨师 • 正念饮食倡导者 • 社区厨房志愿者',
    traits: ['Anxiety', 'ADHD'],
    freeText: '食物就是爱，烹饪就是冥想。通过共享餐食建立社区。寻找欣赏简单快乐的人。'
  },
  {
    email: 'kelly@test.com',
    username: 'Kelly Davis',
    bio: '摄影师 • 心理健康故事讲述者 • 爱狗人士',
    traits: ['PTSD', 'Depression'],
    freeText: '捕捉日常生活中的美好瞬间。用摄影讲述韧性和希望的故事。'
  },
  {
    email: 'luna@test.com',
    username: 'Luna Garcia',
    bio: '冥想导师 • 健康博主 • 可持续生活倡导者',
    traits: ['Anxiety'],
    freeText: '教授正念和有意识的生活。相信存在和真实连接的力量。'
  },
  {
    email: 'max@test.com',
    username: 'Max Taylor',
    bio: '视频游戏开发者 • 无障碍设计师 • 心理健康游戏玩家',
    traits: ['Autism', 'Anxiety'],
    freeText: '创造包容的游戏体验。喜欢深入研究游戏机制和神经多样性的有意义对话。'
  },
  {
    email: 'nina@test.com',
    username: 'Nina Patel',
    bio: '舞蹈治疗师 • 表演艺术家 • 身体积极倡导者',
    traits: ['Depression', 'ADHD'],
    freeText: '运动就是良药。帮助他人通过舞蹈找到快乐和康复。寻找庆祝真实性的人。'
  },
  {
    email: 'oscar@test.com',
    username: 'Oscar Lee',
    bio: '图书馆员 • 读书会主持人 • 安静行动主义者',
    traits: ['Anxiety', 'Autism'],
    freeText: '书籍是我的世界和庇护所。为安静的连接和关于生活与文学的有意义讨论创造空间。'
  },
  // 新增用户
  {
    email: 'sophia@test.com',
    username: 'Sophia Kim',
    bio: '心理学研究生 • 同伴支持专家 • 播客主持人',
    traits: ['Depression', 'Anxiety'],
    freeText: '通过学术研究和个人经验理解心理健康。主持关于心理健康的播客，分享真实故事。'
  },
  {
    email: 'ryan@test.com',
    username: 'Ryan O\'Brien',
    bio: '音乐治疗师 • 吉他老师 • 开放麦之夜组织者',
    traits: ['Bipolar', 'ADHD'],
    freeText: '音乐是通用语言。使用音响治疗帮助他人处理情感。寻找分享音乐激情的人。'
  },
  {
    email: 'maya@test.com',
    username: 'Maya Singh',
    bio: '瑜伽导师 • 阿育吠陀从业者 • 正念育儿倡导者',
    traits: ['Anxiety', 'PTSD'],
    freeText: '古老的智慧遇见现代治疗。通过瑜伽和正念帮助家庭康复。'
  },
  {
    email: 'ethan@test.com',
    username: 'Ethan Chen',
    bio: '环境科学家 • 生态治疗倡导者 • 野生动物摄影师',
    traits: ['Depression', 'Autism'],
    freeText: '在大自然中找到治愈。研究环境对心理健康的影响。相信地球连接的力量。'
  },
  {
    email: 'zoe@test.com',
    username: 'Zoe Martinez',
    bio: '时尚设计师 • 身体积极倡导者 • 心理健康意识活动家',
    traits: ['Depression', 'ADHD'],
    freeText: '通过时尚表达自我。设计包容各种身形的服装。相信时尚作为自我表达和治疗的力量。'
  }
];

// 丰富的帖子内容
const RICH_POSTS = [
  {
    title: "今天的艺术治疗突破",
    content: "刚刚在艺术治疗课上完成了我的第一幅画。令人惊讶的是，颜色能够表达言语无法表达的东西。蓝色代表我的忧郁，但黄色...黄色代表希望。有人也在用创造性方式处理情绪吗？",
    mood: "hopeful",
    tags: ["arttherapy", "creativity", "healing", "selfexpression"],
    imageUrl: "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "正念星期一：小步骤，大影响",
    content: "开始这一周用10分钟冥想。有人发现小的日常习惯能带来平静吗？即使只是深呼吸也能改变我的一天。\n\n今天的咒语：'我足够，我值得平静。'\n\n分享你们的正念时刻吧！✨",
    mood: "peaceful",
    tags: ["mindfulness", "meditation", "routine", "selfcare"],
    imageUrl: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "攀岩教会我关于韧性的知识",
    content: "今天在攀岩墙上，我意识到每个握点都像生活中的一个挑战。有时你觉得会掉下去，但你找到力量坚持住。\n\n心理健康康复也是这样 - 一次一个握点，一天一天。\n\n有人发现身体活动能帮助你的心理健康吗？",
    mood: "strong",
    tags: ["resilience", "exercise", "mentalstrength", "recovery"],
    imageUrl: "https://images.unsplash.com/photo-1522163182402-834f871fd851?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "音乐作为情感的语言",
    content: "刚刚制作了一个反映我今天感受的节拍。奇怪的是，旋律能捕捉到我无法用言语表达的东西。\n\n音乐不判断，它只是...理解。对于任何在挣扎的人，也许试试音乐？即使只是听一首歌也能帮助。\n\n🎵 今天的治疗播放列表在评论中",
    mood: "expressive",
    tags: ["music", "therapy", "emotions", "creativity"],
    imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "编程和焦虑：意外的盟友",
    content: "作为一个患有ADHD和焦虑的程序员，我发现编码实际上很平静。专注于解决问题让我的大脑安静下来。\n\n今天构建了一个心理健康追踪应用。技术可以是治疗性的！\n\n有其他神经分歧的技术人员吗？我们来连接吧！",
    mood: "focused",
    tags: ["tech", "adhd", "anxiety", "coding"],
    imageUrl: "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "烹饪作为自我关爱",
    content: "为自己做了一顿营养丰富的饭菜。切蔬菜时的重复动作几乎像冥想一样。\n\n食物就是爱，即使是为自己做的。还有谁发现烹饪是治疗性的？\n\n分享你们的舒适食谱！🍲",
    mood: "nurturing",
    tags: ["selfcare", "cooking", "mindfulness", "nourishment"],
    imageUrl: "https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "瑜伽垫上的脆弱时刻",
    content: "今天的瑜伽课上，在鸽子式中情绪释放了。我们的身体储存了这么多...允许自己感受一切是OK的。\n\n运动不总是关于力量，有时是关于释放。\n\n发送拥抱给所有今天需要的人 🤗",
    mood: "vulnerable",
    tags: ["yoga", "emotions", "bodywork", "release"],
    imageUrl: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "阅读作为逃避和理解",
    content: "刚读完一本关于神经多样性的书。看到自己反映在页面上如此验证。\n\n书籍是门户 - 通向理解，通向感觉不那么孤独。\n\n有推荐关于心理健康或神经多样性的好书吗？",
    mood: "contemplative",
    tags: ["reading", "neurodiversity", "understanding", "books"],
    imageUrl: "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "社区花园的治疗力量",
    content: "在当地社区花园度过了早晨。手在土壤中工作时，有些东西让我接地气。\n\n看着东西成长提醒我康复需要时间和耐心。也许我们都需要更多绿色空间。\n\n🌱 有人愿意开始园艺小组吗？",
    mood: "grounded",
    tags: ["gardening", "community", "nature", "growth"],
    imageUrl: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "游戏世界中的无障碍",
    content: "作为一个自闭症游戏开发者，我正在开发具有感官友好选项的游戏。代表性很重要！\n\n游戏可以是治疗性的，但只有当它们对每个人都可访问时。让我们为所有大脑创建空间。\n\n🎮 有游戏玩家想测试我的新项目吗？",
    mood: "innovative",
    tags: ["gaming", "accessibility", "autism", "inclusion"],
    imageUrl: "https://images.unsplash.com/photo-1511512578047-dfb367046420?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "舞蹈：我身体的诗歌",
    content: "今晚的舞蹈课让我想起了为什么运动是我的治疗。我的身体讲述我的心无法表达的故事。\n\n每个动作都是一个词，每个舞蹈都是一首诗。对所有寻找表达方式的人 - 也许试试运动？\n\n💃 身体积极万岁！",
    mood: "expressive",
    tags: ["dance", "movement", "therapy", "bodypositive"],
    imageUrl: "https://images.unsplash.com/photo-1547153760-18fc86324498?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "摄影：捕捉希望的瞬间",
    content: "今天拍摄了日出。即使在最黑暗的时刻，光总会回来。\n\n摄影教会我注意小美好 - 反射在水坑中，狗狗的笑脸，陌生人的善举。\n\n📸 分享一张今天让你微笑的照片！",
    mood: "hopeful",
    tags: ["photography", "hope", "beauty", "mindfulness"],
    imageUrl: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=300&fit=crop&crop=center"
  },
  {
    title: "播客对话：打破沉默",
    content: "刚刚录制了关于双相情感障碍现实的播客一集。分享我们的故事很可怕，但这就是我们消除污名的方式。\n\n每个声音都很重要。每个故事都有力量治愈。\n\n🎙️ 谁想成为下一位客人？",
    mood: "courageous",
    tags: ["podcast", "bipolar", "storytelling", "mentalhealth"],
    imageUrl: "https://images.unsplash.com/photo-1478737270239-2f02b77fc618?w=400&h=300&fit=crop&crop=center"
  }
];

async function createComprehensiveData() {
  console.log('🚀 创建完整的虚拟数据环境...\n');
  
  let userCount = 0;
  let postCount = 0;
  
  // 1. 创建/更新用户数据
  console.log('👥 创建用户数据...');
  for (const userData of COMPREHENSIVE_USERS) {
    try {
      // 创建或更新认证用户
      let authUser;
      try {
        authUser = await auth.getUserByEmail(userData.email);
        console.log(`ℹ️  更新现有用户: ${userData.username}`);
      } catch (error) {
        authUser = await auth.createUser({
          email: userData.email,
          password: 'test123456',
          displayName: userData.username,
          emailVerified: true,
        });
        console.log(`✅ 创建新用户: ${userData.username}`);
      }
      
      // 创建用户资料
      const userProfile = {
        uid: authUser.uid,
        username: userData.username,
        email: userData.email,
        bio: userData.bio,
        traits: userData.traits,
        freeText: userData.freeText,
        avatarUrl: `https://ui-avatars.com/api/?name=${encodeURIComponent(userData.username)}&size=200&background=random&color=fff`,
        lastActive: admin.firestore.FieldValue.serverTimestamp(),
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        isSuspended: false,
        reportCount: 0,
        followersCount: Math.floor(Math.random() * 100),
        followingCount: Math.floor(Math.random() * 50),
        postsCount: Math.floor(Math.random() * 25),
        followedBloggerIds: [],
        favoritedPostIds: [],
        favoritedConversationIds: [],
        likedPostIds: [],
        privacy: {
          visibility: 'public',
        },
        verificationStatus: 'verified',
        membershipTier: Math.random() > 0.7 ? 'premium' : 'basic',
        profileCompleteness: 100,
        interests: userData.traits.map(trait => trait.toLowerCase()),
      };
      
      await db.collection('users').doc(authUser.uid).set(userProfile, { merge: true });
      userCount++;
      
    } catch (error) {
      console.log(`❌ 创建用户 ${userData.email} 时出错: ${error.message}`);
    }
  }
  
  // 2. 创建丰富的帖子内容
  console.log('\n📝 创建帖子数据...');
  
  // 获取所有用户ID用于分配帖子
  const allUsers = await auth.listUsers();
  const userIds = allUsers.users.map(u => u.uid);
  
  // 清除旧帖子
  const existingPosts = await db.collection('posts').get();
  const batch = db.batch();
  existingPosts.docs.forEach(doc => {
    batch.delete(doc.ref);
  });
  await batch.commit();
  
  // 创建新帖子
  for (let i = 0; i < RICH_POSTS.length; i++) {
    const post = RICH_POSTS[i];
    const randomAuthor = userIds[Math.floor(Math.random() * userIds.length)];
    
    const postData = {
      title: post.title,
      content: post.content,
      authorId: randomAuthor,
      mood: post.mood,
      tags: post.tags,
      imageUrl: post.imageUrl,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      likesCount: Math.floor(Math.random() * 50),
      commentsCount: Math.floor(Math.random() * 20),
      sharesCount: Math.floor(Math.random() * 15),
      isPublic: true,
      isPinned: Math.random() > 0.9,
      viewsCount: Math.floor(Math.random() * 200),
    };
    
    await db.collection('posts').add(postData);
    postCount++;
    console.log(`📝 创建帖子: ${post.title.substring(0, 30)}...`);
  }
  
  // 3. 生成新的匹配数据（清除旧数据）
  console.log('\n💕 重新生成匹配数据...');
  const matchesSnapshot = await db.collectionGroup('candidates').get();
  const matchBatch = db.batch();
  matchesSnapshot.docs.forEach(doc => {
    matchBatch.delete(doc.ref);
  });
  await matchBatch.commit();
  
  console.log('\n🎉 虚拟数据环境创建完成！');
  console.log(`👥 用户总数: ${userCount}`);
  console.log(`📝 帖子总数: ${postCount}`);
  console.log('\n🔐 所有账号密码: test123456');
  console.log('\n💡 特色用户:');
  COMPREHENSIVE_USERS.slice(0, 8).forEach(user => {
    console.log(`   ${user.email} - ${user.username}`);
  });
  
  process.exit(0);
}

createComprehensiveData();
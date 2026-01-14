#!/usr/bin/env node

const admin = require('firebase-admin');

// Connect to current emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'psycho-dating-app',
});

const db = admin.firestore();

async function createCommunityPosts() {
  console.log('🏘️ 创建社区帖子数据...\n');

  // 获取所有用户
  const usersSnapshot = await db.collection('users').get();
  const allUsers = usersSnapshot.docs.map(doc => ({
    uid: doc.id,
    ...doc.data()
  }));

  console.log(`👥 找到 ${allUsers.length} 个用户`);

  const communityPosts = [
    {
      title: "今天的心情日记 ✨",
      content: "今天是个好日子！早上做了冥想，感觉内心特别平静。分享一些让我开心的小事：看到了一只可爱的小狗、喝到了完美的拿铁、朋友发来的温暖消息。有时候幸福就是这些微小的瞬间组成的 💕",
      imageUrl: "https://images.unsplash.com/photo-1544027993-37dbfe43562a?w=800&h=600&fit=crop",
      tags: ["心情日记", "正能量", "感恩", "mindfulness"],
      likes: Math.floor(Math.random() * 50) + 10,
      comments: Math.floor(Math.random() * 20) + 5,
      category: "生活感悟"
    },
    {
      title: "分享我的焦虑管理技巧 🧠",
      content: "作为一个长期与焦虑相伴的人，想分享一些我觉得有用的方法：\n1. 5-4-3-2-1接地技巧\n2. 每天写感恩日记\n3. 深呼吸练习\n4. 适量运动\n5. 寻求专业帮助\n\n记住，寻求帮助是勇敢的表现，不是软弱 💪",
      imageUrl: "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=800&h=600&fit=crop",
      tags: ["焦虑管理", "心理健康", "自我关怀", "技巧分享"],
      likes: Math.floor(Math.random() * 80) + 30,
      comments: Math.floor(Math.random() * 25) + 8,
      category: "心理健康"
    },
    {
      title: "周末艺术治疗体验 🎨",
      content: "参加了一场艺术治疗工作坊，通过绘画表达内心的情感。没想到画笔能够这么神奇地释放压抑的情绪。推荐大家尝试用创作来疗愈自己，不需要技巧，只需要真诚 ✨",
      imageUrl: "https://images.unsplash.com/photo-1541961017774-22349e4a1262?w=800&h=600&fit=crop",
      tags: ["艺术治疗", "创作", "情感表达", "疗愈"],
      likes: Math.floor(Math.random() * 60) + 20,
      comments: Math.floor(Math.random() * 15) + 4,
      category: "治疗体验"
    },
    {
      title: "森林浴的奇妙体验 🌲",
      content: "今天去了附近的森林公园，尝试了日本的\"森林浴\"。静静地坐在大树下，听鸟鸣风声，感受自然的能量。20分钟后，心情明显平静了很多。大自然真的是最好的治疗师 🍃",
      imageUrl: "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800&h=600&fit=crop",
      tags: ["森林浴", "自然疗法", "mindfulness", "放松"],
      likes: Math.floor(Math.random() * 45) + 15,
      comments: Math.floor(Math.random() * 12) + 3,
      category: "自然疗愈"
    },
    {
      title: "我的冥想之旅 🧘‍♀️",
      content: "开始冥想练习已经3个月了，从最初的5分钟都坐不住，到现在可以专注20分钟。分享几个初学者友好的app：Headspace、Calm、Ten Percent Happier。冥想不是清空思维，而是观察思维 💭",
      imageUrl: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop",
      tags: ["冥想", "mindfulness", "内观", "精神成长"],
      likes: Math.floor(Math.random() * 70) + 25,
      comments: Math.floor(Math.random() * 18) + 6,
      category: "精神实践"
    },
    {
      title: "读书分享：《我们内心的冲突》📚",
      content: "刚读完卡伦·霍妮的这本经典。她对内心冲突的分析太精准了！特别是关于\"理想化自我\"的部分，让我重新认识了完美主义的根源。推荐给正在自我探索路上的朋友们 ✨",
      imageUrl: "https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=800&h=600&fit=crop",
      tags: ["心理学", "读书笔记", "自我认知", "成长"],
      likes: Math.floor(Math.random() * 55) + 18,
      comments: Math.floor(Math.random() * 16) + 5,
      category: "读书分享"
    },
    {
      title: "今天的瑜伽练习 🧘‍♂️",
      content: "尝试了新的阴瑜伽序列，每个体式保持3-5分钟。在鸽子式的时候，突然涌上很多情绪，眼泪不自觉地流下来。瑜伽老师说这很正常，身体会记住情绪。感恩这个释放的过程 🙏",
      imageUrl: "https://images.unsplash.com/photo-1544367567-0f2fcb009e0b?w=800&h=600&fit=crop",
      tags: ["瑜伽", "身心连接", "情绪释放", "阴瑜伽"],
      likes: Math.floor(Math.random() * 40) + 12,
      comments: Math.floor(Math.random() * 10) + 2,
      category: "身心练习"
    },
    {
      title: "咖啡馆里的小确幸 ☕",
      content: "找到了一家超棒的独立咖啡馆，老板是个温暖的大叔，会记住每个常客的喜好。今天点了拿铁，他特意做了叶子拉花。有时候，陌生人的善意就像冬日暖阳，温暖整个心房 ☀️",
      imageUrl: "https://images.unsplash.com/photo-1511920170033-f8396924c348?w=800&h=600&fit=crop",
      tags: ["咖啡", "温暖", "人情味", "小确幸"],
      likes: Math.floor(Math.random() * 35) + 10,
      comments: Math.floor(Math.random() * 8) + 2,
      category: "生活点滴"
    },
    {
      title: "夜晚的情绪调节 🌙",
      content: "深夜时分，焦虑和孤独感总是会放大。分享我的夜晚情绪调节ritual：泡一壶薄荷茶、写下三件感恩的事、听舒缓音乐、做简单拉伸。慢慢地，心情就会平静下来 🌿",
      imageUrl: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop",
      tags: ["夜晚", "情绪调节", "自我关怀", "ritual"],
      likes: Math.floor(Math.random() * 50) + 15,
      comments: Math.floor(Math.random() * 14) + 4,
      category: "情绪管理"
    },
    {
      title: "手工制作的疗愈力量 ✂️",
      content: "最近迷上了手工制作，从简单的折纸到复杂的编织。专注于手工的过程中，大脑会进入一种类似冥想的状态，焦虑和杂念都消失了。完成作品的那一刻，满满的成就感 💫",
      imageUrl: "https://images.unsplash.com/photo-1452860606245-08befc0ff44b?w=800&h=600&fit=crop",
      tags: ["手工", "专注", "疗愈", "创作"],
      likes: Math.floor(Math.random() * 42) + 13,
      comments: Math.floor(Math.random() * 11) + 3,
      category: "创作疗愈"
    },
    {
      title: "音乐疗愈的神奇时刻 🎵",
      content: "今天听到一首老歌，瞬间被拉回到某个美好的回忆里。音乐真的有种魔力，能够瞬间改变我们的情绪状态。分享我的疗愈歌单：Ludovico Einaudi的钢琴曲、Max Richter的古典音乐... 🎹",
      imageUrl: "https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=800&h=600&fit=crop",
      tags: ["音乐", "回忆", "情绪", "疗愈"],
      likes: Math.floor(Math.random() * 48) + 16,
      comments: Math.floor(Math.random() * 13) + 4,
      category: "音乐疗愈"
    },
    {
      title: "与内在小孩的对话 👶",
      content: "在心理咨询中学到了与内在小孩对话的技巧。当感到害怕或愤怒时，试着问问自己：\"小时候的你在害怕什么？需要什么？\" 然后用成人的智慧去安慰那个受伤的小孩。这个练习很有力量 💝",
      imageUrl: "https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=800&h=600&fit=crop",
      tags: ["内在小孩", "心理咨询", "自我疗愈", "内观"],
      likes: Math.floor(Math.random() * 65) + 22,
      comments: Math.floor(Math.random() * 19) + 6,
      category: "心理成长"
    },
    {
      title: "园艺治疗初体验 🌱",
      content: "开始在阳台种植物了！从播种到发芽，看着生命慢慢展现，内心也跟着充满希望。照料植物的过程中，学会了耐心和接纳。每天早上给它们浇水已经成为我最喜欢的仪式感 🌻",
      imageUrl: "https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800&h=600&fit=crop",
      tags: ["园艺", "植物", "耐心", "希望"],
      likes: Math.floor(Math.random() * 38) + 11,
      comments: Math.floor(Math.random() * 9) + 2,
      category: "生活疗愈"
    },
    {
      title: "写作作为情绪出口 ✍️",
      content: "发现写作是很好的情绪出口，不需要华丽的辞藻，只要诚实地记录内心的声音。有时候把焦虑写下来，它就不再那么可怕了。推荐大家尝试晨间日记，释放负面情绪，迎接新的一天 📝",
      imageUrl: "https://images.unsplash.com/photo-1471107340929-a87cd0f5b5f3?w=800&h=600&fit=crop",
      tags: ["写作", "情绪出口", "日记", "自我表达"],
      likes: Math.floor(Math.random() * 44) + 14,
      comments: Math.floor(Math.random() * 12) + 3,
      category: "表达疗愈"
    },
    {
      title: "社群的温暖力量 🤗",
      content: "参加了一个线下的心理健康支持小组，第一次发现自己并不孤单。听到其他人分享相似的经历，内心的羞耻感瞬间消散了。我们互相支持，互相鼓励。感恩遇到这群温暖的伙伴 💖",
      imageUrl: "https://images.unsplash.com/photo-1529156069898-49953e39b3ac?w=800&h=600&fit=crop",
      tags: ["社群", "支持", "连接", "温暖"],
      likes: Math.floor(Math.random() * 72) + 28,
      comments: Math.floor(Math.random() * 21) + 7,
      category: "社群支持"
    },
    {
      title: "美食疗愈的小秘密 🍲",
      content: "今天尝试了正念饮食，慢慢地品味每一口食物的味道、质地、温度。发现当我们专注于当下的感官体验时，内心会变得特别平静。一碗简单的粥，也能成为疗愈的良药 🥣",
      imageUrl: "https://images.unsplash.com/photo-1490645935967-10de6ba17061?w=800&h=600&fit=crop",
      tags: ["正念饮食", "美食", "当下", "感官体验"],
      likes: Math.floor(Math.random() * 36) + 9,
      comments: Math.floor(Math.random() * 8) + 2,
      category: "正念生活"
    },
    {
      title: "宠物陪伴的治愈魔法 🐱",
      content: "我家的橘猫总是能感知我的情绪，每当我难过时，它就会静静地靠在我身边。科学研究表明，抚摸动物可以释放催产素，降低压力荷尔蒙。感恩有这个毛茸茸的治疗师陪伴 🧡",
      imageUrl: "https://images.unsplash.com/photo-1514888286974-6c03e2ca1dba?w=800&h=600&fit=crop",
      tags: ["宠物", "陪伴", "治愈", "橘猫"],
      likes: Math.floor(Math.random() * 58) + 19,
      comments: Math.floor(Math.random() * 16) + 5,
      category: "动物疗愈"
    },
    {
      title: "海边冥想的奇妙体验 🌊",
      content: "今天去海边做了一次冥想，海浪的声音就像天然的白噪音，帮助我进入更深层的放松状态。面对无边的大海，突然意识到自己的渺小，同时也感受到与宇宙的连接。内心前所未有的宁静 🌅",
      imageUrl: "https://images.unsplash.com/photo-1439066615861-d1af74d74000?w=800&h=600&fit=crop",
      tags: ["海边", "冥想", "大自然", "宁静"],
      likes: Math.floor(Math.random() * 52) + 17,
      comments: Math.floor(Math.random() * 15) + 4,
      category: "自然冥想"
    },
    {
      title: "感恩练习改变了我 🙏",
      content: "坚持每天写3件感恩的事，已经100天了。从最初的勉强凑数，到现在真心感受到生活中的美好。这个简单的练习悄悄地改变了我的心态，让我更容易注意到积极的事物 ✨",
      imageUrl: "https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=800&h=600&fit=crop",
      tags: ["感恩", "练习", "心态", "积极"],
      likes: Math.floor(Math.random() * 67) + 23,
      comments: Math.floor(Math.random() * 18) + 6,
      category: "正念练习"
    },
    {
      title: "DIY香薰的放松时光 🕯️",
      content: "学会了自己调配精油香薰，薰衣草+佛手柑的组合特别适合睡前使用。在香薰的陪伴下，整个房间都充满了宁静的氛围。这种仪式感让我更容易从白天的忙碌中抽离出来 🌙",
      imageUrl: "https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=800&h=600&fit=crop",
      tags: ["香薰", "精油", "放松", "仪式感"],
      likes: Math.floor(Math.random() * 41) + 12,
      comments: Math.floor(Math.random() * 10) + 3,
      category: "生活美学"
    }
  ];

  let totalPosts = 0;

  // 为每个帖子随机分配作者并保存
  const batch = db.batch();
  
  communityPosts.forEach((post, index) => {
    // 随机选择一个用户作为作者
    const randomUser = allUsers[Math.floor(Math.random() * allUsers.length)];
    
    const postId = `community_post_${Date.now()}_${index}`;
    const postRef = db.collection('posts').doc(postId);
    
    const fullPost = {
      postId: postId,
      userId: randomUser.uid,
      author: randomUser.username,
      authorImageUrl: randomUser.avatarUrl || "",
      text: post.content,
      content: post.content,
      title: post.title,
      imageUrl: post.imageUrl,
      media: post.imageUrl ? [post.imageUrl] : [],
      mediaType: post.imageUrl ? "image" : "text",
      likeCount: post.likes,
      likes: post.likes,
      commentCount: post.comments,
      comments: post.comments,
      favoriteCount: Math.floor(Math.random() * 15) + 2,
      favorites: Math.floor(Math.random() * 15) + 2,
      tags: post.tags,
      category: post.category,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      isPublic: true,
      status: "visible",
      reportCount: 0,
      viewCount: Math.floor(Math.random() * 200) + 50,
      shareCount: Math.floor(Math.random() * 20) + 2
    };
    
    batch.set(postRef, fullPost);
    totalPosts++;
  });

  await batch.commit();

  console.log(`✅ 成功创建了 ${totalPosts} 个社区帖子`);
  console.log('🏘️ 社区内容现在应该更加丰富和精美了！');
  
  process.exit(0);
}

createCommunityPosts();
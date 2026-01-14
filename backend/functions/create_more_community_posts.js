#!/usr/bin/env node

const admin = require('firebase-admin');

// Connect to current emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'psycho-dating-app',
});

const db = admin.firestore();

async function createMoreCommunityPosts() {
  console.log('🏘️ 创建更多社区帖子数据...\n');

  // 获取所有用户
  const usersSnapshot = await db.collection('users').get();
  const allUsers = usersSnapshot.docs.map(doc => ({
    uid: doc.id,
    ...doc.data()
  }));

  console.log(`👥 找到 ${allUsers.length} 个用户`);

  const additionalPosts = [
    {
      title: "深夜的情绪波动 🌙",
      content: "3am thoughts: 为什么深夜的情绪总是这么复杂？白天努力装作坚强，到了夜晚所有的脆弱都涌现。今晚决定不逃避，静静地坐着，感受这些情绪的流淌。发现当我不再抗拒时，它们反而慢慢平静下来了 💭",
      imageUrl: "https://images.unsplash.com/photo-1502134249126-9f3755a50d78?w=800&h=600&fit=crop",
      tags: ["深夜思考", "情绪接纳", "自我觉察", "内观"],
      likes: Math.floor(Math.random() * 60) + 20,
      comments: Math.floor(Math.random() * 15) + 5,
      category: "情绪探索"
    },
    {
      title: "断舍离的心灵收获 ✨",
      content: "花了整个周末整理房间，断舍离不仅仅是整理物品，更是整理内心。每当我放下一件不再需要的东西，内心也跟着轻盈了一些。空间变得简洁，思维也跟着清晰。发现外在的秩序真的会影响内在的平静 🏠",
      imageUrl: "https://images.unsplash.com/photo-1484154218962-a197022b5858?w=800&h=600&fit=crop",
      tags: ["断舍离", "极简主义", "内心整理", "生活哲学"],
      likes: Math.floor(Math.random() * 45) + 15,
      comments: Math.floor(Math.random() * 12) + 3,
      category: "生活智慧"
    },
    {
      title: "雨天的温柔治愈 🌧️",
      content: "喜欢雨天的下午，坐在窗边听雨声，配一杯热茶。雨水冲刷着世界，也冲刷着内心的尘埃。有时候我们需要的不是晴朗，而是这种温柔的洗涤。让情绪如雨水般流淌，然后重新开始 ☕",
      imageUrl: "https://images.unsplash.com/photo-1428592953211-077101b2021b?w=800&h=600&fit=crop",
      tags: ["雨天", "宁静", "情绪流动", "治愈时光"],
      likes: Math.floor(Math.random() * 55) + 18,
      comments: Math.floor(Math.random() * 14) + 4,
      category: "自然治愈"
    },
    {
      title: "学会与孤独和解 🫂",
      content: "之前总是害怕独处，觉得孤独是件可怕的事。但最近开始享受一个人的时光：一个人看电影、一个人吃饭、一个人散步。慢慢发现，孤独不是缺失，而是与自己深度连接的机会。学会了与孤独做朋友，内心变得更加坚定 💪",
      imageUrl: "https://images.unsplash.com/photo-1494253109108-2e30c049369b?w=800&h=600&fit=crop",
      tags: ["孤独", "独处", "自我陪伴", "内在力量"],
      likes: Math.floor(Math.random() * 70) + 25,
      comments: Math.floor(Math.random() * 18) + 6,
      category: "个人成长"
    },
    {
      title: "舞蹈释放的力量 💃",
      content: "今天尝试了舞动治疗，没有固定的动作，只是跟着内心的节拍自由摆动。当音乐响起，身体开始诚实地表达内心的情感。有愤怒、有悲伤、也有喜悦。30分钟后，感觉整个人都被释放了，那些压抑的情绪通过身体找到了出口 🎶",
      imageUrl: "https://images.unsplash.com/photo-1518611012118-696072aa579a?w=800&h=600&fit=crop",
      tags: ["舞蹈治疗", "身体表达", "情绪释放", "自由"],
      likes: Math.floor(Math.random() * 48) + 16,
      comments: Math.floor(Math.random() * 11) + 3,
      category: "身体疗愈"
    },
    {
      title: "城市漫步的意外收获 🚶‍♂️",
      content: "没有目的地的城市漫步是最好的冥想。今天走了3小时，从熟悉的街道到陌生的小巷。看到街角的咖啡店、老爷爷下棋、小朋友追泡泡...平凡的画面却充满生命力。提醒我生活中到处都是美好，只要我们愿意停下来观察 👀",
      imageUrl: "https://images.unsplash.com/photo-1449824913935-59a10b8d2000?w=800&h=600&fit=crop",
      tags: ["城市漫步", "mindful walking", "观察", "当下"],
      likes: Math.floor(Math.random() * 42) + 13,
      comments: Math.floor(Math.random() * 9) + 2,
      category: "正念生活"
    },
    {
      title: "治愈系电影推荐 🎬",
      content: "分享几部最近看的治愈系电影：《小森林》让我重新思考简单生活的美好，《海蒂和爷爷》提醒我大自然的治愈力量，《心灵奇旅》帮我找回对生活的热情。好的电影就像心灵导师，在我们迷茫时给予指引 🍿",
      imageUrl: "https://images.unsplash.com/photo-1489599988200-89b1b1d74698?w=800&h=600&fit=crop",
      tags: ["治愈电影", "心灵成长", "生活美学", "推荐"],
      likes: Math.floor(Math.random() * 56) + 19,
      comments: Math.floor(Math.random() * 16) + 5,
      category: "文化分享"
    },
    {
      title: "早起的神奇魔法 ☀️",
      content: "坚持早起一个月了，5:30起床看日出已经成为习惯。清晨的世界如此宁静，那一刻只有我和初升的太阳。这段独属于自己的时光让我找回了内心的节奏。早起不只是时间管理，更是对自己的温柔承诺 🌅",
      imageUrl: "https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=800&h=600&fit=crop",
      tags: ["早起", "日出", "morning routine", "自律"],
      likes: Math.floor(Math.random() * 51) + 17,
      comments: Math.floor(Math.random() * 13) + 4,
      category: "生活习惯"
    },
    {
      title: "手账记录心情的温度 📝",
      content: "开始用手账记录每天的心情温度，用不同颜色代表不同情绪。一个月后翻看，发现情绪就像天气一样，有晴有雨，但都会过去。这个小小的仪式让我学会了观察和接纳自己的情绪变化，不再急于改变它们 🎨",
      imageUrl: "https://images.unsplash.com/photo-1434030216411-0b793f4b4173?w=800&h=600&fit=crop",
      tags: ["手账", "情绪记录", "自我观察", "仪式感"],
      likes: Math.floor(Math.random() * 44) + 14,
      comments: Math.floor(Math.random() * 10) + 3,
      category: "情绪管理"
    },
    {
      title: "星空下的哲学思考 🌌",
      content: "昨晚去郊外看星星，躺在草地上仰望无垠的星空。在宇宙的浩瀚面前，内心的烦恼显得如此渺小。那一刻突然明白，我们都是星尘组成的，来自同一个起源，最终也将回归宇宙。这种宏观的视角带来了莫名的安慰 ✨",
      imageUrl: "https://images.unsplash.com/photo-1446776653964-20c1d3a81b06?w=800&h=600&fit=crop",
      tags: ["星空", "哲学思考", "宇宙观", "内心平静"],
      likes: Math.floor(Math.random() * 63) + 21,
      comments: Math.floor(Math.random() * 17) + 5,
      category: "哲学思辨"
    },
    {
      title: "烘焙治愈的秘密 🍞",
      content: "周末尝试了面包烘焙，从揉面到发酵再到烘烤，整个过程需要耐心等待。看着面团慢慢发起，闻着烤箱里传出的香味，内心也跟着暖起来。手作的温度传递着爱，那种满足感是买来的面包无法比拟的 💝",
      imageUrl: "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800&h=600&fit=crop",
      tags: ["烘焙", "手作", "耐心", "生活美学"],
      likes: Math.floor(Math.random() * 39) + 12,
      comments: Math.floor(Math.random() * 8) + 2,
      category: "生活创作"
    },
    {
      title: "温泉疗愈身心 ♨️",
      content: "今天去了山里的温泉，热水包围着身体，所有的紧张和焦虑都被温暖融化。闭上眼睛，只听到水声和鸟鸣，仿佛回到了母体般的安全感。温泉不只是放松身体，更是灵魂的洗礼。出来后整个人都重新充电了 🔋",
      imageUrl: "https://images.unsplash.com/photo-1544161515-4ab6ce6db874?w=800&h=600&fit=crop",
      tags: ["温泉", "身心疗愈", "放松", "自然疗法"],
      likes: Math.floor(Math.random() * 47) + 15,
      comments: Math.floor(Math.random() * 12) + 3,
      category: "身体疗愈"
    },
    {
      title: "朋友圈背后的真实 📱",
      content: "今天决定一整天不刷社交媒体，发现内心少了很多比较和焦虑。我们看到的朋友圈都是精心挑选的片段，真实生活远比那些完美照片复杂。学会了关注自己的内心声音，而不是别人的生活高光 🎭",
      imageUrl: "https://images.unsplash.com/photo-1611262588024-d12430b98920?w=800&h=600&fit=crop",
      tags: ["社交媒体", "真实自我", "比较心理", "digital detox"],
      likes: Math.floor(Math.random() * 68) + 23,
      comments: Math.floor(Math.random() * 19) + 6,
      category: "数字生活"
    },
    {
      title: "老人的生活智慧 👴",
      content: "在公园遇到一位下棋的老爷爷，聊天中他说：'年轻人总是急着要答案，其实人生最美的部分就在提问的过程中。'这句话让我思考了很久。也许我们不需要那么快找到所有答案，享受探索的过程本身就是意义 🏮",
      imageUrl: "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=800&h=600&fit=crop",
      tags: ["生活智慧", "老年人", "人生哲理", "慢生活"],
      likes: Math.floor(Math.random() * 59) + 20,
      comments: Math.floor(Math.random() * 15) + 4,
      category: "人生感悟"
    },
    {
      title: "植物陪伴的日常 🌿",
      content: "家里的绿萝长出了新叶，那嫩绿的颜色让人心情瞬间明亮。每天给它们浇水、晒太阳，观察它们的细微变化，这个过程教会了我什么是无条件的关爱。植物不会说话，但它们的生长就是最好的回应 🌱",
      imageUrl: "https://images.unsplash.com/photo-1485955900006-10f4d324d411?w=800&h=600&fit=crop",
      tags: ["植物", "生命力", "陪伴", "耐心"],
      likes: Math.floor(Math.random() * 41) + 13,
      comments: Math.floor(Math.random() * 9) + 2,
      category: "绿色生活"
    }
  ];

  let totalPosts = 0;
  const batch = db.batch();
  
  additionalPosts.forEach((post, index) => {
    // 随机选择一个用户作为作者
    const randomUser = allUsers[Math.floor(Math.random() * allUsers.length)];
    
    const postId = `community_post_extra_${Date.now()}_${index}`;
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

  console.log(`✅ 成功创建了 ${totalPosts} 个额外的社区帖子`);
  console.log('🏘️ 现在社区内容应该足够丰富了！');
  
  // 检查总帖子数
  const allPostsSnapshot = await db.collection('posts').get();
  console.log(`📊 数据库中总共有 ${allPostsSnapshot.size} 个帖子`);
  
  process.exit(0);
}

createMoreCommunityPosts();
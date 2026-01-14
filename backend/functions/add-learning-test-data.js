/**
 * Script to add test learning data for AI memory system
 * This will create sample chat history and match records for users
 * so we can test the personalized keyword functionality
 */

const { initializeApp, cert } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');

// Initialize Firebase Admin for emulator
try {
  initializeApp({
    projectId: 'psycho-dating-app'  // Use correct project ID for emulator
  });
} catch (error) {
  // App already initialized, continue
}

const db = getFirestore();

// Sample chat messages for different personality types
const chatSamples = {
  creative: [
    "我喜欢画画，最近在学习水彩画",
    "音乐对我来说很重要，特别是爵士乐",
    "我觉得艺术可以表达内心最真实的想法",
    "昨天看了一个很棒的展览，很有启发",
    "我正在写一本短篇小说集"
  ],
  intellectual: [
    "最近在读一本关于量子物理的书",
    "我对哲学很感兴趣，特别是存在主义",
    "科技发展对人类社会的影响值得深思",
    "我觉得批判性思维很重要",
    "喜欢和朋友讨论深层次的话题"
  ],
  social: [
    "我很享受和朋友们聚会的时光",
    "喜欢参加各种社交活动",
    "觉得人际关系是生活中最重要的",
    "我是一个很外向的人",
    "团队合作让我充满活力"
  ],
  introspective: [
    "我需要独处的时间来思考",
    "喜欢安静的环境，比如图书馆",
    "我觉得内心的平静很重要",
    "冥想帮助我更好地了解自己",
    "我比较倾向于深度而非广度的交流"
  ]
};

// Sample match reasons and keywords
const matchSamples = [
  {
    reason: "共同的艺术爱好",
    keywords: ["创作", "艺术", "灵感", "美学"]
  },
  {
    reason: "相似的价值观",
    keywords: ["真诚", "成长", "理解", "深度"]
  },
  {
    reason: "互补的性格特质",
    keywords: ["平衡", "互补", "支持", "和谐"]
  },
  {
    reason: "共同的兴趣爱好",
    keywords: ["音乐", "阅读", "旅行", "学习"]
  }
];

async function addLearningTestData() {
  try {
    console.log('🚀 开始添加AI学习测试数据...');

    // Get all users
    console.log('🔍 正在查找用户...');
    const usersSnapshot = await db.collection('users').get();
    console.log(`📊 查询返回 ${usersSnapshot.docs.length} 个文档`);
    
    const users = usersSnapshot.docs.map(doc => {
      const data = doc.data();
      console.log(`👤 用户: ${doc.id} - ${data.username || 'No username'}`);
      return { id: doc.id, ...data };
    });

    if (users.length < 2) {
      console.log('❌ 需要至少2个用户来生成测试数据');
      console.log('💡 请先运行 ./SEED_DATA.sh 来创建测试用户');
      return;
    }

    console.log(`📋 找到 ${users.length} 个用户`);

    // Add chat history for each user
    for (const user of users.slice(0, 3)) { // Only first 3 users
      console.log(`💬 为用户 ${user.username} (${user.id}) 添加聊天记录...`);
      
      // Assign personality type based on user traits or randomly
      const personalityTypes = Object.keys(chatSamples);
      const personality = personalityTypes[Math.floor(Math.random() * personalityTypes.length)];
      
      console.log(`🎭 分配性格类型: ${personality}`);
      
      const messages = chatSamples[personality];
      
      // Create conversations collection for this user
      for (let i = 0; i < messages.length; i++) {
        const conversationId = `test_conversation_${user.id}_${i}`;
        const messageId = `test_message_${user.id}_${i}`;
        
        await db
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .doc(messageId)
          .set({
            id: messageId,
            senderId: user.id,
            text: messages[i],
            type: 'text',
            status: 'sent',
            reactions: [],
            isDeleted: false,
            createdAt: FieldValue.serverTimestamp()
          });
      }
    }

    // Add match history for each user
    for (const user of users.slice(0, 3)) {
      console.log(`🎯 为用户 ${user.username} (${user.id}) 添加匹配记录...`);
      
      // Create 3-5 match records for each user
      const numMatches = 3 + Math.floor(Math.random() * 3);
      
      for (let i = 0; i < numMatches; i++) {
        // Pick a random other user to match with
        const otherUsers = users.filter(u => u.id !== user.id);
        const matchedUser = otherUsers[Math.floor(Math.random() * otherUsers.length)];
        const matchSample = matchSamples[Math.floor(Math.random() * matchSamples.length)];
        
        const actions = ['liked', 'chatted', 'liked', 'passed', 'chatted'];
        const action = actions[Math.floor(Math.random() * actions.length)];
        
        await db
          .collection('matchHistory')
          .doc(user.id)
          .collection('records')
          .doc(`test_match_${i}`)
          .set({
            matchedUserId: matchedUser.id,
            matchReason: matchSample.reason,
            keywords: matchSample.keywords,
            score: 0.7 + (Math.random() * 0.3), // Random score between 0.7-1.0
            userAction: action,
            timestamp: FieldValue.serverTimestamp(),
            chatDuration: action === 'chatted' ? Math.floor(Math.random() * 30) + 5 : null, // 5-35 minutes
            chatMessages: action === 'chatted' ? Math.floor(Math.random() * 20) + 5 : null  // 5-25 messages
          });
      }
      
      console.log(`✅ 为用户 ${user.username} 添加了 ${numMatches} 条匹配记录`);
    }

    console.log('🎉 AI学习测试数据添加完成！');
    console.log('');
    console.log('现在你可以：');
    console.log('1. 打开应用');
    console.log('2. 点击匹配按钮');
    console.log('3. 查看个性化的心情关键词！');
    
  } catch (error) {
    console.error('❌ 添加测试数据失败:', error);
  }
}

// Run the script
addLearningTestData().then(() => {
  console.log('脚本执行完成');
  process.exit(0);
}).catch(error => {
  console.error('脚本执行失败:', error);
  process.exit(1);
});
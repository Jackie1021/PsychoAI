#!/usr/bin/env node

const admin = require('firebase-admin');

// Connect to current emulator
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8081';
process.env.FIREBASE_AUTH_EMULATOR_HOST = '127.0.0.1:9098';

admin.initializeApp({
  projectId: 'psycho-dating-app',
});

const db = admin.firestore();

async function generateMatchesForAllUsers() {
  console.log('🎯 为所有用户生成匹配数据...\n');
  
  // 获取所有用户
  const usersSnapshot = await db.collection('users').get();
  const allUsers = usersSnapshot.docs.map(doc => ({
    uid: doc.id,
    ...doc.data()
  }));
  
  console.log(`👥 找到 ${allUsers.length} 个用户`);
  
  let totalMatches = 0;
  
  // 为每个用户生成匹配
  for (let i = 0; i < allUsers.length; i++) {
    const currentUser = allUsers[i];
    const otherUsers = allUsers.filter(u => u.uid !== currentUser.uid);
    
    console.log(`💕 为 ${currentUser.username} 生成匹配...`);
    
    // 基于特征相似度计算匹配分数
    const matches = [];
    
    for (const otherUser of otherUsers) {
      const currentTraits = new Set(currentUser.traits || []);
      const otherTraits = new Set(otherUser.traits || []);
      
      let score = 0;
      if (currentTraits.size === 0 && otherTraits.size === 0) {
        score = 0.3; // 基础匹配分数
      } else {
        const intersection = new Set([...currentTraits].filter(x => otherTraits.has(x))).size;
        const union = new Set([...currentTraits, ...otherTraits]).size;
        if (union > 0) {
          score = intersection / union;
        }
      }
      
      // 添加随机性和多样性
      score += Math.random() * 0.3;
      score = Math.min(score, 1.0);
      
      if (score > 0.2) { // 较低的阈值确保更多匹配
        matches.push({
          id: `match_${currentUser.uid}_${otherUser.uid}`,
          userA: {
            uid: currentUser.uid,
            username: currentUser.username,
            traits: currentUser.traits || [],
            freeText: currentUser.freeText || "",
            avatarUrl: currentUser.avatarUrl || "",
          },
          userB: {
            uid: otherUser.uid,
            username: otherUser.username,
            traits: otherUser.traits || [],
            freeText: otherUser.freeText || "",
            avatarUrl: otherUser.avatarUrl || "",
          },
          totalScore: Math.round(score * 100),
          reasoning: generateReasoning(currentUser, otherUser),
          compatibilityFactors: generateCompatibilityFactors(currentUser, otherUser),
          potentialChallenges: ["Different communication styles", "Varying energy levels"],
          recommendedActivities: generateActivities(currentUser, otherUser),
          formulaScore: score,
          finalScore: score,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    }
    
    // 随机选择8-12个最好的匹配
    matches.sort((a, b) => b.totalScore - a.totalScore);
    const selectedMatches = matches.slice(0, Math.min(12, Math.max(8, matches.length)));
    
    // 保存匹配到Firestore
    const userMatchesRef = db.collection("matches").doc(currentUser.uid);
    const batch = db.batch();
    
    // 清除现有匹配
    const existingMatches = await userMatchesRef.collection("candidates").get();
    existingMatches.docs.forEach(doc => {
      batch.delete(doc.ref);
    });
    
    // 添加新匹配
    selectedMatches.forEach(match => {
      const matchRef = userMatchesRef.collection("candidates").doc(match.userB.uid);
      batch.set(matchRef, match);
    });
    
    await batch.commit();
    
    console.log(`   ✅ 为 ${currentUser.username} 生成了 ${selectedMatches.length} 个匹配`);
    totalMatches += selectedMatches.length;
  }
  
  console.log(`\n🎉 完成！总共生成了 ${totalMatches} 个匹配关系`);
  console.log('👀 现在在Flutter应用中应该能看到更多匹配泡泡了！');
  
  process.exit(0);
}

function generateReasoning(userA, userB) {
  const reasons = [
    "Compatible interests and complementary traits",
    "Shared understanding of mental health journey",
    "Similar values and life perspectives",
    "Mutual support and growth potential",
    "Creative and thoughtful personalities",
    "Balanced emotional and practical approach",
    "Strong empathy and communication skills",
    "Aligned goals for personal development"
  ];
  return reasons[Math.floor(Math.random() * reasons.length)];
}

function generateCompatibilityFactors(userA, userB) {
  const factors = [
    ["Shared interests", "Mental health awareness"],
    ["Creative pursuits", "Emotional intelligence"],
    ["Personal growth focus", "Supportive nature"],
    ["Similar values", "Communication style"],
    ["Mindfulness practices", "Self-care priorities"],
    ["Artistic expression", "Deep conversations"],
    ["Community involvement", "Healing journey"],
    ["Professional compatibility", "Life balance"]
  ];
  return factors[Math.floor(Math.random() * factors.length)];
}

function generateActivities(userA, userB) {
  const activities = [
    ["Coffee chat", "Art museum visit", "Nature walk"],
    ["Yoga class", "Book discussion", "Cooking together"],
    ["Mindfulness session", "Concert", "Volunteer work"],
    ["Photography walk", "Craft workshop", "Farmers market"],
    ["Beach sunset", "Poetry reading", "Garden visit"],
    ["Hiking trail", "Music session", "Tea ceremony"],
    ["Art therapy", "Dance class", "Meditation retreat"]
  ];
  return activities[Math.floor(Math.random() * activities.length)];
}

generateMatchesForAllUsers();
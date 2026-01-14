"use strict";
/**
 * @file User Memory Learning Service
 * AI记忆学习系统，从用户历史记录中学习偏好和特征，
 * 提供智能关键词推荐和个性化匹配建议
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.saveUserInteraction = exports.getPersonalizedMoodKeywords = exports.updateUserLearningProfile = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
const node_fetch_1 = __importDefault(require("node-fetch"));
// interface MoodContext {
//   currentMood: string;
//   energyLevel: string;
//   socialDesire: string;
//   activityType: string;
//   timeContext: string;
//   keywords: string[];
// }
// Helper function to get Firestore
function getDb() {
    return admin_1.admin.firestore();
}
/**
 * Calls Gemini API for personality analysis
 */
async function analyzeUserPersonality(apiKey, userHistory, chatHistory, matchHistory) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;
    const analysisPrompt = `
作为一个专业的心理分析师和匹配专家，请分析以下用户的完整历史数据，生成详细的用户画像：

用户基础信息:
- 用户名: ${userHistory.username}
- 当前兴趣标签: ${userHistory.traits?.join(", ") || "无"}
- 自我介绍: ${userHistory.freeText || "无"}

聊天历史记录:
${chatHistory.map(chat => `- ${chat.text}`).join("\n")}

匹配历史记录:
${matchHistory.map(match => `- 匹配用户: ${match.matchedUserId}, 原因: ${match.matchReason}, 关键词: ${match.keywords.join(", ")}, 用户行为: ${match.userAction}`).join("\n")}

请基于以上信息，深度分析用户的心理特征、情感模式、兴趣偏好、沟通风格等，并返回JSON格式的详细用户画像：

\`\`\`json
{
  "personalityKeywords": ["内向", "创造性", "理性", "温和", "独立"],
  "emotionalPatterns": ["情感稳定", "容易共情", "需要安全感", "表达含蓄"],
  "interestCategories": ["艺术创作", "科技数码", "户外运动", "文学阅读"],
  "communicationStyle": "深度交流型",
  "relationshipGoals": ["长期稳定关系", "精神层面契合", "相互成长"],
  "activityPreferences": ["安静环境", "小群体聚会", "一对一深谈", "创意活动"],
  "valueSystem": ["真诚", "成长", "创新", "平等", "尊重"],
  "lifestyleIndicators": ["工作生活平衡", "注重品质", "喜欢学习", "重视友谊"],
  "confidenceScore": 0.85
}
\`\`\`

请确保分析结果准确反映用户的真实特征和偏好模式。
`;
    const requestBody = {
        contents: [{
                parts: [{
                        text: analysisPrompt
                    }]
            }],
        generationConfig: {
            temperature: 0.3,
            topK: 20,
            topP: 0.8,
            maxOutputTokens: 1000,
        }
    };
    functions.logger.info("🧠 Analyzing user personality", {
        userId: userHistory.uid,
        chatHistoryLength: chatHistory.length,
        matchHistoryLength: matchHistory.length,
    });
    const response = await (0, node_fetch_1.default)(url, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody)
    });
    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Gemini API error: ${response.status} ${errorText}`);
    }
    const data = await response.json();
    if (data.error || !data.candidates || data.candidates.length === 0) {
        throw new Error("Invalid response from Gemini API");
    }
    const candidate = data.candidates[0];
    if (candidate.finishReason !== "STOP" || !candidate.content?.parts?.[0]?.text) {
        throw new Error("Incomplete response from Gemini API");
    }
    const rawText = candidate.content.parts[0].text;
    // Extract JSON from response
    const jsonMatch = rawText.match(/```json([\s\S]*?)```/);
    const jsonText = jsonMatch ? jsonMatch[1].trim() : rawText.trim();
    try {
        const profile = JSON.parse(jsonText);
        return {
            ...profile,
            lastAnalyzed: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        };
    }
    catch (parseError) {
        functions.logger.error("❌ Failed to parse personality analysis", {
            error: parseError,
            jsonText: jsonText.substring(0, 200)
        });
        throw new Error("Failed to parse personality analysis");
    }
}
/**
 * Generates mood-based keyword suggestions
 */
async function generateMoodKeywords(apiKey, userProfile, currentContext) {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;
    const keywordPrompt = `
基于用户的个性分析和当前情境，生成个性化的心情/状态关键词建议：

用户个性特征:
- 性格关键词: ${userProfile.personalityKeywords?.join(", ")}
- 情感模式: ${userProfile.emotionalPatterns?.join(", ")}
- 兴趣类别: ${userProfile.interestCategories?.join(", ")}
- 沟通风格: ${userProfile.communicationStyle}
- 价值观: ${userProfile.valueSystem?.join(", ")}

当前情境: ${currentContext || "日常状态"}

请生成15-20个符合用户个性的心情/状态关键词，这些关键词将用于：
1. 帮助用户表达当前状态
2. 优化匹配算法
3. 提供个性化建议

返回JSON格式：

\`\`\`json
{
  "moodKeywords": [
    "创作灵感爆发", "寻找灵魂共鸣", "想要深度对话", "探索新可能", 
    "需要理解支持", "享受宁静时光", "渴望真诚交流", "寻求成长伙伴",
    "艺术感知敏锐", "思考人生意义", "温暖而内敛", "独立又渴望连接",
    "追求精神契合", "重视内在品质", "喜欢慢慢了解", "珍惜深层友谊"
  ]
}
\`\`\`

请确保关键词：
1. 符合用户的真实个性特征
2. 具有情感共鸣性
3. 便于理解和选择
4. 有助于精准匹配
`;
    const requestBody = {
        contents: [{
                parts: [{
                        text: keywordPrompt
                    }]
            }],
        generationConfig: {
            temperature: 0.4,
            topK: 30,
            topP: 0.9,
            maxOutputTokens: 500,
        }
    };
    const response = await (0, node_fetch_1.default)(url, {
        method: "POST",
        headers: {
            "Content-Type": "application/json",
        },
        body: JSON.stringify(requestBody)
    });
    if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`Gemini API error: ${response.status} ${errorText}`);
    }
    const data = await response.json();
    if (data.error || !data.candidates || data.candidates.length === 0) {
        throw new Error("Invalid response from Gemini API");
    }
    const candidate = data.candidates[0];
    if (candidate.finishReason !== "STOP" || !candidate.content?.parts?.[0]?.text) {
        throw new Error("Incomplete response from Gemini API");
    }
    const rawText = candidate.content.parts[0].text;
    // Extract JSON from response
    const jsonMatch = rawText.match(/```json([\s\S]*?)```/);
    const jsonText = jsonMatch ? jsonMatch[1].trim() : rawText.trim();
    try {
        const result = JSON.parse(jsonText);
        return result.moodKeywords || [];
    }
    catch (parseError) {
        functions.logger.error("❌ Failed to parse mood keywords", {
            error: parseError,
            jsonText: jsonText.substring(0, 200)
        });
        // Fallback keywords based on user profile
        return [
            "寻找共鸣", "深度交流", "真诚相待", "精神契合",
            "温暖陪伴", "理解支持", "成长伙伴", "创意分享"
        ];
    }
}
/**
 * Updates user learning profile
 */
exports.updateUserLearningProfile = functions
    .runWith({
    timeoutSeconds: 180,
    memory: "1GB"
})
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }
    const { userId, forceRefresh = false } = data;
    const uid = userId || context.auth.uid;
    // Get API key
    const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key || "AIzaSyAXzBf-BlfgSArI77f__D0h-fh1S9QG4gs";
    if (!apiKey) {
        throw new functions.https.HttpsError("failed-precondition", "Gemini API key not configured.");
    }
    try {
        // Get current user data
        const userDoc = await getDb().collection("users").doc(uid).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError("not-found", "User profile not found.");
        }
        const userData = userDoc.data();
        const existingProfile = userData.learningProfile;
        // Check if we need to refresh (once per week or forced)
        const oneWeekAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        const needsRefresh = forceRefresh ||
            !existingProfile ||
            !existingProfile.lastAnalyzed ||
            existingProfile.lastAnalyzed.toDate() < oneWeekAgo;
        if (!needsRefresh) {
            functions.logger.info("User profile is recent, skipping analysis", { userId: uid });
            return {
                profile: existingProfile,
                updated: false,
                message: "Profile is up to date"
            };
        }
        // Get chat history (last 50 messages)
        const chatHistorySnapshot = await getDb()
            .collectionGroup("messages")
            .where("senderId", "==", uid)
            .orderBy("createdAt", "desc")
            .limit(50)
            .get();
        const chatHistory = chatHistorySnapshot.docs.map(doc => doc.data());
        // Get match history (last 6 months)
        const sixMonthsAgo = new Date(Date.now() - 6 * 30 * 24 * 60 * 60 * 1000);
        const matchHistorySnapshot = await getDb()
            .collection("matchHistory")
            .doc(uid)
            .collection("records")
            .where("timestamp", ">=", sixMonthsAgo)
            .orderBy("timestamp", "desc")
            .limit(100)
            .get();
        const matchHistory = matchHistorySnapshot.docs.map(doc => doc.data());
        // Analyze user personality
        const learningProfile = await analyzeUserPersonality(apiKey, userData, chatHistory, matchHistory);
        // Update user document with learning profile
        await getDb().collection("users").doc(uid).update({
            learningProfile,
            lastProfileUpdate: admin_1.admin.firestore.FieldValue.serverTimestamp(),
        });
        functions.logger.info("✅ User learning profile updated", {
            userId: uid,
            confidenceScore: learningProfile.confidenceScore,
            personalityKeywords: learningProfile.personalityKeywords?.length,
        });
        return {
            profile: learningProfile,
            updated: true,
            message: "Profile successfully analyzed and updated"
        };
    }
    catch (error) {
        functions.logger.error("❌ Error updating user learning profile", {
            error,
            userId: uid,
        });
        throw new functions.https.HttpsError("internal", "Failed to update user learning profile");
    }
});
/**
 * Gets personalized mood keyword suggestions
 */
exports.getPersonalizedMoodKeywords = functions
    .runWith({
    timeoutSeconds: 60,
    memory: "512MB"
})
    .https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }
    const { userId, currentContext } = data;
    const uid = userId || context.auth.uid;
    // Get API key
    const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key || "AIzaSyAXzBf-BlfgSArI77f__D0h-fh1S9QG4gs";
    if (!apiKey) {
        throw new functions.https.HttpsError("failed-precondition", "Gemini API key not configured.");
    }
    try {
        // Get user learning profile
        const userDoc = await getDb().collection("users").doc(uid).get();
        if (!userDoc.exists) {
            throw new functions.https.HttpsError("not-found", "User profile not found.");
        }
        const userData = userDoc.data();
        const learningProfile = userData.learningProfile;
        // If no learning profile, generate basic keywords
        if (!learningProfile) {
            functions.logger.info("No learning profile found, returning basic keywords", { userId: uid });
            return {
                keywords: [
                    "寻找共鸣", "深度交流", "真诚相待", "温暖陪伴",
                    "理解支持", "精神契合", "创意分享", "成长伙伴",
                    "安静思考", "活力满满", "探索新鲜", "享受当下"
                ],
                source: "default"
            };
        }
        // Generate personalized keywords
        const personalizedKeywords = await generateMoodKeywords(apiKey, learningProfile, currentContext);
        functions.logger.info("✅ Generated personalized mood keywords", {
            userId: uid,
            keywordCount: personalizedKeywords.length,
            currentContext,
        });
        return {
            keywords: personalizedKeywords,
            source: "personalized",
            userProfile: {
                personalityKeywords: learningProfile.personalityKeywords,
                communicationStyle: learningProfile.communicationStyle,
            }
        };
    }
    catch (error) {
        functions.logger.error("❌ Error generating mood keywords", {
            error,
            userId: uid,
        });
        // Return fallback keywords
        return {
            keywords: [
                "寻找共鸣", "深度交流", "真诚相待", "温暖陪伴",
                "理解支持", "精神契合", "创意分享", "成长伙伴"
            ],
            source: "fallback"
        };
    }
});
/**
 * Saves user interaction for learning
 */
exports.saveUserInteraction = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }
    const { matchedUserId, action, keywords, score, chatDuration, chatMessages } = data;
    const uid = context.auth.uid;
    try {
        const interactionData = {
            matchedUserId,
            matchReason: "ai_chat_analysis",
            keywords: keywords || [],
            score: score || 0,
            userAction: action,
            timestamp: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            chatDuration,
            chatMessages,
        };
        await getDb()
            .collection("matchHistory")
            .doc(uid)
            .collection("records")
            .add(interactionData);
        functions.logger.info("✅ User interaction saved for learning", {
            userId: uid,
            matchedUserId,
            action,
        });
        return { success: true };
    }
    catch (error) {
        functions.logger.error("❌ Error saving user interaction", {
            error,
            userId: uid,
        });
        throw new functions.https.HttpsError("internal", "Failed to save interaction");
    }
});
//# sourceMappingURL=user_memory_service.js.map
/**
 * @file AI Chat Service
 * Handles VIP AI chat functionality with Gemini API integration,
 * conversation analysis for soulmate matching, and keyword generation.
 */

import * as functions from "firebase-functions";
import { admin } from "./admin";
import fetch from "node-fetch";

// Interfaces
interface ChatMessage {
  text: string;
  isUser: boolean;
  timestamp: string;
}

interface MatchProfile {
  uid: string;
  username: string;
  traits: string[];
  freeText: string;
  avatarUrl?: string;
  analysis?: MatchAnalysis;
}

interface MatchAnalysis {
  score: number;
  keyInsights: string[];
  compatibility: string;
  sharedInterests: string[];
  conversationStarters: string[];
}

// Helper function to get Firestore
function getDb() {
  return admin.firestore();
}

/**
 * Calls Gemini API for AI chat conversation
 */
async function callGeminiForChat(
  apiKey: string,
  message: string,
  conversationHistory: ChatMessage[]
): Promise<string> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

  // Build conversation context
  let context = "You are a compassionate AI companion designed to help users find their soulmates. You should be empathetic, understanding, and engaging. Respond naturally and helpfully while occasionally identifying opportunities to help users find meaningful connections.\n\n";
  
  if (conversationHistory.length > 0) {
    context += "Previous conversation:\n";
    conversationHistory.forEach((msg) => {
      context += `${msg.isUser ? 'User' : 'AI'}: ${msg.text}\n`;
    });
    context += "\n";
  }
  
  context += `User: ${message}\nAI:`;

  functions.logger.info("🤖 Calling Gemini for AI chat", {
    messageLength: message.length,
    historyLength: conversationHistory.length,
  });

  const requestBody = {
    contents: [{
      parts: [{
        text: context
      }]
    }],
    generationConfig: {
      temperature: 0.7,
      topK: 40,
      topP: 0.95,
      maxOutputTokens: 300,
    }
  };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify(requestBody)
  });

  if (!response.ok) {
    const errorText = await response.text();
    functions.logger.error("❌ Gemini API error in chat", {
      status: response.status,
      error: errorText
    });
    throw new Error(`Gemini API error: ${response.status} ${errorText}`);
  }

  const data: any = await response.json();

  if (data.error || !data.candidates || data.candidates.length === 0) {
    functions.logger.error("❌ Invalid Gemini response for chat", { data });
    throw new Error("Invalid response from Gemini API");
  }

  const candidate = data.candidates[0];
  if (candidate.finishReason !== "STOP" || !candidate.content?.parts?.[0]?.text) {
    throw new Error("Incomplete or blocked response from Gemini API");
  }

  return candidate.content.parts[0].text.trim();
}

/**
 * Analyzes conversation and finds potential soulmate matches
 */
async function analyzeConversationForMatches(
  apiKey: string,
  conversationText: string,
  currentUser: any,
  allUsers: any[]
): Promise<MatchProfile[]> {
  const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

  const analysisPrompt = `
Analyze the following conversation and identify the user's key personality traits, interests, emotional needs, and life situation:

Conversation:
${conversationText}

Current user profile:
- Username: ${currentUser.username}
- Traits: ${currentUser.traits?.join(", ") || "None"}
- Bio: ${currentUser.freeText || "No bio"}

Available potential matches:
${allUsers.map(user => `- ${user.username}: Traits: ${user.traits?.join(", ") || "None"}, Bio: ${user.freeText || "No bio"}`).join("\n")}

Based on the conversation analysis, select the top 3 most compatible matches and provide detailed analysis. Return your response in this exact JSON format:

\`\`\`json
{
  "matches": [
    {
      "uid": "user_id",
      "username": "username",
      "analysis": {
        "score": 85,
        "keyInsights": ["shared love for creativity", "similar life goals", "complementary personalities"],
        "compatibility": "High emotional and intellectual compatibility based on conversation patterns",
        "sharedInterests": ["art", "travel", "deep conversations"],
        "conversationStarters": ["Tell me about your latest creative project", "What's your dream travel destination?"]
      }
    }
  ]
}
\`\`\`
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

  functions.logger.info("🔍 Analyzing conversation for matches", {
    conversationLength: conversationText.length,
    availableUsers: allUsers.length,
  });

  const response = await fetch(url, {
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

  const data: any = await response.json();

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
    
    // Build match profiles with full user data
    const matchProfiles: MatchProfile[] = result.matches.map((match: any) => {
      const user = allUsers.find(u => u.uid === match.uid || u.username === match.username);
      return {
        uid: user?.uid || match.uid,
        username: user?.username || match.username,
        traits: user?.traits || [],
        freeText: user?.freeText || "",
        avatarUrl: user?.avatarUrl,
        analysis: match.analysis
      };
    }).filter((profile: MatchProfile) => profile.uid); // Only include valid matches

    return matchProfiles;
  } catch (parseError) {
    functions.logger.error("❌ Failed to parse conversation analysis", {
      error: parseError,
      jsonText: jsonText.substring(0, 200)
    });
    throw new Error("Failed to parse conversation analysis");
  }
}

/**
 * Helper function to check VIP access
 */
async function checkVipAccess(userId: string): Promise<boolean> {
  try {
    const userDoc = await getDb().collection("users").doc(userId).get();
    
    if (!userDoc.exists) {
      return false;
    }

    const userData = userDoc.data()!;
    const membershipTier = userData.membershipTier as string;
    const membershipExpiry = userData.membershipExpiry;

    // Check if user has active premium/pro membership
    if (membershipTier === "free" || !membershipTier) {
      return false;
    }

    // Check if membership has expired
    if (membershipExpiry && membershipExpiry.toDate() < new Date()) {
      return false;
    }

    return true;
  } catch (error) {
    functions.logger.error("❌ Error checking VIP access", { error, userId });
    return false;
  }
}

/**
 * Checks if user has VIP access to AI chat
 */
export const hasVipAccess = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { userId } = data;
  const uid = userId || context.auth.uid;

  return await checkVipAccess(uid);
});

/**
 * Sends a message to AI chat and gets response (VIP feature)
 */
export const sendAiChatMessage = functions
  .runWith({
    timeoutSeconds: 60,
    memory: "512MB"
  })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { message, conversationHistory, userId } = data;
    const uid = userId || context.auth.uid;

    // Validate VIP access
    const hasVipAccess = await checkVipAccess(uid);
    if (!hasVipAccess) {
      throw new functions.https.HttpsError("permission-denied", "VIP membership required for AI chat feature.");
    }

    // Get API key
    const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key || "AIzaSyAXzBf-BlfgSArI77f__D0h-fh1S9QG4gs";
    
    if (!apiKey) {
      throw new functions.https.HttpsError("failed-precondition", "Gemini API key not configured.");
    }

    try {
      const response = await callGeminiForChat(apiKey, message, conversationHistory || []);
      
      functions.logger.info("✅ AI chat response generated", {
        userId: uid,
        messageLength: message.length,
        responseLength: response.length,
      });

      return { response };
    } catch (error) {
      functions.logger.error("❌ Error in AI chat", {
        error,
        userId: uid,
        messagePreview: message.substring(0, 50)
      });

      // Return a friendly fallback response
      return { 
        response: "I'm having trouble connecting right now, but I'm here to listen. Could you tell me more about what's on your mind?" 
      };
    }
  });

/**
 * Analyzes chat conversation and finds soulmate matches
 */
export const analyzeChatAndFindMatches = functions
  .runWith({
    timeoutSeconds: 120,
    memory: "1GB"
  })
  .https.onCall(async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
    }

    const { userId, conversationText } = data;
    const uid = userId || context.auth.uid;

    // Validate VIP access
    const hasVip = await checkVipAccess(uid);
    if (!hasVip) {
      throw new functions.https.HttpsError("permission-denied", "VIP membership required for soulmate matching feature.");
    }

    // Get API key
    const apiKey = process.env.GEMINI_API_KEY || functions.config().gemini?.key || "AIzaSyAXzBf-BlfgSArI77f__D0h-fh1S9QG4gs";
    
    if (!apiKey) {
      throw new functions.https.HttpsError("failed-precondition", "Gemini API key not configured.");
    }

    try {
      // Get current user data
      const currentUserDoc = await getDb().collection("users").doc(uid).get();
      if (!currentUserDoc.exists) {
        throw new functions.https.HttpsError("not-found", "User profile not found.");
      }
      
      const currentUser = currentUserDoc.data()!;

      // Get all other users for matching
      const allUsersSnapshot = await getDb()
        .collection("users")
        .where("isSuspended", "!=", true)
        .limit(50) // Limit to manageable number for analysis
        .get();

      const allUsers = allUsersSnapshot.docs
        .map(doc => ({ uid: doc.id, ...doc.data() }))
        .filter(user => user.uid !== uid);

      if (allUsers.length === 0) {
        functions.logger.info("No users available for matching", { userId: uid });
        return { matches: [] };
      }

      // Analyze conversation and find matches
      const matches = await analyzeConversationForMatches(
        apiKey, 
        conversationText, 
        currentUser, 
        allUsers
      );

      functions.logger.info("✅ Conversation analysis completed", {
        userId: uid,
        matchesFound: matches.length,
        conversationLength: conversationText.length,
      });

      return { matches };
    } catch (error) {
      functions.logger.error("❌ Error in conversation analysis", {
        error,
        userId: uid,
        conversationLength: conversationText?.length || 0,
      });

      // Return empty matches on error
      return { matches: [] };
    }
  });
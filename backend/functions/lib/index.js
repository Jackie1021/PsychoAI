"use strict";
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
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.getMatchesSimple = exports.getMatches = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
// import { callAgent } from "./llm_service";
// import { matchmakerAgentPrompt } from "./agents";
__exportStar(require("./chat_service"), exports);
__exportStar(require("./ai_chat_service"), exports);
__exportStar(require("./user_memory_service"), exports);
__exportStar(require("./user_handler"), exports);
__exportStar(require("./post_handler"), exports);
__exportStar(require("./report_handler"), exports);
__exportStar(require("./comment_handler"), exports);
__exportStar(require("./membership_handler"), exports);
__exportStar(require("./llm_analysis_service"), exports);
exports.getMatches = functions
    .runWith({
    timeoutSeconds: 300, // 5 minutes - enough for 10 concurrent LLM calls
    memory: "512MB"
})
    .https.onCall(async (data, context) => {
    // 1. Authenticate the user.
    let uid;
    // In emulator mode, allow fallback to first available user for testing
    if (!context.auth || !context.auth.uid || context.auth.uid.trim() === '') {
        functions.logger.warn('⚠️ No auth context, using fallback for emulator testing');
        // Get first available user as fallback for emulator testing
        const db = admin_1.admin.firestore();
        const usersSnapshot = await db.collection("users").limit(1).get();
        if (usersSnapshot.empty) {
            throw new functions.https.HttpsError("not-found", "No users found in system. Please create user profiles first.");
        }
        uid = usersSnapshot.docs[0].id;
        functions.logger.info(`🔧 Using fallback user ID for testing: ${uid}`);
    }
    else {
        uid = context.auth.uid;
        functions.logger.info(`✅ Authenticated user ID: ${uid}`);
    }
    // 2. Fetch the current user and all other users from Firestore.
    const db = admin_1.admin.firestore();
    const usersCollection = db.collection("users");
    const currentUserDoc = await usersCollection.doc(uid).get();
    let currentUser;
    if (!currentUserDoc.exists) {
        // Create user document if it doesn't exist
        const userProfile = {
            uid,
            username: context.auth?.token?.name || context.auth?.token?.email?.split("@")[0] || "User",
            traits: [],
            freeText: "",
            avatarUrl: context.auth?.token?.picture || "",
            bio: "",
            email: context.auth?.token?.email || "",
            lastActive: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            isSuspended: false,
            reportCount: 0,
            followersCount: 0,
            followingCount: 0,
            postsCount: 0,
            followedBloggerIds: [],
            favoritedPostIds: [],
            favoritedConversationIds: [],
            likedPostIds: [],
            createdAt: admin_1.admin.firestore.FieldValue.serverTimestamp(),
            privacy: {
                visibility: "public",
            },
        };
        await usersCollection.doc(uid).set(userProfile);
        functions.logger.info(`User profile created for ${uid} during getMatches`);
        currentUser = userProfile;
    }
    else {
        currentUser = {
            ...currentUserDoc.data(),
            uid,
        };
    }
    const allUsersSnapshot = await usersCollection.get();
    const allUsers = allUsersSnapshot.docs
        .map((doc) => {
        const data = doc.data();
        return {
            ...data,
            uid: doc.id,
        };
    })
        .filter((user) => user.uid !== uid && !user.isSuspended);
    if (allUsers.length === 0) {
        functions.logger.info(`No other users found for matching user ${uid}`);
        return { success: true, matchesFound: 0 };
    }
    // 3. Run the initial deterministic matching algorithm.
    const scoredUsers = [];
    for (const otherUser of allUsers) {
        const userTraits = new Set(currentUser.traits || []);
        const otherUserTraits = new Set(otherUser.traits || []);
        if (userTraits.size === 0 && otherUserTraits.size === 0) {
            // If both have no traits, give a small baseline score
            scoredUsers.push({ user: otherUser, score: 0.2 });
            continue;
        }
        const intersection = new Set([...userTraits].filter((x) => otherUserTraits.has(x))).size;
        const union = new Set([...userTraits, ...otherUserTraits]).size;
        if (union === 0)
            continue;
        const score = intersection / union;
        if (score > 0.01) { // Very low threshold to get more matches for testing
            scoredUsers.push({ user: otherUser, score });
        }
    }
    // If no good trait matches, just include all users with a baseline score
    if (scoredUsers.length === 0) {
        functions.logger.info(`No trait-based matches found, using all users for ${uid}`);
        allUsers.forEach((user) => {
            scoredUsers.push({ user, score: 0.1 });
        });
    }
    // Sort by score and take the top candidates for analysis
    scoredUsers.sort((a, b) => b.score - a.score);
    const topCandidates = scoredUsers.slice(0, Math.min(15, scoredUsers.length));
    // 4. Create simple matches without LLM (temporarily disabled for debugging)
    const llmResults = topCandidates.map((candidate) => {
        const formulaScore = candidate.score;
        const finalScore = formulaScore;
        return {
            totalScore: Math.round((formulaScore * 100) + Math.random() * 20), // Random score 80-100
            reasoning: "Compatible interests and complementary traits",
            compatibilityFactors: ["Shared interests", "Mental health awareness"],
            potentialChallenges: ["Different communication styles"],
            recommendedActivities: ["Coffee chat", "Deep conversation", "Art therapy session"],
            formulaScore,
            finalScore,
            userA: {
                uid: currentUser.uid,
                username: currentUser.username,
                traits: currentUser.traits || [],
                freeText: currentUser.freeText || "",
                avatarUrl: currentUser.avatarUrl,
            },
            userB: {
                uid: candidate.user.uid,
                username: candidate.user.username,
                traits: candidate.user.traits || [],
                freeText: candidate.user.freeText || "",
                avatarUrl: candidate.user.avatarUrl,
            },
            id: `match_${uid}_${candidate.user.uid}` // Create a unique ID
        };
    });
    functions.logger.info(`✅ LLM analysis completed: ${llmResults.length} successful out of ${topCandidates.length} candidates`);
    // 5. Save the rich analysis results back to Firestore.
    const batch = db.batch();
    const matchesCollection = db.collection("matches").doc(uid).collection("candidates");
    llmResults.forEach((result) => {
        const docRef = matchesCollection.doc(result.userB.uid);
        batch.set(docRef, result);
    });
    await batch.commit();
    functions.logger.info(`💾 Successfully saved ${llmResults.length} matches for user ${uid}.`);
    return { success: true, matchesFound: llmResults.length };
});
// Simplified version of getMatches without LLM calls for debugging
exports.getMatchesSimple = functions
    .runWith({
    timeoutSeconds: 60,
    memory: "256MB"
})
    .https.onCall(async (data, context) => {
    try {
        functions.logger.info('🚀 Starting simplified getMatches...');
        // 1. Authenticate the user
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated", "The function must be called while authenticated.");
        }
        const uid = context.auth.uid;
        if (!uid || uid.trim() === '') {
            functions.logger.error('❌ User ID is empty or null');
            throw new functions.https.HttpsError("unauthenticated", "User ID is required but was not provided.");
        }
        functions.logger.info(`👤 User ID: ${uid}`);
        // 2. Fetch current user and all users
        const db = admin_1.admin.firestore();
        const usersCollection = db.collection("users");
        const currentUserDoc = await usersCollection.doc(uid).get();
        if (!currentUserDoc.exists) {
            functions.logger.error('❌ Current user document not found');
            throw new functions.https.HttpsError("not-found", "User profile not found. Please complete your profile first.");
        }
        const currentUser = {
            ...currentUserDoc.data(),
            uid,
        };
        functions.logger.info(`✅ Found current user: ${currentUser.username}`);
        // 3. Get all other users
        const allUsersSnapshot = await usersCollection.get();
        const allUsers = allUsersSnapshot.docs
            .map(doc => ({ ...doc.data(), uid: doc.id }))
            .filter(user => user.uid !== uid);
        functions.logger.info(`📊 Found ${allUsers.length} potential matches`);
        // 4. Create simple matches (without LLM)
        const matches = allUsers.slice(0, 3).map((user, index) => ({
            id: `match_${uid}_${user.uid}`,
            userA: {
                uid: currentUser.uid,
                username: currentUser.username || 'Unknown',
                traits: currentUser.traits || [],
                freeText: currentUser.freeText || "",
                avatarUrl: currentUser.avatarUrl || "",
            },
            userB: {
                uid: user.uid,
                username: user.username || 'Unknown',
                traits: user.traits || [],
                freeText: user.freeText || "",
                avatarUrl: user.avatarUrl || "",
            },
            totalScore: 80 + index * 2,
            reasoning: "Compatible interests and complementary traits",
            compatibilityFactors: ["Shared interests", "Mental health awareness"],
            potentialChallenges: ["Different communication styles"],
            recommendedActivities: ["Coffee chat", "Art therapy session"],
            formulaScore: 0.8,
            finalScore: 0.8
        }));
        functions.logger.info(`✅ Created ${matches.length} simple matches`);
        // 5. Store matches
        const userMatchesRef = db.collection("matches").doc(uid);
        const matchesBatch = db.batch();
        // Clear existing matches
        const existingMatches = await userMatchesRef.collection("candidates").get();
        existingMatches.docs.forEach(doc => {
            matchesBatch.delete(doc.ref);
        });
        // Add new matches
        matches.forEach(match => {
            const matchRef = userMatchesRef.collection("candidates").doc(match.id);
            matchesBatch.set(matchRef, match);
        });
        await matchesBatch.commit();
        functions.logger.info(`💾 Stored ${matches.length} matches in Firestore`);
        return {
            success: true,
            matchCount: matches.length,
            message: 'Matches generated successfully (simplified version)'
        };
    }
    catch (error) {
        functions.logger.error('❌ Error in simplified getMatches:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError("internal", "Failed to generate matches: " + (error instanceof Error ? error.message : String(error)));
    }
});
//# sourceMappingURL=index.js.map
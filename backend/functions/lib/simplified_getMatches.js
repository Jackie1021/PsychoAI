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
Object.defineProperty(exports, "__esModule", { value: true });
exports.getMatchesSimple = void 0;
const functions = __importStar(require("firebase-functions"));
const admin = __importStar(require("firebase-admin"));
// Simplified version of getMatches without LLM calls
exports.getMatchesSimple = functions
    .runWith({
    timeoutSeconds: 60,
    memory: "256MB"
})
    .https.onCall(async (data, context) => {
    try {
        console.log('🚀 Starting simplified getMatches...');
        // 1. Authenticate the user
        if (!context.auth) {
            throw new functions.https.HttpsError("unauthenticated", "The function must be called while authenticated.");
        }
        const uid = context.auth.uid;
        console.log(`👤 User ID: ${uid}`);
        // 2. Fetch current user and all users
        const db = admin.firestore();
        const usersCollection = db.collection("users");
        const currentUserDoc = await usersCollection.doc(uid).get();
        if (!currentUserDoc.exists) {
            console.log('❌ Current user document not found');
            throw new functions.https.HttpsError("not-found", "User profile not found. Please complete your profile first.");
        }
        const currentUser = {
            ...currentUserDoc.data(),
            uid,
        };
        console.log(`✅ Found current user: ${currentUser.username}`);
        // 3. Get all other users
        const allUsersSnapshot = await usersCollection.get();
        const allUsers = allUsersSnapshot.docs
            .map(doc => ({ ...doc.data(), uid: doc.id }))
            .filter(user => user.uid !== uid);
        console.log(`📊 Found ${allUsers.length} potential matches`);
        // 4. Create simple matches (without LLM)
        const matches = allUsers.slice(0, 5).map((user, index) => ({
            id: `match_${uid}_${user.uid}`,
            userA: {
                uid: currentUser.uid,
                username: currentUser.username,
                traits: currentUser.traits || [],
                freeText: currentUser.freeText || "",
                avatarUrl: currentUser.avatarUrl || "",
            },
            userB: {
                uid: user.uid,
                username: user.username,
                traits: user.traits || [],
                freeText: user.freeText || "",
                avatarUrl: user.avatarUrl || "",
            },
            totalScore: 80 + index * 2, // Simple scoring
            reasoning: "Compatible interests and complementary traits",
            compatibilityFactors: ["Shared interests", "Mental health awareness"],
            potentialChallenges: ["Different communication styles"],
            recommendedActivities: ["Coffee chat", "Art therapy session"],
            formulaScore: 0.8,
            finalScore: 0.8
        }));
        console.log(`✅ Created ${matches.length} simple matches`);
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
        console.log(`💾 Stored ${matches.length} matches in Firestore`);
        return {
            success: true,
            matchCount: matches.length,
            message: 'Matches generated successfully (simplified version)'
        };
    }
    catch (error) {
        console.error('❌ Error in simplified getMatches:', error);
        if (error instanceof functions.https.HttpsError) {
            throw error;
        }
        throw new functions.https.HttpsError("internal", "Failed to generate matches: " + (error instanceof Error ? error.message : String(error)));
    }
});
//# sourceMappingURL=simplified_getMatches.js.map
import * as functions from "firebase-functions";
import { admin } from "./admin";
import { callAgent } from "./llm_service";
import { matchmakerAgentPrompt } from "./agents";

export * from "./chat_service";
export * from "./user_handler";
export * from "./post_handler";
export * from "./report_handler";
export * from "./comment_handler";
export * from "./membership_handler";
export * from "./llm_analysis_service";

interface UserData {
  uid: string;
  username: string;
  traits: string[];
  freeText: string;
  avatarUrl?: string;
  bio?: string;
  lastActive?: any;
  isSuspended?: boolean;
  reportCount?: number;
}

export const getMatches = functions
  .runWith({
    timeoutSeconds: 300, // 5 minutes - enough for 10 concurrent LLM calls
    memory: "512MB"
  })
  .https.onCall(async (data, context) => {
  // 1. Authenticate the user.
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "The function must be called while authenticated."
    );
  }
  const uid = context.auth.uid;

  // 2. Fetch the current user and all other users from Firestore.
  const db = admin.firestore();
  const usersCollection = db.collection("users");

  const currentUserDoc = await usersCollection.doc(uid).get();

  let currentUser: UserData;
  if (!currentUserDoc.exists) {
    // Create user document if it doesn't exist
    const userProfile = {
      uid,
      username: context.auth.token?.name || context.auth.token?.email?.split("@")[0] || "User",
      traits: [],
      freeText: "",
      avatarUrl: context.auth.token?.picture || "",
      bio: "",
      email: context.auth.token?.email || "",
      lastActive: admin.firestore.FieldValue.serverTimestamp(),
      isSuspended: false,
      reportCount: 0,
      followersCount: 0,
      followingCount: 0,
      postsCount: 0,
      followedBloggerIds: [],
      favoritedPostIds: [],
      favoritedConversationIds: [],
      likedPostIds: [],
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      privacy: {
        visibility: "public",
      },
    };

    await usersCollection.doc(uid).set(userProfile);
    functions.logger.info(`User profile created for ${uid} during getMatches`);
    currentUser = userProfile as any;
  } else {
    currentUser = {
      ...(currentUserDoc.data() as UserData),
      uid,
    };
  }

  const allUsersSnapshot = await usersCollection.get();
  const allUsers = allUsersSnapshot.docs
    .map((doc) => {
      const data = doc.data() as UserData;
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
  const scoredUsers: { user: UserData; score: number }[] = [];
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

    if (union === 0) continue;

    const score = intersection / union;
    if (score > 0.05) { // A low threshold to get a decent pool for the LLM
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

  // Sort by score and take the top 10 for LLM analysis (reduced to save API calls)
  scoredUsers.sort((a, b) => b.score - a.score);
  const topCandidates = scoredUsers.slice(0, Math.min(10, scoredUsers.length));

  // 4. Concurrently call the LLM Agent for each candidate.
  const llmPromises = topCandidates.map(async (candidate) => {
    const prompt = matchmakerAgentPrompt(currentUser, candidate.user);
    try {
      const llmResponse = await callAgent(prompt);
      const formulaScore = candidate.score;
      const aiScore = llmResponse.totalScore / 100; // Normalize AI score to 0-1

      // Calculate a weighted final score
      const finalScore = formulaScore * 0.3 + aiScore * 0.7;

      return {
        ...llmResponse,
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
    } catch (error) {
      functions.logger.warn(
        `⚠️ Skipping match ${uid} - ${candidate.user.uid} due to LLM error`,
        { 
          error: error instanceof Error ? error.message : String(error),
          candidateUsername: candidate.user.username
        }
      );
      return null; // Return null if a single LLM call fails - will be filtered out
    }
  });

  const llmResults = (await Promise.all(llmPromises)).filter(
    (result) => result !== null
  ) as any[];

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

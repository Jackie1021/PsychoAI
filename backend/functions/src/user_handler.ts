import * as functions from "firebase-functions";
import { admin } from "./admin";
import { FieldValue } from "firebase-admin/firestore";

/**
 * Triggered when a new user is created via Firebase Auth.
 * Automatically creates a user profile document in Firestore.
 */
export const onUserCreated = functions.auth.user().onCreate(async (user) => {
  const db = admin.firestore();

  const userProfile = {
    uid: user.uid,
    username: user.displayName || user.email?.split("@")[0] || "User",
    avatarUrl: user.photoURL || "",
    bio: "",
    traits: [],
    freeText: "",
    lastActive: FieldValue.serverTimestamp(),
    isSuspended: false,
    reportCount: 0,
    createdAt: FieldValue.serverTimestamp(),
    followedBloggerIds: [],
    favoritedPostIds: [],
    favoritedConversationIds: [],
    likedPostIds: [],
    followersCount: 0,
    followingCount: 0,
    postsCount: 0,
    membershipTier: "free",
    membershipExpiry: null,
    subscriptionId: null,
    privacy: {
      visibility: "public",
    },
  };

  try {
    await db.collection("users").doc(user.uid).set(userProfile);
    functions.logger.info(`User profile created for ${user.uid}`);
  } catch (error) {
    functions.logger.error("Error creating user profile:", error);
    throw error;
  }
});

/**
 * Updates the last active timestamp for a user.
 * Called by the client when user performs actions.
 */
export const updateUserActivity = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const db = admin.firestore();
    const uid = context.auth.uid;

    try {
      await db.collection("users").doc(uid).update({
        lastActive: FieldValue.serverTimestamp(),
      });

      return { success: true };
    } catch (error) {
      functions.logger.error("Error updating user activity:", error);
      throw new functions.https.HttpsError(
        "internal",
        "Failed to update activity"
      );
    }
  }
);

/**
 * Blocks another user. Blocked users won't appear in feeds or matches.
 */
export const blockUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { blockedUid } = data;
  if (!blockedUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "blockedUid is required"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  if (uid === blockedUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Cannot block yourself"
    );
  }

  try {
    await db
      .collection("users")
      .doc(uid)
      .collection("blocks")
      .doc(blockedUid)
      .set({
        blockedAt: FieldValue.serverTimestamp(),
      });

    // Create audit log
    await db.collection("auditLogs").add({
      action: "user_blocked",
      actorId: uid,
      targetType: "user",
      targetId: blockedUid,
      timestamp: FieldValue.serverTimestamp(),
    });

    functions.logger.info(`User ${uid} blocked ${blockedUid}`);
    return { success: true, message: "User blocked successfully" };
  } catch (error) {
    functions.logger.error("Error blocking user:", error);
    throw new functions.https.HttpsError("internal", "Failed to block user");
  }
});

/**
 * Unblocks a previously blocked user.
 */
export const unblockUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { blockedUid } = data;
  if (!blockedUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "blockedUid is required"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  try {
    await db
      .collection("users")
      .doc(uid)
      .collection("blocks")
      .doc(blockedUid)
      .delete();

    functions.logger.info(`User ${uid} unblocked ${blockedUid}`);
    return { success: true, message: "User unblocked successfully" };
  } catch (error) {
    functions.logger.error("Error unblocking user:", error);
    throw new functions.https.HttpsError("internal", "Failed to unblock user");
  }
});

/**
 * Follows another user. Updates both follower and following collections and counters.
 */
export const followUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { targetUid } = data;
  if (!targetUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUid is required"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  if (uid === targetUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Cannot follow yourself"
    );
  }

  const currentUserRef = db.collection("users").doc(uid);
  const targetUserRef = db.collection("users").doc(targetUid);

  const [targetDoc, existingFollow] = await Promise.all([
    targetUserRef.get(),
    currentUserRef.collection("following").doc(targetUid).get(),
  ]);

  if (!targetDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Target user not found");
  }

  if (existingFollow.exists) {
    return { success: true, alreadyFollowing: true };
  }

  const batch = db.batch();

  batch.set(
    currentUserRef.collection("following").doc(targetUid),
    {
      followedAt: FieldValue.serverTimestamp(),
    }
  );

  batch.set(
    targetUserRef.collection("followers").doc(uid),
    {
      followedAt: FieldValue.serverTimestamp(),
    }
  );

  batch.update(currentUserRef, {
    followedBloggerIds: FieldValue.arrayUnion(targetUid),
    followingCount: FieldValue.increment(1),
  });

  batch.update(targetUserRef, {
    followersCount: FieldValue.increment(1),
  });

  batch.set(db.collection("auditLogs").doc(), {
    action: "user_followed",
    actorId: uid,
    targetType: "user",
    targetId: targetUid,
    timestamp: FieldValue.serverTimestamp(),
  });

  await batch.commit();

  functions.logger.info(`User ${uid} followed ${targetUid}`);
  return { success: true };
});

/**
 * Unfollows a previously followed user.
 */
export const unfollowUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { targetUid } = data;
  if (!targetUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "targetUid is required"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  if (uid === targetUid) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Cannot unfollow yourself"
    );
  }

  const currentUserRef = db.collection("users").doc(uid);
  const targetUserRef = db.collection("users").doc(targetUid);

  const followingDoc = await currentUserRef.collection("following").doc(targetUid).get();

  if (!followingDoc.exists) {
    return { success: true, alreadyUnfollowed: true };
  }

  const batch = db.batch();

  batch.delete(followingDoc.ref);
  batch.delete(targetUserRef.collection("followers").doc(uid));

  batch.update(currentUserRef, {
    followedBloggerIds: FieldValue.arrayRemove(targetUid),
    followingCount: FieldValue.increment(-1),
  });

  batch.update(targetUserRef, {
    followersCount: FieldValue.increment(-1),
  });

  batch.set(db.collection("auditLogs").doc(), {
    action: "user_unfollowed",
    actorId: uid,
    targetType: "user",
    targetId: targetUid,
    timestamp: FieldValue.serverTimestamp(),
  });

  await batch.commit();

  functions.logger.info(`User ${uid} unfollowed ${targetUid}`);
  return { success: true };
});

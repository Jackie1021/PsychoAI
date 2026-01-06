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
exports.unfollowUser = exports.followUser = exports.unblockUser = exports.blockUser = exports.updateUserActivity = exports.onUserCreated = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
const firestore_1 = require("firebase-admin/firestore");
/**
 * Triggered when a new user is created via Firebase Auth.
 * Automatically creates a user profile document in Firestore.
 */
exports.onUserCreated = functions.auth.user().onCreate(async (user) => {
    const db = admin_1.admin.firestore();
    const userProfile = {
        uid: user.uid,
        username: user.displayName || user.email?.split("@")[0] || "User",
        avatarUrl: user.photoURL || "",
        bio: "",
        traits: [],
        freeText: "",
        lastActive: firestore_1.FieldValue.serverTimestamp(),
        isSuspended: false,
        reportCount: 0,
        createdAt: firestore_1.FieldValue.serverTimestamp(),
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
    }
    catch (error) {
        functions.logger.error("Error creating user profile:", error);
        throw error;
    }
});
/**
 * Updates the last active timestamp for a user.
 * Called by the client when user performs actions.
 */
exports.updateUserActivity = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const db = admin_1.admin.firestore();
    const uid = context.auth.uid;
    try {
        await db.collection("users").doc(uid).update({
            lastActive: firestore_1.FieldValue.serverTimestamp(),
        });
        return { success: true };
    }
    catch (error) {
        functions.logger.error("Error updating user activity:", error);
        throw new functions.https.HttpsError("internal", "Failed to update activity");
    }
});
/**
 * Blocks another user. Blocked users won't appear in feeds or matches.
 */
exports.blockUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { blockedUid } = data;
    if (!blockedUid) {
        throw new functions.https.HttpsError("invalid-argument", "blockedUid is required");
    }
    const db = admin_1.admin.firestore();
    const uid = context.auth.uid;
    if (uid === blockedUid) {
        throw new functions.https.HttpsError("invalid-argument", "Cannot block yourself");
    }
    try {
        await db
            .collection("users")
            .doc(uid)
            .collection("blocks")
            .doc(blockedUid)
            .set({
            blockedAt: firestore_1.FieldValue.serverTimestamp(),
        });
        // Create audit log
        await db.collection("auditLogs").add({
            action: "user_blocked",
            actorId: uid,
            targetType: "user",
            targetId: blockedUid,
            timestamp: firestore_1.FieldValue.serverTimestamp(),
        });
        functions.logger.info(`User ${uid} blocked ${blockedUid}`);
        return { success: true, message: "User blocked successfully" };
    }
    catch (error) {
        functions.logger.error("Error blocking user:", error);
        throw new functions.https.HttpsError("internal", "Failed to block user");
    }
});
/**
 * Unblocks a previously blocked user.
 */
exports.unblockUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { blockedUid } = data;
    if (!blockedUid) {
        throw new functions.https.HttpsError("invalid-argument", "blockedUid is required");
    }
    const db = admin_1.admin.firestore();
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
    }
    catch (error) {
        functions.logger.error("Error unblocking user:", error);
        throw new functions.https.HttpsError("internal", "Failed to unblock user");
    }
});
/**
 * Follows another user. Updates both follower and following collections and counters.
 */
exports.followUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { targetUid } = data;
    if (!targetUid) {
        throw new functions.https.HttpsError("invalid-argument", "targetUid is required");
    }
    const db = admin_1.admin.firestore();
    const uid = context.auth.uid;
    if (uid === targetUid) {
        throw new functions.https.HttpsError("invalid-argument", "Cannot follow yourself");
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
    batch.set(currentUserRef.collection("following").doc(targetUid), {
        followedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    batch.set(targetUserRef.collection("followers").doc(uid), {
        followedAt: firestore_1.FieldValue.serverTimestamp(),
    });
    batch.update(currentUserRef, {
        followedBloggerIds: firestore_1.FieldValue.arrayUnion(targetUid),
        followingCount: firestore_1.FieldValue.increment(1),
    });
    batch.update(targetUserRef, {
        followersCount: firestore_1.FieldValue.increment(1),
    });
    batch.set(db.collection("auditLogs").doc(), {
        action: "user_followed",
        actorId: uid,
        targetType: "user",
        targetId: targetUid,
        timestamp: firestore_1.FieldValue.serverTimestamp(),
    });
    await batch.commit();
    functions.logger.info(`User ${uid} followed ${targetUid}`);
    return { success: true };
});
/**
 * Unfollows a previously followed user.
 */
exports.unfollowUser = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { targetUid } = data;
    if (!targetUid) {
        throw new functions.https.HttpsError("invalid-argument", "targetUid is required");
    }
    const db = admin_1.admin.firestore();
    const uid = context.auth.uid;
    if (uid === targetUid) {
        throw new functions.https.HttpsError("invalid-argument", "Cannot unfollow yourself");
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
        followedBloggerIds: firestore_1.FieldValue.arrayRemove(targetUid),
        followingCount: firestore_1.FieldValue.increment(-1),
    });
    batch.update(targetUserRef, {
        followersCount: firestore_1.FieldValue.increment(-1),
    });
    batch.set(db.collection("auditLogs").doc(), {
        action: "user_unfollowed",
        actorId: uid,
        targetType: "user",
        targetId: targetUid,
        timestamp: firestore_1.FieldValue.serverTimestamp(),
    });
    await batch.commit();
    functions.logger.info(`User ${uid} unfollowed ${targetUid}`);
    return { success: true };
});
//# sourceMappingURL=user_handler.js.map
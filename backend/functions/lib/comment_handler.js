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
exports.onCommentDeleted = exports.onCommentCreated = exports.likeComment = void 0;
const functions = __importStar(require("firebase-functions"));
const admin_1 = require("./admin");
const firestore_1 = require("firebase-admin/firestore");
/**
 * Likes or unlikes a comment
 */
exports.likeComment = functions.https.onCall(async (data, context) => {
    if (!context.auth) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }
    const { postId, commentId } = data;
    if (!postId || !commentId) {
        throw new functions.https.HttpsError("invalid-argument", "postId and commentId are required");
    }
    const db = admin_1.admin.firestore();
    const uid = context.auth.uid;
    try {
        const commentRef = db
            .collection("posts")
            .doc(postId)
            .collection("comments")
            .doc(commentId);
        const likeRef = commentRef.collection("likes").doc(uid);
        const likeDoc = await likeRef.get();
        if (likeDoc.exists) {
            // Unlike
            await Promise.all([
                likeRef.delete(),
                commentRef.update({
                    likeCount: firestore_1.FieldValue.increment(-1),
                }),
            ]);
            return { success: true, liked: false };
        }
        else {
            // Like
            await Promise.all([
                likeRef.set({
                    likedAt: firestore_1.FieldValue.serverTimestamp(),
                }),
                commentRef.update({
                    likeCount: firestore_1.FieldValue.increment(1),
                }),
            ]);
            return { success: true, liked: true };
        }
    }
    catch (error) {
        functions.logger.error("Error liking comment:", error);
        throw new functions.https.HttpsError("internal", "Failed to like comment");
    }
});
/**
 * Triggered when a comment is created
 * Updates counters and handles reply relationships
 */
exports.onCommentCreated = functions.firestore
    .document("posts/{postId}/comments/{commentId}")
    .onCreate(async (snap, context) => {
    const db = admin_1.admin.firestore();
    const postId = context.params.postId;
    const commentData = snap.data();
    try {
        // Update post comment count
        await db
            .collection("posts")
            .doc(postId)
            .update({
            commentCount: firestore_1.FieldValue.increment(1),
        });
        // If it's a reply, update parent comment's reply count
        if (commentData.parentCommentId) {
            await db
                .collection("posts")
                .doc(postId)
                .collection("comments")
                .doc(commentData.parentCommentId)
                .update({
                replyCount: firestore_1.FieldValue.increment(1),
            });
        }
        functions.logger.info(`Comment created on post ${postId}, counts updated`);
    }
    catch (error) {
        functions.logger.error("Error in onCommentCreated:", error);
    }
});
/**
 * Triggered when a comment is deleted
 * Updates counters
 */
exports.onCommentDeleted = functions.firestore
    .document("posts/{postId}/comments/{commentId}")
    .onDelete(async (snap, context) => {
    const db = admin_1.admin.firestore();
    const postId = context.params.postId;
    const commentData = snap.data();
    try {
        // Update post comment count
        await db
            .collection("posts")
            .doc(postId)
            .update({
            commentCount: firestore_1.FieldValue.increment(-1),
        });
        // If it was a reply, update parent comment's reply count
        if (commentData.parentCommentId) {
            await db
                .collection("posts")
                .doc(postId)
                .collection("comments")
                .doc(commentData.parentCommentId)
                .update({
                replyCount: firestore_1.FieldValue.increment(-1),
            });
        }
        // Delete all likes for this comment
        const likesSnapshot = await db
            .collection("posts")
            .doc(postId)
            .collection("comments")
            .doc(context.params.commentId)
            .collection("likes")
            .get();
        const batch = db.batch();
        likesSnapshot.docs.forEach((doc) => {
            batch.delete(doc.ref);
        });
        await batch.commit();
        functions.logger.info(`Comment deleted from post ${postId}, counts updated`);
    }
    catch (error) {
        functions.logger.error("Error in onCommentDeleted:", error);
    }
});
//# sourceMappingURL=comment_handler.js.map
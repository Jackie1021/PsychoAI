import * as functions from "firebase-functions";
import { admin } from "./admin";
import { FieldValue } from "firebase-admin/firestore";

/**
 * Likes or unlikes a comment
 */
export const likeComment = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { postId, commentId } = data;
  if (!postId || !commentId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "postId and commentId are required"
    );
  }

  const db = admin.firestore();
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
          likeCount: FieldValue.increment(-1),
        }),
      ]);

      return { success: true, liked: false };
    } else {
      // Like
      await Promise.all([
        likeRef.set({
          likedAt: FieldValue.serverTimestamp(),
        }),
        commentRef.update({
          likeCount: FieldValue.increment(1),
        }),
      ]);

      return { success: true, liked: true };
    }
  } catch (error) {
    functions.logger.error("Error liking comment:", error);
    throw new functions.https.HttpsError("internal", "Failed to like comment");
  }
});

/**
 * Triggered when a comment is created
 * Updates counters and handles reply relationships
 */
export const onCommentCreated = functions.firestore
  .document("posts/{postId}/comments/{commentId}")
  .onCreate(async (snap, context) => {
    const db = admin.firestore();
    const postId = context.params.postId;
    const commentData = snap.data();

    try {
      // Update post comment count
      await db
        .collection("posts")
        .doc(postId)
        .update({
          commentCount: FieldValue.increment(1),
        });

      // If it's a reply, update parent comment's reply count
      if (commentData.parentCommentId) {
        await db
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc(commentData.parentCommentId)
          .update({
            replyCount: FieldValue.increment(1),
          });
      }

      functions.logger.info(
        `Comment created on post ${postId}, counts updated`
      );
    } catch (error) {
      functions.logger.error("Error in onCommentCreated:", error);
    }
  });

/**
 * Triggered when a comment is deleted
 * Updates counters
 */
export const onCommentDeleted = functions.firestore
  .document("posts/{postId}/comments/{commentId}")
  .onDelete(async (snap, context) => {
    const db = admin.firestore();
    const postId = context.params.postId;
    const commentData = snap.data();

    try {
      // Update post comment count
      await db
        .collection("posts")
        .doc(postId)
        .update({
          commentCount: FieldValue.increment(-1),
        });

      // If it was a reply, update parent comment's reply count
      if (commentData.parentCommentId) {
        await db
          .collection("posts")
          .doc(postId)
          .collection("comments")
          .doc(commentData.parentCommentId)
          .update({
            replyCount: FieldValue.increment(-1),
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

      functions.logger.info(
        `Comment deleted from post ${postId}, counts updated`
      );
    } catch (error) {
      functions.logger.error("Error in onCommentDeleted:", error);
    }
  });

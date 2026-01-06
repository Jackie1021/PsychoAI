import * as functions from "firebase-functions";
import { admin, db as sharedDb } from "./admin";
import { FieldValue, FieldPath } from "firebase-admin/firestore";

interface PostData {
  userId: string;
  text: string;
  media: string[];
  mediaType: string;
  createdAt: FieldValue;
  status: "visible" | "hidden" | "removed";
  reportCount: number;
  likeCount: number;
  commentCount: number;
  favoriteCount: number;
  isPublic: boolean;
}

/**
 * Ensures user document exists, creates one if not.
 */
async function ensureUserDocument(
  uid: string,
  displayName?: string,
  photoURL?: string,
  email?: string
): Promise<void> {
  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const userDoc = await userRef.get();

  if (!userDoc.exists) {
    const userProfile = {
      uid,
      username: displayName || email?.split("@")[0] || "User",
      avatarUrl: photoURL || "",
      bio: "",
      traits: [],
      freeText: "",
      email: email || "",
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
      privacy: {
        visibility: "public",
      },
    };

    await userRef.set(userProfile);
    functions.logger.info(`✅ User profile created for ${uid}`);
  }
}

/**
 * Creates a new post.
 */
export const createPost = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated to create posts"
    );
  }

  const { text, media, mediaType } = data;
  const isPublic = data.isPublic !== false;
  const hasMedia = Array.isArray(media) && media.length > 0;
  const hasText = typeof text === "string" && text.trim().length > 0;

  if (!hasText && !hasMedia) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Post must include text or media"
    );
  }

  if (hasText && text.length > 5000) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Post text too long (max 5000 characters)"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  try {
    // Ensure user document exists
    await ensureUserDocument(
      uid,
      context.auth.token?.name,
      context.auth.token?.picture,
      context.auth.token?.email
    );

    // Check if user is suspended
    const userRef = db.collection("users").doc(uid);
    const userDoc = await userRef.get();
    
    if (userDoc.data()?.isSuspended) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Your account is suspended"
      );
    }

    const postData: PostData = {
      userId: uid,
      text: hasText ? text.trim() : "",
      media: hasMedia ? media : [],
      mediaType: mediaType || (hasMedia ? "image" : "text"),
      createdAt: FieldValue.serverTimestamp(),
      status: "visible",
      reportCount: 0,
      likeCount: 0,
      commentCount: 0,
      favoriteCount: 0,
      isPublic,
    };

    const postRef = await db.collection("posts").add(postData);
    functions.logger.info(`✅ Post created: ${postRef.id} by user ${uid}`);

    // Update user post count
    await userRef.update({
      postsCount: FieldValue.increment(1),
      lastActive: FieldValue.serverTimestamp(),
    });

    return {
      success: true,
      postId: postRef.id,
      message: "Post created successfully",
    };
  } catch (error) {
    functions.logger.error("❌ Error creating post:", error);
    
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }

    const message = error instanceof Error ? error.message : "Unknown error";
    functions.logger.error(`❌ Post creation failed for user ${uid}: ${message}`);

    throw new functions.https.HttpsError(
      "internal",
      `Failed to create post: ${message}`
    );
  }
});

/**
 * Deletes a post (soft delete by setting status to 'removed').
 */
export const deletePost = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { postId } = data;
  if (!postId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "postId is required"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  try {
    const postRef = db.collection("posts").doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Post not found");
    }

    const postData = postDoc.data();
    if (postData?.userId !== uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You can only delete your own posts"
      );
    }

    // Soft delete
    await postRef.update({
      status: "removed",
    });

    functions.logger.info(`Post ${postId} deleted by user ${uid}`);

    return { success: true, message: "Post deleted successfully" };
  } catch (error) {
    functions.logger.error("Error deleting post:", error);
    throw new functions.https.HttpsError("internal", "Failed to delete post");
  }
});

/**
 * Likes or unlikes a post.
 */
export const likePost = functions.https.onCall(async (data, context) => {
  functions.logger.info('❤️ likePost called', { postId: data.postId, authUid: context.auth?.uid });
  
  if (!context.auth) {
    functions.logger.error('❌ likePost: User not authenticated');
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { postId } = data;
  if (!postId) {
    functions.logger.error('❌ likePost: postId is required');
    throw new functions.https.HttpsError(
      "invalid-argument",
      "postId is required"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;
  functions.logger.info('👤 likePost: Processing', { postId, uid });

  try {
    const likeRef = db
      .collection("posts")
      .doc(postId)
      .collection("likes")
      .doc(uid);

    const userLikeRef = db
      .collection("users")
      .doc(uid)
      .collection("likes")
      .doc(postId);

    const userDocRef = db.collection("users").doc(uid);

    const likeDoc = await likeRef.get();
    const isCurrentlyLiked = likeDoc.exists;
    
    functions.logger.info('🔍 likePost: Current state', { 
      postId, 
      uid, 
      isCurrentlyLiked,
      action: isCurrentlyLiked ? 'Unlike' : 'Like'
    });

    if (isCurrentlyLiked) {
      // Unlike
      functions.logger.info('🔄 likePost: Unliking post...');
      await Promise.all([
        likeRef.delete(),
        userLikeRef.delete(),
        db
          .collection("posts")
          .doc(postId)
          .update({
            likeCount: FieldValue.increment(-1),
        }),
        userDocRef.set(
          {
            likedPostIds: FieldValue.arrayRemove(postId),
            lastActive: FieldValue.serverTimestamp(),
          },
          { merge: true }
        ),
      ]);

      functions.logger.info('✅ likePost: Successfully unliked', { postId, uid });
      return { success: true, liked: false };
    } else {
      // Like
      functions.logger.info('🔄 likePost: Liking post...');
      await Promise.all([
        likeRef.set({
          likedAt: FieldValue.serverTimestamp(),
        }),
        userLikeRef.set({
          likedAt: FieldValue.serverTimestamp(),
        }),
        db
          .collection("posts")
          .doc(postId)
          .update({
            likeCount: FieldValue.increment(1),
          }),
        userDocRef.set(
          {
            likedPostIds: FieldValue.arrayUnion(postId),
            lastActive: FieldValue.serverTimestamp(),
          },
          { merge: true }
        ),
      ]);

      functions.logger.info('✅ likePost: Successfully liked', { postId, uid });
      return { success: true, liked: true };
    }
  } catch (error) {
    functions.logger.error("❌ likePost: Error", { 
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
      postId,
      uid 
    });
    throw new functions.https.HttpsError("internal", "Failed to like post");
  }
});

/**
 * Favorites or unfavorites a post.
 */
export const toggleFavoritePost = functions.https.onCall(async (data, context) => {
  functions.logger.info('⭐ toggleFavoritePost called', { postId: data.postId, authUid: context.auth?.uid });
  
  if (!context.auth) {
    functions.logger.error('❌ toggleFavoritePost: User not authenticated');
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { postId } = data;
  if (!postId) {
    functions.logger.error('❌ toggleFavoritePost: postId is required');
    throw new functions.https.HttpsError(
      "invalid-argument",
      "postId is required"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;
  functions.logger.info('👤 toggleFavoritePost: Processing', { postId, uid });

  try {
    const postRef = db.collection("posts").doc(postId);
    const favoriteRef = postRef.collection("favorites").doc(uid);
    const userFavoriteRef = db
      .collection("users")
      .doc(uid)
      .collection("favorites")
      .doc(postId);
    const userDocRef = db.collection("users").doc(uid);

    const favoriteDoc = await favoriteRef.get();
    const isCurrentlyFavorited = favoriteDoc.exists;
    
    functions.logger.info('🔍 toggleFavoritePost: Current state', { 
      postId, 
      uid, 
      isCurrentlyFavorited,
      action: isCurrentlyFavorited ? 'Unfavorite' : 'Favorite'
    });

    if (isCurrentlyFavorited) {
      functions.logger.info('🔄 toggleFavoritePost: Unfavoriting post...');
      await Promise.all([
        favoriteRef.delete(),
        userFavoriteRef.delete(),
        postRef.update({
          favoriteCount: FieldValue.increment(-1),
        }),
        userDocRef.set(
          {
            favoritedPostIds: FieldValue.arrayRemove(postId),
            lastActive: FieldValue.serverTimestamp(),
          },
          { merge: true }
        ),
      ]);

      functions.logger.info('✅ toggleFavoritePost: Successfully unfavorited', { postId, uid });
      return { success: true, favorited: false };
    }

    functions.logger.info('🔄 toggleFavoritePost: Favoriting post...');
    await Promise.all([
      favoriteRef.set({
        favoritedAt: FieldValue.serverTimestamp(),
      }),
      userFavoriteRef.set({
        favoritedAt: FieldValue.serverTimestamp(),
      }),
      postRef.update({
        favoriteCount: FieldValue.increment(1),
      }),
      userDocRef.set(
        {
          favoritedPostIds: FieldValue.arrayUnion(postId),
          lastActive: FieldValue.serverTimestamp(),
        },
        { merge: true }
      ),
    ]);

    functions.logger.info('✅ toggleFavoritePost: Successfully favorited', { postId, uid });
    return { success: true, favorited: true };
  } catch (error) {
    functions.logger.error("❌ toggleFavoritePost: Error", { 
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
      postId,
      uid 
    });
    throw new functions.https.HttpsError(
      "internal",
      "Failed to toggle favorite"
    );
  }
});

/**
 * Updates a post (only the owner can update).
 */
export const updatePost = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { postId, text, isPublic } = data;
  if (!postId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "postId is required"
    );
  }

  const db = admin.firestore();
  const uid = context.auth.uid;

  try {
    const postRef = db.collection("posts").doc(postId);
    const postDoc = await postRef.get();

    if (!postDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Post not found");
    }

    const postData = postDoc.data();
    if (postData?.userId !== uid) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You can only update your own posts"
      );
    }

    const updates: any = {
      updatedAt: FieldValue.serverTimestamp(),
    };

    if (text !== undefined) {
      if (text.length > 5000) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Post text too long (max 5000 characters)"
        );
      }
      updates.text = text.trim();
    }

    if (isPublic !== undefined) {
      updates.isPublic = isPublic;
    }

    await postRef.update(updates);

    functions.logger.info(`✅ Post ${postId} updated by user ${uid}`);

    return { success: true, message: "Post updated successfully" };
  } catch (error) {
    functions.logger.error("❌ Error updating post:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", "Failed to update post");
  }
});

/**
 * Gets posts liked by a user.
 */
export const getLikedPosts = functions.https.onCall(async (data, context) => {
  functions.logger.info('🔵 getLikedPosts called', { userId: data.userId, authUid: context.auth?.uid });
  
  if (!context.auth) {
    functions.logger.error('❌ getLikedPosts: User not authenticated');
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const { userId } = data;
  const targetUserId = userId || context.auth.uid;
  functions.logger.info('👤 getLikedPosts: Target user ID', { targetUserId });

  const db = sharedDb || admin.firestore();

  try {
    const userDoc = await db.collection("users").doc(targetUserId).get();
    if (!userDoc.exists) {
      functions.logger.warn('⚠️ getLikedPosts: User document not found', { targetUserId });
      return { success: true, posts: [] };
    }

    const userData = userDoc.data();
    const rawLikedPostIds = userData?.likedPostIds || [];
    // Filter out invalid IDs (null, undefined, empty strings)
    const likedPostIds = rawLikedPostIds.filter((id: any) => id && typeof id === 'string' && id.trim().length > 0);
    
    functions.logger.info('📋 getLikedPosts: Found liked posts', { 
      count: likedPostIds.length,
      rawCount: rawLikedPostIds.length,
      postIds: likedPostIds 
    });

    if (likedPostIds.length === 0) {
      functions.logger.info('✅ getLikedPosts: No liked posts found');
      return { success: true, posts: [] };
    }

    // Fetch posts in batches (Firestore 'in' query limit is 10)
    const batchSize = 10;
    const postBatches: any[] = [];

    for (let i = 0; i < likedPostIds.length; i += batchSize) {
      const batch = likedPostIds.slice(i, i + batchSize);
      functions.logger.info(`🔄 getLikedPosts: Fetching batch ${Math.floor(i / batchSize) + 1}`, { 
        batchSize: batch.length,
        postIds: batch 
      });
      
      // Use FieldPath.documentId() from admin module to ensure it's properly initialized
      const snapshot = await db
        .collection("posts")
        .where(FieldPath.documentId(), "in", batch)
        .where("status", "==", "visible")
        .get();

      functions.logger.info(`✅ getLikedPosts: Batch fetched`, { 
        found: snapshot.docs.length,
        expected: batch.length 
      });
      
      postBatches.push(...snapshot.docs);
    }

    const posts = postBatches.map((doc) => ({
      postId: doc.id,
      ...doc.data(),
    }));

    functions.logger.info('✅ getLikedPosts: Returning posts', { 
      totalCount: posts.length,
      postIds: posts.map(p => p.postId)
    });

    return { success: true, posts };
  } catch (error) {
    functions.logger.error("❌ getLikedPosts: Error fetching liked posts", { 
      error: error instanceof Error ? error.message : String(error),
      stack: error instanceof Error ? error.stack : undefined,
      targetUserId 
    });
    throw new functions.https.HttpsError(
      "internal",
      "Failed to fetch liked posts"
    );
  }
});

/**
 * Gets posts favorited by a user.
 */
export const getFavoritedPosts = functions.https.onCall(
  async (data, context) => {
    functions.logger.info('🟡 getFavoritedPosts called', { userId: data.userId, authUid: context.auth?.uid });
    
    if (!context.auth) {
      functions.logger.error('❌ getFavoritedPosts: User not authenticated');
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    const { userId } = data;
    const targetUserId = userId || context.auth.uid;
    functions.logger.info('👤 getFavoritedPosts: Target user ID', { targetUserId });

    const db = sharedDb || admin.firestore();

    try {
      const userDoc = await db.collection("users").doc(targetUserId).get();
      if (!userDoc.exists) {
        functions.logger.warn('⚠️ getFavoritedPosts: User document not found', { targetUserId });
        return { success: true, posts: [] };
      }

      const userData = userDoc.data();
      const rawFavoritedPostIds = userData?.favoritedPostIds || [];
      // Filter out invalid IDs (null, undefined, empty strings)
      const favoritedPostIds = rawFavoritedPostIds.filter((id: any) => id && typeof id === 'string' && id.trim().length > 0);
      
      functions.logger.info('📋 getFavoritedPosts: Found favorited posts', { 
        count: favoritedPostIds.length,
        rawCount: rawFavoritedPostIds.length,
        postIds: favoritedPostIds 
      });

      if (favoritedPostIds.length === 0) {
        functions.logger.info('✅ getFavoritedPosts: No favorited posts found');
        return { success: true, posts: [] };
      }

      const batchSize = 10;
      const postBatches: any[] = [];

      for (let i = 0; i < favoritedPostIds.length; i += batchSize) {
        const batch = favoritedPostIds.slice(i, i + batchSize);
        functions.logger.info(`🔄 getFavoritedPosts: Fetching batch ${Math.floor(i / batchSize) + 1}`, { 
          batchSize: batch.length,
          postIds: batch 
        });
        
        const snapshot = await db
          .collection("posts")
          .where(FieldPath.documentId(), "in", batch)
          .where("status", "==", "visible")
          .get();

        functions.logger.info(`✅ getFavoritedPosts: Batch fetched`, { 
          found: snapshot.docs.length,
          expected: batch.length 
        });

        postBatches.push(...snapshot.docs);
      }

      const posts = postBatches.map((doc) => ({
        postId: doc.id,
        ...doc.data(),
      }));

      functions.logger.info('✅ getFavoritedPosts: Returning posts', { 
        totalCount: posts.length,
        postIds: posts.map(p => p.postId)
      });

      return { success: true, posts };
    } catch (error) {
      functions.logger.error("❌ getFavoritedPosts: Error fetching favorited posts", { 
        error: error instanceof Error ? error.message : String(error),
        stack: error instanceof Error ? error.stack : undefined,
        targetUserId 
      });
      throw new functions.https.HttpsError(
        "internal",
        "Failed to fetch favorited posts"
      );
    }
  }
);

/**
 * Triggered when a post is deleted. Cleans up related data.
 */
export const onPostDeleted = functions.firestore
  .document("posts/{postId}")
  .onDelete(async (snapshot, context) => {
    const db = admin.firestore();
    const postId = context.params.postId;

    try {
      // Delete all likes
      const likesSnapshot = await db
        .collection("posts")
        .doc(postId)
        .collection("likes")
        .get();

      const batch = db.batch();
      likesSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      const favoritesSnapshot = await db
        .collection("posts")
        .doc(postId)
        .collection("favorites")
        .get();

      favoritesSnapshot.docs.forEach((doc) => {
        batch.delete(doc.ref);
      });

      await batch.commit();

      functions.logger.info(`✅ Cleaned up data for deleted post ${postId}`);
    } catch (error) {
      functions.logger.error("❌ Error cleaning up post data:", error);
    }
  });


import * as functions from "firebase-functions";
import { admin } from "./admin";
import { FieldValue } from "firebase-admin/firestore";

// Delayed Firestore instance retrieval
function getDb() {
  return admin.firestore();
}

/**
 * Creates a new conversation between two users
 */
export const createConversation = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { currentUserId, otherUserId, matchId } = data;

  if (!currentUserId || !otherUserId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required user IDs.");
  }

  // Check if conversation already exists
  const existingQuery = await getDb()
    .collection("conversations")
    .where("participantIds", "array-contains", currentUserId)
    .get();

  for (const doc of existingQuery.docs) {
    const convData = doc.data();
    if (convData.participantIds && convData.participantIds.includes(otherUserId)) {
      return { conversationId: doc.id, existed: true };
    }
  }

  // Get user information
  const currentUserDoc = await getDb().collection("users").doc(currentUserId).get();
  const otherUserDoc = await getDb().collection("users").doc(otherUserId).get();

  const currentUserData = currentUserDoc.data() || {};
  const otherUserData = otherUserDoc.data() || {};

  // Create new conversation
  const conversationRef = getDb().collection("conversations").doc();
  const now = FieldValue.serverTimestamp();

  await conversationRef.set({
    id: conversationRef.id,
    participantIds: [currentUserId, otherUserId],
    participantInfo: {
      [currentUserId]: {
        id: currentUserId,
        name: currentUserData.name || "User",
        avatar: currentUserData.avatar || null,
        bio: currentUserData.bio || null,
      },
      [otherUserId]: {
        id: otherUserId,
        name: otherUserData.name || "User",
        avatar: otherUserData.avatar || null,
        bio: otherUserData.bio || null,
      },
    },
    type: matchId ? "match" : "direct",
    status: "active",
    createdAt: now,
    updatedAt: now,
    unreadCount: {
      [currentUserId]: 0,
      [otherUserId]: 0,
    },
    metadata: {
      matchId: matchId || null,
      isFavorited: {
        [currentUserId]: false,
        [otherUserId]: false,
      },
      isPinned: {
        [currentUserId]: false,
        [otherUserId]: false,
      },
      tags: [],
    },
  });

  // Create system message if from match
  if (matchId) {
    await conversationRef.collection("messages").add({
      senderId: "system",
      text: "🎉 You matched! Start your conversation.",
      type: "system",
      status: "sent",
      isDeleted: false,
      reactions: [],
      createdAt: now,
    });
  }

  return { conversationId: conversationRef.id, existed: false };
});

/**
 * Sends a chat message
 */
export const sendMessage = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { conversationId, text, type = "text", mediaUrl, mediaMetadata, replyTo } = data;
  const uid = context.auth.uid;

  if (!conversationId || !text) {
    throw new functions.https.HttpsError("invalid-argument", "Missing required fields.");
  }

  const conversationRef = getDb().collection("conversations").doc(conversationId);
  const messageRef = conversationRef.collection("messages").doc();
  const now = FieldValue.serverTimestamp();

  // Create message
  await messageRef.set({
    id: messageRef.id,
    senderId: uid,
    text: text,
    type: type,
    mediaUrl: mediaUrl || null,
    mediaMetadata: mediaMetadata || null,
    replyTo: replyTo || null,
    status: "sent",
    reactions: [],
    isDeleted: false,
    createdAt: now,
  });

  // Update conversation
  const conversationDoc = await conversationRef.get();
  if (conversationDoc.exists) {
    const convData = conversationDoc.data();
    const unreadCount = convData?.unreadCount || {};

    // Increment unread count for other participants
    const participantIds = convData?.participantIds || [];
    for (const participantId of participantIds) {
      if (participantId !== uid) {
        unreadCount[participantId] = (unreadCount[participantId] || 0) + 1;
      }
    }

    await conversationRef.update({
      lastMessage: {
        text: text,
        senderId: uid,
        timestamp: now,
        type: type,
      },
      updatedAt: now,
      unreadCount: unreadCount,
    });
  }

  return { success: true, messageId: messageRef.id };
});

/**
 * Marks messages as read
 */
export const markMessagesAsRead = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const { conversationId } = data;
  const uid = context.auth.uid;

  if (!conversationId) {
    throw new functions.https.HttpsError("invalid-argument", "Missing conversationId.");
  }

  const conversationRef = getDb().collection("conversations").doc(conversationId);
  
  // Reset unread count for this user
  await conversationRef.update({
    [`unreadCount.${uid}`]: 0,
  });

  return { success: true };
});

/**
 * Gets all conversations for the current user
 */
export const getConversations = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated.");
  }

  const uid = context.auth.uid;
  const conversationsSnapshot = await getDb()
    .collection("conversations")
    .where("participantIds", "array-contains", uid)
    .where("status", "==", "active")
    .orderBy("updatedAt", "desc")
    .get();

  const conversations = conversationsSnapshot.docs.map(doc => ({
    id: doc.id,
    ...doc.data(),
  }));

  return { conversations };
});

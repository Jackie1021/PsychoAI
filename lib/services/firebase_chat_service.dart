import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_app/models/chat_participant.dart';
import 'package:flutter_app/models/conversation.dart';
import 'package:flutter_app/models/message.dart';
import 'package:flutter_app/services/chat_service.dart';

class FirebaseChatService implements ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  @override
  Stream<List<Conversation>> getConversationsStream(String userId) {
    return _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: userId)
        .where('status', isNotEqualTo: ConversationStatus.deleted.name)
        .orderBy('status')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Conversation.fromMap(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<Conversation?> getConversation(String conversationId) async {
    final doc = await _firestore.collection('conversations').doc(conversationId).get();
    if (!doc.exists) return null;
    return Conversation.fromMap(doc.data()!, doc.id);
  }

  @override
  Future<String> createConversation({
    required String currentUserId,
    required String otherUserId,
    String? matchId,
  }) async {
    // Check if conversation already exists
    final existingQuery = await _firestore
        .collection('conversations')
        .where('participantIds', arrayContains: currentUserId)
        .get();

    for (var doc in existingQuery.docs) {
      final conversation = Conversation.fromMap(doc.data(), doc.id);
      if (conversation.participantIds.contains(otherUserId)) {
        return doc.id;
      }
    }

    // Get user info for both participants
    final currentUserDoc = await _firestore.collection('users').doc(currentUserId).get();
    final otherUserDoc = await _firestore.collection('users').doc(otherUserId).get();

    final currentUserData = currentUserDoc.data() ?? {};
    final otherUserData = otherUserDoc.data() ?? {};

    final conversationRef = _firestore.collection('conversations').doc();
    final now = DateTime.now();

    final conversation = Conversation(
      id: conversationRef.id,
      participantIds: [currentUserId, otherUserId],
      participantInfo: {
        currentUserId: ChatParticipant(
          id: currentUserId,
          name: currentUserData['username'] ?? currentUserData['name'] ?? 'User',
          avatar: currentUserData['avatarUrl'] ?? currentUserData['avatar'],
          bio: currentUserData['bio'],
        ),
        otherUserId: ChatParticipant(
          id: otherUserId,
          name: otherUserData['username'] ?? otherUserData['name'] ?? 'User',
          avatar: otherUserData['avatarUrl'] ?? otherUserData['avatar'],
          bio: otherUserData['bio'],
        ),
      },
      type: matchId != null ? ConversationType.match : ConversationType.direct,
      status: ConversationStatus.active,
      createdAt: now,
      updatedAt: now,
      unreadCount: {currentUserId: 0, otherUserId: 0},
      metadata: ConversationMetadata(
        matchId: matchId,
        isFavorited: {currentUserId: false, otherUserId: false},
        isPinned: {currentUserId: false, otherUserId: false},
      ),
    );

    await conversationRef.set(conversation.toMap());

    // Wait for the document to be fully written before creating system message
    // This ensures Firestore rules can properly read the conversation document
    await conversationRef.get();

    // Create system message if from match
    if (matchId != null) {
      // Add a small delay to ensure the document is fully committed
      await Future.delayed(const Duration(milliseconds: 100));
      
      try {
        await sendMessage(
          conversationId: conversationRef.id,
          senderId: 'system',
          text: '🎉 You matched! Start your conversation.',
          type: MessageType.system,
        );
      } catch (e) {
        // If system message creation fails, log but don't fail the conversation creation
        print('⚠️ Failed to create system message: $e');
        // Retry once after a longer delay
        await Future.delayed(const Duration(milliseconds: 500));
        try {
          await sendMessage(
            conversationId: conversationRef.id,
            senderId: 'system',
            text: '🎉 You matched! Start your conversation.',
            type: MessageType.system,
          );
        } catch (retryError) {
          print('⚠️ Retry failed to create system message: $retryError');
        }
      }
    }

    return conversationRef.id;
  }

  @override
  Future<void> updateConversationMetadata(
    String conversationId,
    String userId, {
    bool? isFavorited,
    bool? isPinned,
  }) async {
    final updates = <String, dynamic>{};
    
    if (isFavorited != null) {
      updates['metadata.isFavorited.$userId'] = isFavorited;
    }
    
    if (isPinned != null) {
      updates['metadata.isPinned.$userId'] = isPinned;
    }

    if (updates.isNotEmpty) {
      await _firestore.collection('conversations').doc(conversationId).update(updates);
    }
  }

  @override
  Future<void> deleteConversation(String conversationId, String userId) async {
    // Soft delete: just update status for this user
    await _firestore.collection('conversations').doc(conversationId).update({
      'status': ConversationStatus.deleted.name,
    });
  }

  @override
  Stream<List<Message>> getMessagesStream(String conversationId, {int limit = 50}) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('isDeleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromMap(doc.data(), doc.id))
          .toList()
          .reversed
          .toList();
    });
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
    MessageType type = MessageType.text,
    String? mediaUrl,
    MediaMetadata? mediaMetadata,
    MessageReplyInfo? replyTo,
  }) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc();

    final now = DateTime.now();

    final message = Message(
      id: messageRef.id,
      senderId: senderId,
      text: text,
      type: type,
      mediaUrl: mediaUrl,
      mediaMetadata: mediaMetadata,
      replyTo: replyTo,
      status: MessageStatus.sent,
      createdAt: now,
    );

    await messageRef.set(message.toMap());

    // Update conversation lastMessage and timestamp
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    final conversationDoc = await conversationRef.get();
    
    if (conversationDoc.exists) {
      final conversation = Conversation.fromMap(conversationDoc.data()!, conversationDoc.id);
      
      // Update unread count for other participants
      final updatedUnreadCount = Map<String, int>.from(conversation.unreadCount);
      for (var participantId in conversation.participantIds) {
        if (participantId != senderId) {
          updatedUnreadCount[participantId] = (updatedUnreadCount[participantId] ?? 0) + 1;
        }
      }

      await conversationRef.update({
        'lastMessage': LastMessageSnapshot(
          text: text,
          senderId: senderId,
          timestamp: now,
          type: type.name,
        ).toMap(),
        'updatedAt': Timestamp.fromDate(now),
        'unreadCount': updatedUnreadCount,
      });
    }
  }

  @override
  Future<void> markMessagesAsRead(String conversationId, String userId) async {
    final conversationRef = _firestore.collection('conversations').doc(conversationId);
    
    await conversationRef.update({
      'unreadCount.$userId': 0,
    });

    // Update message status to read
    final messagesQuery = await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('status', whereIn: [MessageStatus.sent.name, MessageStatus.delivered.name])
        .get();

    final batch = _firestore.batch();
    for (var doc in messagesQuery.docs) {
      batch.update(doc.reference, {'status': MessageStatus.read.name});
    }
    await batch.commit();
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId)
        .update({
      'isDeleted': true,
      'text': 'This message was deleted',
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Future<void> addReaction(
    String conversationId,
    String messageId,
    String userId,
    String emoji,
  ) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final messageDoc = await messageRef.get();
    if (!messageDoc.exists) return;

    final message = Message.fromMap(messageDoc.data()!, messageDoc.id);
    final reactions = List<MessageReaction>.from(message.reactions);

    // Remove existing reaction from this user
    reactions.removeWhere((r) => r.userId == userId);

    // Add new reaction
    reactions.add(MessageReaction(
      userId: userId,
      emoji: emoji,
      timestamp: DateTime.now(),
    ));

    await messageRef.update({
      'reactions': reactions.map((r) => r.toMap()).toList(),
    });
  }

  @override
  Future<void> removeReaction(
    String conversationId,
    String messageId,
    String userId,
  ) async {
    final messageRef = _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .doc(messageId);

    final messageDoc = await messageRef.get();
    if (!messageDoc.exists) return;

    final message = Message.fromMap(messageDoc.data()!, messageDoc.id);
    final reactions = List<MessageReaction>.from(message.reactions);

    reactions.removeWhere((r) => r.userId == userId);

    await messageRef.update({
      'reactions': reactions.map((r) => r.toMap()).toList(),
    });
  }

  @override
  Future<void> updateUserOnlineStatus(String userId, bool isOnline) async {
    await _firestore.collection('users').doc(userId).update({
      'onlineStatus': isOnline ? 'online' : 'offline',
      'lastSeen': Timestamp.fromDate(DateTime.now()),
    });
  }

  @override
  Stream<bool> getUserOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return false;
      return doc.data()?['onlineStatus'] == 'online';
    });
  }
}

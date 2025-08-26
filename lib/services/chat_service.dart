import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:buzzmate/models/chat_model.dart';
import 'package:buzzmate/models/message_model.dart';
import 'package:buzzmate/services/cache_service.dart';
import 'package:buzzmate/utils/connectivity_utils.dart';

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final CacheService _cacheService = CacheService();
  final ConnectivityUtils _connectivityUtils = ConnectivityUtils();

  final Map<String, StreamSubscription> _activeSubscriptions = {};
  final Map<String, List<MessageModel>> _cachedMessages = {};

  // Initialize chat service
  void initialize() {
    _connectivityUtils.connectionStream.listen((isConnected) {
      if (isConnected) {
        _syncCachedData();
      }
    });
  }

  // -------------------- Chats --------------------

  Stream<List<ChatModel>> getUserChats(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
          final chats = snapshot.docs.map((doc) =>
              ChatModel.fromFirestore(doc.id, doc.data())).toList();

          await _cacheService.cacheUserChats(userId, chats);
          return chats;
        })
        .handleError((_) => _cacheService.getCachedChats(userId));
  }

  Future<String> createChat(List<String> participants) async {
    final existingChatId = await getExistingChat(participants);
    if (existingChatId != null) return existingChatId;

    final chatRef = _firestore.collection('chats').doc();
    final chatData = {
      'id': chatRef.id,
      'participants': participants,
      'lastMessage': '',
      'lastMessageTime': Timestamp.now(),
      'unreadCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'typingUsers': [],
      'isGroup': false,
    };

    await chatRef.set(chatData);
    return chatRef.id;
  }

  Future<String?> getExistingChat(List<String> participants) async {
    final query = await _firestore
        .collection('chats')
        .where('participants', arrayContainsAny: participants)
        .get();

    for (final doc in query.docs) {
      final chatParticipants = List<String>.from(doc['participants']);
      if (chatParticipants.toSet().containsAll(participants) &&
          participants.toSet().containsAll(chatParticipants)) {
        return doc.id;
      }
    }
    return null;
  }

  Future<String> createGroup({
    required String name,
    required String description,
    required List<String> participants,
    required String createdBy,
    String? avatarUrl,
  }) async {
    final chatRef = _firestore.collection('chats').doc();
    final chatData = {
      'id': chatRef.id,
      'name': name,
      'description': description,
      'avatarUrl': avatarUrl,
      'participants': participants,
      'admins': [createdBy],
      'createdBy': createdBy,
      'isGroup': true,
      'lastMessage': '',
      'lastMessageTime': Timestamp.now(),
      'unreadCount': 0,
      'createdAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
      'typingUsers': [],
    };

    await chatRef.set(chatData);
    return chatRef.id;
  }

  // -------------------- Messages --------------------

  Stream<List<MessageModel>> getChatMessages(String chatId,
      {int limit = 50}) {
    _activeSubscriptions[chatId]?.cancel();

    final cachedMessages = _cachedMessages[chatId] ?? [];
    final controller = StreamController<List<MessageModel>>();

    if (cachedMessages.isNotEmpty) {
      controller.add(cachedMessages);
    }

    final subscription = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .asyncMap((snapshot) async {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc.id, doc.data()))
          .toList();

      // fetch replyTo messages
      for (var i = 0; i < messages.length; i++) {
        final msg = messages[i];
        if (msg.replyToMessageId != null) {
          try {
            final replyDoc = await _firestore
                .collection('chats')
                .doc(chatId)
                .collection('messages')
                .doc(msg.replyToMessageId)
                .get();
            if (replyDoc.exists) {
              final replyMessage =
                  MessageModel.fromFirestore(replyDoc.id, replyDoc.data()!);
              messages[i] = msg.copyWith(replyToMessage: replyMessage);
            }
          } catch (_) {}
        }
      }

      _cachedMessages[chatId] = messages;
      _cacheService.cacheChatMessages(chatId, messages);
      return messages;
    }).listen(
      (messages) {
        if (!controller.isClosed) controller.add(messages);
      },
      onError: (_) {
        if (!controller.isClosed) controller.add(cachedMessages);
      },
    );

    _activeSubscriptions[chatId] = subscription;
    subscription.onDone(() {
      if (!controller.isClosed) controller.close();
    });

    return controller.stream;
  }

  Future<void> sendMessage({
    required String chatId,
    required String senderId,
    required String content,
    String type = 'text',
    Duration? disappearAfter,
    String? replyToMessageId,
  }) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc();

    final messageData = {
      'id': messageRef.id,
      'chatId': chatId,
      'senderId': senderId,
      'content': content,
      'type': type,
      'timestamp': Timestamp.now(),
      'read': false,
      'reactions': {},
      'edited': false,
      'replyToMessageId': replyToMessageId,
      'disappearAfter': disappearAfter?.inSeconds,
    };

    if (disappearAfter != null) {
      messageData['expireTime'] =
          Timestamp.fromDate(DateTime.now().add(disappearAfter));
    }

    if (await _connectivityUtils.isConnected()) {
      final batch = _firestore.batch();
      batch.set(messageRef, messageData);
      batch.update(_firestore.collection('chats').doc(chatId), {
        'lastMessage': content,
        'lastMessageTime': Timestamp.now(),
        'lastMessageSenderId': senderId,
        'updatedAt': Timestamp.now(),
      });
      await batch.commit();
    } else {
      await _cacheService.cachePendingMessage(chatId, messageData);
    }
  }

  Future<void> replyToMessage({
    required String chatId,
    required String senderId,
    required String content,
    required String replyToMessageId,
  }) async {
    await sendMessage(
      chatId: chatId,
      senderId: senderId,
      content: content,
      replyToMessageId: replyToMessageId,
    );
  }

  Future<void> editMessage(
      String chatId, String messageId, String newContent) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .update({
      'content': newContent,
      'edited': true,
      'editedAt': Timestamp.now(),
    });
  }

  Future<void> deleteMessageForEveryone(
      String chatId, String messageId) async {
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId)
        .delete();
  }

  Future<void> deleteMessageForMe(
      String chatId, String messageId, String userId) async {
    await _cacheService.cacheDeletedMessage(chatId, messageId, userId);
  }

  // -------------------- Reactions --------------------

  Future<void> reactToMessage(
      String chatId, String messageId, String userId, String emoji) async {
    final messageRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);

    final doc = await messageRef.get();
    if (!doc.exists) return;

    final reactions =
        Map<String, dynamic>.from(doc.data()!['reactions'] ?? {});
    final userReactions =
        reactions.entries.where((e) => (e.value as List).contains(userId));

    // remove old reactions
    for (var entry in userReactions) {
      reactions[entry.key] =
          (List<String>.from(entry.value)..remove(userId));
      if ((reactions[entry.key] as List).isEmpty) {
        reactions.remove(entry.key);
      }
    }

    // add new reaction
    reactions[emoji] = (List<String>.from(reactions[emoji] ?? [])
      ..add(userId));

    await messageRef.update({'reactions': reactions});
  }

  Future<void> removeReaction(
      String chatId, String messageId, String userId, String emoji) async {
    final ref = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .doc(messageId);
    await ref.update({
      'reactions.$emoji': FieldValue.arrayRemove([userId]),
    });
  }

  // -------------------- Typing --------------------

  Stream<List<String>> getTypingUsers(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.id).toList());
  }

  Future<void> updateTypingStatus(
      String chatId, String userId, bool isTyping) async {
    final typingRef = _firestore
        .collection('chats')
        .doc(chatId)
        .collection('typing')
        .doc(userId);

    if (isTyping) {
      await typingRef.set({'timestamp': Timestamp.now()});
    } else {
      await typingRef.delete();
    }
  }

  // -------------------- Read receipts --------------------

  Future<void> markMessagesAsRead(String chatId, String userId) async {
    final unread = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('senderId', isNotEqualTo: userId)
        .where('read', isEqualTo: false)
        .get();

    if (unread.docs.isEmpty) return;

    final batch = _firestore.batch();
    for (var doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();

    await _firestore.collection('chats').doc(chatId).update({
      'unreadCount': FieldValue.increment(-unread.docs.length),
    });
  }

  // -------------------- Search --------------------

  Future<List<MessageModel>> searchInChat(
      String chatId, String query) async {
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('content', isGreaterThanOrEqualTo: query)
        .where('content', isLessThan: query + 'z')
        .get();

    return messages.docs
        .map((doc) => MessageModel.fromFirestore(doc.id, doc.data()))
        .toList();
  }

  Future<List<MessageModel>> globalSearch(
      String userId, String query) async {
    final chats = await _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .get();

    final results = <MessageModel>[];
    for (final chat in chats.docs) {
      results.addAll(await searchInChat(chat.id, query));
    }
    return results;
  }

  // -------------------- Scheduled Messages --------------------

  Future<List<Map<String, dynamic>>> getScheduledMessages(
      String userId) async {
    final query = await _firestore
        .collection('scheduled_messages')
        .where('senderId', isEqualTo: userId)
        .where('isSent', isEqualTo: false)
        .get();

    return query.docs.map((doc) {
      final data = doc.data();
      return {
        'id': doc.id,
        ...data,
        'scheduledTime': (data['scheduledTime'] as Timestamp).toDate(),
        'createdAt': (data['createdAt'] as Timestamp).toDate(),
      };
    }).toList();
  }

  Future<void> updateScheduledMessage(
      String messageId, Map<String, dynamic> updates) async {
    if (updates.containsKey('scheduledTime')) {
      updates['scheduledTime'] =
          Timestamp.fromDate(updates['scheduledTime']);
    }
    await _firestore
        .collection('scheduled_messages')
        .doc(messageId)
        .update(updates);
  }

  Future<void> deleteScheduledMessage(String messageId) async {
    await _firestore
        .collection('scheduled_messages')
        .doc(messageId)
        .delete();
  }

  Future<void> scheduleMessage({
    required String senderId,
    required List<String> recipientIds,
    required String content,
    required DateTime scheduledTime,
    String type = 'text',
  }) async {
    await _firestore.collection('scheduled_messages').add({
      'senderId': senderId,
      'recipientIds': recipientIds,
      'content': content,
      'type': type,
      'scheduledTime': Timestamp.fromDate(scheduledTime),
      'isSent': false,
      'createdAt': Timestamp.now(),
    });
  }

  // -------------------- Helpers --------------------

  Future<void> _syncCachedData() async {
    final pending = await _cacheService.getPendingMessages();
    for (final entry in pending.entries) {
      for (final msg in entry.value) {
        await sendMessage(
          chatId: entry.key,
          senderId: msg['senderId'],
          content: msg['content'],
          type: msg['type'] ?? 'text',
        );
      }
    }
    await _cacheService.clearPendingMessages();
  }

  void dispose() {
    for (final sub in _activeSubscriptions.values) {
      sub.cancel();
    }
    _activeSubscriptions.clear();
    _cachedMessages.clear();
  }
}

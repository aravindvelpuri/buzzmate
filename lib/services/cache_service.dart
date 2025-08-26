import 'package:hive/hive.dart';
import 'package:buzzmate/models/chat_model.dart';
import 'package:buzzmate/models/message_model.dart';
import 'package:buzzmate/models/scheduled_message_model.dart';

class CacheService {
  static const String _chatBox = 'user_chats';
  static const String _messageBox = 'chat_messages';
  static const String _pendingBox = 'pending_messages';
  static const String _deletedBox = 'deleted_messages';
  static const String _scheduledBox = 'scheduled_messages';
  static const String _settingsBox = 'user_settings';

  Future<Box> _openBox(String name) async {
    return await Hive.openBox(name);
  }

  // Cache user chats
  Future<void> cacheUserChats(String userId, List<ChatModel> chats) async {
    final box = await _openBox(_chatBox);
    await box.put(userId, chats.map((chat) => chat.toJson()).toList());
  }

  // Get cached chats
  Future<List<ChatModel>> getCachedChats(String userId) async {
    try {
      final box = await _openBox(_chatBox);
      final cachedData = box.get(userId, defaultValue: []) as List;
      return cachedData.map((data) => ChatModel.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Cache chat messages
  Future<void> cacheChatMessages(String chatId, List<MessageModel> messages) async {
    final box = await _openBox(_messageBox);
    // Store only last 100 messages per chat
    final limitedMessages = messages.take(100).toList();
    await box.put(chatId, limitedMessages.map((msg) => msg.toJson()).toList());
  }

  // Get cached messages
  Future<List<MessageModel>> getCachedMessages(String chatId) async {
    try {
      final box = await _openBox(_messageBox);
      final cachedData = box.get(chatId, defaultValue: []) as List;
      return cachedData.map((data) => MessageModel.fromJson(data as Map<String, dynamic>)).toList();
    } catch (e) {
      return [];
    }
  }

  // Cache pending messages for offline sync
  Future<void> cachePendingMessage(String chatId, Map<String, dynamic> message) async {
    final box = await _openBox(_pendingBox);
    final pendingMessages = box.get(chatId, defaultValue: []) as List;
    pendingMessages.add(message);
    await box.put(chatId, pendingMessages);
  }

  // Get all pending messages
  Future<Map<String, List<Map<String, dynamic>>>> getPendingMessages() async {
    final box = await _openBox(_pendingBox);
    final allData = box.toMap();
    return Map<String, List<Map<String, dynamic>>>.from(allData);
  }

  // Clear pending messages after sync
  Future<void> clearPendingMessages() async {
    final box = await _openBox(_pendingBox);
    await box.clear();
  }

  // Cache deleted messages (for me)
  Future<void> cacheDeletedMessage(String chatId, String messageId, String userId) async {
    final box = await _openBox(_deletedBox);
    final key = '$chatId-$userId';
    final deletedMessages = box.get(key, defaultValue: []) as List;
    deletedMessages.add(messageId);
    await box.put(key, deletedMessages);
  }

  // Get deleted messages for user
  Future<List<String>> getDeletedMessages(String chatId, String userId) async {
    final box = await _openBox(_deletedBox);
    final key = '$chatId-$userId';
    return List<String>.from(box.get(key, defaultValue: []));
  }

  // Cache scheduled messages
  Future<void> cacheScheduledMessage(ScheduledMessageModel message) async {
    final box = await _openBox(_scheduledBox);
    await box.put(message.id, message.toJson());
  }

  // Get scheduled messages
  Future<List<ScheduledMessageModel>> getScheduledMessages() async {
    final box = await _openBox(_scheduledBox);
    final allData = box.values.toList();
    return allData.map((data) => ScheduledMessageModel.fromJson(data as Map<String, dynamic>)).toList();
  }

  // Remove scheduled message
  Future<void> removeScheduledMessage(String messageId) async {
    final box = await _openBox(_scheduledBox);
    await box.delete(messageId);
  }

  // Cache user settings
  Future<void> cacheUserSettings(String userId, Map<String, dynamic> settings) async {
    final box = await _openBox(_settingsBox);
    await box.put(userId, settings);
  }

  // Get user settings
  Future<Map<String, dynamic>> getUserSettings(String userId) async {
    final box = await _openBox(_settingsBox);
    return Map<String, dynamic>.from(box.get(userId, defaultValue: {}));
  }

  // Clear all cache
  Future<void> clearAllCache() async {
    final boxes = [_chatBox, _messageBox, _pendingBox, _deletedBox, _scheduledBox, _settingsBox];
    for (final boxName in boxes) {
      final box = await _openBox(boxName);
      await box.clear();
    }
  }
}
// ignore_for_file: depend_on_referenced_packages

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart'; // ✅ Added for DateFormat

class FileUtils {
  static Future<File> writeToFile(String content, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/$fileName');
    await file.writeAsString(content);
    return file;
  }

  static Future<void> shareFile(File file, String subject) async {
    await Share.shareXFiles([XFile(file.path)], subject: subject);
  }

  static Future<void> exportChat(List<Map<String, dynamic>> messages, String chatName) async {
    final formattedMessages = messages.map((msg) {
      final timestamp = DateFormat('yyyy-MM-dd HH:mm:ss').format(msg['timestamp'].toDate());
      final sender = msg['senderName'] ?? 'Unknown';
      return '[$timestamp] $sender: ${msg['content']}';
    }).join('\n\n');

    final file = await writeToFile(formattedMessages, '${chatName}_chat_export.txt');
    await shareFile(file, 'Chat Export - $chatName');
  }

  static Future<void> clearLocalChat(String chatId) async {
    final directory = await getApplicationDocumentsDirectory();
    final chatFile = File('${directory.path}/chat_$chatId.json');
    if (await chatFile.exists()) {
      await chatFile.delete();
    }
  }
}
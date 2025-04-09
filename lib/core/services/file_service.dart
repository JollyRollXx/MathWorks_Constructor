// lib/core/services/file_service.dart
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';

class FileService {
  static Future<String> getSavePath() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultDir = await getApplicationDocumentsDirectory();
    return prefs.getString('savePath') ?? '${defaultDir.path}/MathWorks';
  }

  static Future<List<File>> loadSavedWorks() async {
    final savePath = await getSavePath();
    final mathWorksDir = Directory(savePath);
    if (await mathWorksDir.exists()) {
      return mathWorksDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.pdf'))
          .toList()
        ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));
    }
    return [];
  }

  static Future<void> saveFile(String fileName, List<int> bytes) async {
    final savePath = await getSavePath();
    final mathWorksDir = Directory(savePath);
    if (!await mathWorksDir.exists()) {
      await mathWorksDir.create(recursive: true);
    }
    final file = File('$savePath/$fileName');
    await file.writeAsBytes(bytes);
  }

  static Future<void> deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
    }
  }

  static Future<void> openFile(String path) async {
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      throw Exception('Не удалось открыть файл: ${result.message}');
    }
  }
}
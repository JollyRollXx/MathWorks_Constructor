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
      // Получаем все PDF-файлы
      final allFiles =
          mathWorksDir
              .listSync()
              .whereType<File>()
              .where((file) => file.path.endsWith('.pdf'))
              .toList();

      // Создаем словарь, где ключом будет базовое имя файла
      Map<String, List<File>> fileGroups = {};

      for (File file in allFiles) {
        final fileName = file.path.split(Platform.pathSeparator).last;
        String baseName = fileName;

        // Удаляем суффиксы для группировки
        if (baseName.endsWith('_variants.pdf')) {
          baseName = baseName.replaceAll('_variants.pdf', '');
        } else if (baseName.endsWith('_Ответы.pdf')) {
          baseName = baseName.replaceAll('_Ответы.pdf', '');
        } else if (baseName.endsWith('_answers.pdf')) {
          baseName = baseName.replaceAll('_answers.pdf', '');
        } else if (baseName.endsWith('.pdf')) {
          baseName = baseName.replaceAll('.pdf', '');
        }

        // Добавляем файл в соответствующую группу
        if (!fileGroups.containsKey(baseName)) {
          fileGroups[baseName] = [];
        }
        fileGroups[baseName]!.add(file);
      }

      // Собираем список, отдавая приоритет файлам заданий
      List<File> result = [];
      fileGroups.forEach((baseName, files) {
        // Сортируем файлы так, чтобы файл заданий был первым
        files.sort((a, b) {
          final aName = a.path.split(Platform.pathSeparator).last;
          final bName = b.path.split(Platform.pathSeparator).last;

          if (aName.contains('_variants') && !bName.contains('_variants')) {
            return -1;
          } else if (!aName.contains('_variants') &&
              bName.contains('_variants')) {
            return 1;
          }
          return 0;
        });

        // Добавляем только первый файл из группы в результат
        if (files.isNotEmpty) {
          result.add(files.first);
        }
      });

      // Сортируем по дате последнего изменения (новые сверху)
      result.sort(
        (a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()),
      );
      return result;
    }
    return [];
  }

  // Получает все связанные файлы для данного файла
  static Future<List<File>> getRelatedFiles(File file) async {
    final savePath = await getSavePath();
    final fileName = file.path.split(Platform.pathSeparator).last;
    String baseName = fileName;

    // Удаляем суффиксы для нахождения базового имени
    if (baseName.endsWith('_variants.pdf')) {
      baseName = baseName.replaceAll('_variants.pdf', '');
    } else if (baseName.endsWith('_Ответы.pdf')) {
      baseName = baseName.replaceAll('_Ответы.pdf', '');
    } else if (baseName.endsWith('_answers.pdf')) {
      baseName = baseName.replaceAll('_answers.pdf', '');
    } else if (baseName.endsWith('.pdf')) {
      baseName = baseName.replaceAll('.pdf', '');
    }

    final dir = Directory(savePath);
    if (await dir.exists()) {
      return dir.listSync().whereType<File>().where((f) {
        final name = f.path.split(Platform.pathSeparator).last;
        return name.startsWith(baseName) && name.endsWith('.pdf');
      }).toList();
    }
    return [file];
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

  // Удаляет все связанные файлы
  static Future<void> deleteRelatedFiles(File file) async {
    final relatedFiles = await getRelatedFiles(file);
    for (var f in relatedFiles) {
      if (await f.exists()) {
        await f.delete();
      }
    }
  }

  static Future<void> openFile(String path) async {
    final result = await OpenFile.open(path);
    if (result.type != ResultType.done) {
      throw Exception('Не удалось открыть файл: ${result.message}');
    }
  }
}

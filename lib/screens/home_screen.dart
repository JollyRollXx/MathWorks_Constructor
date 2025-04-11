// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import 'dart:io';
import '../core/services/file_service.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<File> _savedWorks = [];
  // Map для хранения информации о наличии ответов для каждого файла
  Map<String, bool> _hasAnswersMap = {};

  @override
  void initState() {
    super.initState();
    _loadSavedWorks();
  }

  Future<void> _loadSavedWorks() async {
    try {
      final files = await FileService.loadSavedWorks();

      // Создаем новую карту для хранения информации о наличии ответов
      Map<String, bool> hasAnswersMap = {};

      // Для каждого файла определяем, есть ли связанный файл с ответами
      for (final file in files) {
        final relatedFiles = await FileService.getRelatedFiles(file);
        final fileName = file.path.split(Platform.pathSeparator).last;
        final baseName = _getBaseName(fileName);

        // Проверяем, есть ли файл с ответами
        bool hasAnswers = relatedFiles.any((f) {
          final name = f.path.split(Platform.pathSeparator).last;
          return name.contains('_Ответы') || name.contains('_answers');
        });

        // Сохраняем информацию в карте
        hasAnswersMap[baseName] = hasAnswers;
      }

      if (mounted) {
        setState(() {
          _savedWorks = files;
          _hasAnswersMap = hasAnswersMap;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке работ: $e')),
        );
      }
    }
  }

  // Вспомогательный метод для получения базового имени файла без расширения и суффиксов
  String _getBaseName(String fileName) {
    if (fileName.endsWith('_variants.pdf')) {
      return fileName.replaceAll('_variants.pdf', '');
    } else if (fileName.endsWith('_Ответы.pdf')) {
      return fileName.replaceAll('_Ответы.pdf', '');
    } else if (fileName.endsWith('_answers.pdf')) {
      return fileName.replaceAll('_answers.pdf', '');
    } else if (fileName.endsWith('.pdf')) {
      return fileName.replaceAll('.pdf', '');
    }
    return fileName;
  }

  Future<void> _openWork(File file) async {
    try {
      // Получаем все связанные файлы
      final relatedFiles = await FileService.getRelatedFiles(file);

      // Сортируем файлы, чтобы задания всегда были первыми в списке
      relatedFiles.sort((a, b) {
        final aName = a.path.split(Platform.pathSeparator).last;
        final bName = b.path.split(Platform.pathSeparator).last;

        final aIsVariants = aName.contains('_variants');
        final bIsVariants = bName.contains('_variants');

        final aIsAnswers =
            aName.contains('_Ответы') || aName.contains('_answers');
        final bIsAnswers =
            bName.contains('_Ответы') || bName.contains('_answers');

        // Задания всегда первые
        if (aIsVariants && !bIsVariants) return -1;
        if (!aIsVariants && bIsVariants) return 1;

        // Если нет заданий, то любые другие файлы перед ответами
        if (aIsAnswers && !bIsAnswers) return 1;
        if (!aIsAnswers && bIsAnswers) return -1;

        return 0;
      });

      // Если есть несколько файлов, показываем диалог выбора
      if (relatedFiles.length > 1 && mounted) {
        final colorScheme = Theme.of(context).colorScheme;

        showDialog(
          context: context,
          builder:
              (context) => Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
                backgroundColor: Colors.transparent,
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 400),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withAlpha(30),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.file_open_rounded,
                            color: colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Выберите файл',
                            style: GoogleFonts.inter(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 60,
                        height: 3,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Доступны следующие файлы:',
                        style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...relatedFiles.map((f) {
                        final name = f.path.split(Platform.pathSeparator).last;
                        final bool isVariants = name.contains('_variants');
                        final bool isAnswers =
                            name.contains('_Ответы') ||
                            name.contains('_answers');

                        IconData fileIcon = Icons.description_outlined;
                        String displayName = name;

                        if (isVariants) {
                          displayName = 'Задания';
                          fileIcon = Icons.assignment_outlined;
                        } else if (isAnswers) {
                          displayName = 'Ответы';
                          fileIcon = Icons.check_circle_outline;
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              FileService.openFile(f.path);
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: _FileOptionCard(
                              title: displayName,
                              icon: fileIcon,
                              isVariants: isVariants,
                              isAnswers: isAnswers,
                              colorScheme: colorScheme,
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Отмена',
                          style: TextStyle(
                            color: colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        );
      } else {
        // Если только один файл, открываем его напрямую
        await FileService.openFile(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при открытии файла: $e')),
        );
      }
    }
  }

  Future<void> _deleteWork(File file) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Удалить работу?'),
            content: const Text(
              'Вы уверены, что хотите удалить эту работу и все связанные файлы?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Отмена'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );

    if (confirm == true && mounted) {
      try {
        // Удаляем все связанные файлы
        await FileService.deleteRelatedFiles(file);
        await _loadSavedWorks();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка при удалении файла: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(16);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;

        return Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? constraints.maxWidth * 0.1 : 16.0,
            vertical: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader('Последние работы', colorScheme),
              const SizedBox(height: 16),
              Expanded(
                child:
                    _savedWorks.isEmpty
                        ? Center(
                          child: Text(
                            'Пока нет сохраненных работ',
                            style: Theme.of(
                              context,
                            ).textTheme.titleLarge?.copyWith(
                              color: colorScheme.onSurface.withAlpha(178),
                            ),
                          ),
                        )
                        : ListView.separated(
                          itemCount: _savedWorks.length,
                          separatorBuilder:
                              (context, index) => const SizedBox(height: 16),
                          itemBuilder: (context, index) {
                            final file = _savedWorks[index];
                            final fileName = _getBaseName(
                              file.path.split(Platform.pathSeparator).last,
                            );
                            final lastModified = file.lastModifiedSync();

                            // Проверяем, есть ли ответы для этой работы
                            final hasAnswers =
                                _hasAnswersMap[fileName] ?? false;

                            return _WorkCard(
                              title: fileName,
                              date:
                                  'Создано: ${lastModified.toString().substring(0, 10)}',
                              hasAnswers: hasAnswers,
                              onTap: () => _openWork(file),
                              onDelete: () => _deleteWork(file),
                            );
                          },
                        ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModernHeader(String title, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 48,
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkCard extends StatefulWidget {
  final String title;
  final String date;
  final bool hasAnswers;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkCard({
    required this.title,
    required this.date,
    required this.hasAnswers,
    required this.onTap,
    required this.onDelete,
  });

  @override
  State<_WorkCard> createState() => _WorkCardState();
}

class _WorkCardState extends State<_WorkCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    final isDarkMode = brightness == Brightness.dark;
    final borderRadius = BorderRadius.circular(16);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: TweenAnimationBuilder(
        duration: const Duration(milliseconds: 300),
        tween: Tween<double>(begin: 0, end: _isHovered ? 1.0 : 0.0),
        builder: (context, double value, child) {
          return Transform.translate(
            offset: Offset(0, -3.0 * value),
            child: Transform.scale(
              scale: 1.0 + 0.02 * value,
              child: Material(
                color: Colors.transparent,
                borderRadius: borderRadius,
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: widget.onTap,
                  borderRadius: borderRadius,
                  highlightColor: colorScheme.primary.withAlpha(20),
                  splashColor: colorScheme.primary.withAlpha(30),
                  child: Ink(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      color: Theme.of(context).cardTheme.color,
                      border: Border.all(
                        color:
                            _isHovered
                                ? colorScheme.primary.withAlpha(
                                  isDarkMode ? 100 : 50,
                                )
                                : Colors.transparent,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color:
                              _isHovered
                                  ? colorScheme.primary.withAlpha(
                                    isDarkMode ? 50 : 30,
                                  )
                                  : colorScheme.shadow.withAlpha(
                                    isDarkMode ? 30 : 10,
                                  ),
                          blurRadius: _isHovered ? 15 : 8,
                          spreadRadius: _isHovered ? 1 : 0,
                          offset:
                              _isHovered
                                  ? const Offset(0, 5)
                                  : const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    widget.date,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onSurface.withAlpha(
                                        178,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withAlpha(30),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      widget.hasAnswers
                                          ? 'Задания и ответы'
                                          : 'Задания',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall?.copyWith(
                                        color: colorScheme.primary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: widget.onDelete,
                            borderRadius: BorderRadius.circular(20),
                            splashColor: Colors.red.withAlpha(50),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.delete, color: Colors.red),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FileOptionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isVariants;
  final bool isAnswers;
  final ColorScheme colorScheme;

  const _FileOptionCard({
    required this.title,
    required this.icon,
    required this.isVariants,
    required this.isAnswers,
    required this.colorScheme,
  });

  @override
  State<_FileOptionCard> createState() => _FileOptionCardState();
}

class _FileOptionCardState extends State<_FileOptionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    Color cardColor =
        widget.isVariants
            ? widget.colorScheme.primary.withAlpha(20)
            : widget.isAnswers
            ? widget.colorScheme.secondary.withAlpha(20)
            : widget.colorScheme.surface;

    Color iconColor =
        widget.isVariants
            ? widget.colorScheme.primary
            : widget.isAnswers
            ? widget.colorScheme.secondary
            : widget.colorScheme.onSurface;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color:
              _isHovered
                  ? cardColor.withAlpha(cardColor.alpha + 20)
                  : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                _isHovered
                    ? widget.colorScheme.primary.withAlpha(80)
                    : Colors.transparent,
            width: 1.5,
          ),
          boxShadow:
              _isHovered
                  ? [
                    BoxShadow(
                      color: widget.colorScheme.shadow.withAlpha(20),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ]
                  : null,
        ),
        child: Row(
          children: [
            Icon(widget.icon, color: iconColor, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: widget.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.isVariants
                        ? 'Открыть файл с заданиями'
                        : widget.isAnswers
                        ? 'Открыть файл с ответами'
                        : 'Открыть файл',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: widget.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: widget.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

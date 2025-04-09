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

  @override
  void initState() {
    super.initState();
    _loadSavedWorks();
  }

  Future<void> _loadSavedWorks() async {
    try {
      final files = await FileService.loadSavedWorks();
      if (mounted) {
        setState(() => _savedWorks = files);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при загрузке работ: $e')),
        );
      }
    }
  }

  Future<void> _openWork(File file) async {
    try {
      await FileService.openFile(file.path);
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
      builder: (context) => AlertDialog(
        title: const Text('Удалить работу?'),
        content: const Text('Вы уверены, что хотите удалить эту работу?'),
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
        await FileService.deleteFile(file);
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
                child: _savedWorks.isEmpty
                    ? Center(
                  child: Text(
                    'Пока нет сохраненных работ',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(
                      color: colorScheme.onSurface.withAlpha(178), // Заменяем withOpacity(0.7)
                    ),
                  ),
                )
                    : ListView.separated(
                  itemCount: _savedWorks.length,
                  separatorBuilder: (context, index) =>
                  const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final file = _savedWorks[index];
                    final fileName = file.path
                        .split(Platform.pathSeparator)
                        .last
                        .replaceAll('_variants.pdf', '')
                        .replaceAll('.pdf', '');
                    final lastModified = file.lastModifiedSync();
                    return _WorkCard(
                      title: fileName,
                      date:
                      'Создано: ${lastModified.toString().substring(0, 10)}',
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
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _WorkCard({
    required this.title,
    required this.date,
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
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Theme.of(context).cardTheme.color,
                  boxShadow: [
                    BoxShadow(
                      color: colorScheme.primary
                          .withAlpha(_isHovered ? 38 : 13), // Заменяем withOpacity(0.15) и (0.05)
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style:
                            Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.date,
                            style:
                            Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurface
                                  .withAlpha(178), // Заменяем withOpacity(0.7)
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                        onPressed: widget.onDelete,
                        tooltip: 'Удалить работу',
                      ),
                    ],
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
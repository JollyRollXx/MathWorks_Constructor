import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:first_flutter_app/core/services/file_service.dart';
import 'package:first_flutter_app/core/services/task_generator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'dart:typed_data';
import '../widgets/common/animated_button.dart';
import '../widgets/common/input_fields.dart';
import '../widgets/common/multi_select_dropdown.dart';
import '../widgets/common/slider_input.dart';

class ConstructorScreen extends StatefulWidget {
  const ConstructorScreen({super.key});

  @override
  _ConstructorScreenState createState() => _ConstructorScreenState();
}

class _ConstructorScreenState extends State<ConstructorScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _variantsController = TextEditingController(text: '1');
  String _selectedClass = '5';
  String _difficulty = 'simple';
  bool _isAllThemesMode = false;
  bool _withAnswers = false;
  int _maxNumber = 20;
  bool _allowNegatives = false;
  final Map<String, int> _tasksCount = {};
  List<String> _selectedThemes = [];

  final List<String> _classes = ['5', '6', '7', '8', '9', '10', '11'];
  final Map<String, List<String>> _themesByClass = {
    '5': ['Обыкновенные дроби', 'Десятичные дроби', 'Натуральные числа'],
    '6': ['Обыкновенные дроби', 'Рациональные числа'],
    '7': ['Преобразование буквенных выражений', 'Одночлены', 'Многочлены'],
    '8': [
      'Квадратичная функция',
      'Алгебраические дроби',
      'Неравенства',
      'Квадратные уравнения',
    ],
    '9': [
      'Системы уравнений',
      'Числовые функции',
      'Тригонометрические уравнения',
    ],
    '10': ['Действительные числа', 'Степенные функции', 'Логарифмы'],
    '11': [
      'Производная',
      'Задачи по теории вероятностей',
      'Неравенства и системы неравенств',
    ],
  };

  @override
  void initState() {
    super.initState();
    _updateSelectedThemes();
  }

  void _updateSelectedThemes() {
    _selectedThemes.clear();
    _tasksCount.clear();
    if (_isAllThemesMode) {
      _selectedThemes =
          _themesByClass.values.expand((themes) => themes).toSet().toList();
      for (var theme in _selectedThemes) {
        _tasksCount[theme] = 5;
      }
    } else {
      _selectedThemes = List.from(_themesByClass[_selectedClass] ?? []);
      for (var theme in _selectedThemes) {
        _tasksCount[theme] = 5;
      }
    }
    setState(() {});
  }

  Future<Map<String, pw.Font>> _loadFonts() async {
    final regularFontData = await services.rootBundle.load('assets/fonts/times.ttf');
    final boldFontData = await services.rootBundle.load('assets/fonts/timesbd.ttf');
    final italicFontData = await services.rootBundle.load('assets/fonts/timesi.ttf');
    return {
      'regular': pw.Font.ttf(regularFontData),
      'bold': pw.Font.ttf(boldFontData),
      'italic': pw.Font.ttf(italicFontData),
    };
  }

  String _sanitizeFileName(String fileName) {
    return fileName.replaceAll(RegExp(r'[<>:"/\\|?*\s]'), '_');
  }

  Future<void> _generateAndSavePDF() async {
    if (_formKey.currentState!.validate() && _selectedThemes.isNotEmpty) {
      final int variantCount = int.parse(_variantsController.text);
      final variants = TaskGenerator.generateTaskVariants(
        _tasksCount,
        variantCount,
        difficulty: _difficulty,
        maxNumber: _maxNumber,
        allowNegatives: _allowNegatives,
      );
      final fonts = await _loadFonts();

      final pdfTasks = pw.Document();
      final pdfAnswers = _withAnswers ? pw.Document() : null;

      final now = DateTime.now();
      final dateString =
          '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year.toString().substring(2)}';

      for (
      int variantIndex = 0;
      variantIndex < variants.length;
      variantIndex++
      ) {
        final tasks = variants[variantIndex];
        pdfTasks.addPage(
          pw.MultiPage(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(40),
            header:
                (pw.Context context) =>
                _buildHeader(fonts, variantIndex, dateString),
            footer: (pw.Context context) => _buildFooter(fonts, context),
            build: (pw.Context context) => _buildTaskContent(fonts, tasks),
          ),
        );

        if (_withAnswers) {
          pdfAnswers!.addPage(
            pw.MultiPage(
              pageFormat: PdfPageFormat.a4,
              margin: const pw.EdgeInsets.all(40),
              header:
                  (pw.Context context) => _buildHeader(
                fonts,
                variantIndex,
                dateString,
                isAnswers: true,
              ),
              footer: (pw.Context context) => _buildFooter(fonts, context),
              build: (pw.Context context) => _buildAnswerContent(fonts, tasks),
            ),
          );
        }
      }

      final Uint8List tasksBytes = await pdfTasks.save();
      final sanitizedTitle = _sanitizeFileName(_titleController.text);
      final String tasksFileName = '${sanitizedTitle}_variants.pdf';

      final tempDir = await getTemporaryDirectory();
      final tempTasksFile = File('${tempDir.path}/temp_$tasksFileName');
      await tempTasksFile.writeAsBytes(tasksBytes);

      Uint8List? answersBytes;
      File? tempAnswersFile;
      if (_withAnswers) {
        answersBytes = await pdfAnswers!.save();
        final String answersFileName = '${sanitizedTitle}_answers.pdf';
        tempAnswersFile = File('${tempDir.path}/temp_$answersFileName');
        await tempAnswersFile.writeAsBytes(answersBytes);
      }

      try {
        await FileService.openFile(tempTasksFile.path);
        if (_withAnswers) await FileService.openFile(tempAnswersFile!.path);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Не удалось открыть файл: $e')),
          );
        }
        return;
      }

      if (mounted) {
        final shouldSave = await showDialog<bool>(
          context: context,
          builder:
              (context) => AlertDialog(
            title: const Text('Сохранить PDF?'),
            content: const Text('Если всё корректно, нажмите "Сохранить".'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Вернуться'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Сохранить'),
              ),
            ],
          ),
        );

        if (shouldSave == true) {
          try {
            await FileService.saveFile(tasksFileName, tasksBytes);
            if (_withAnswers) {
              await FileService.saveFile(
                '${sanitizedTitle}_answers.pdf',
                answersBytes!,
              );
            }
            await FileService.openFile(
              '${await FileService.getSavePath()}/$tasksFileName',
            );
            if (_withAnswers) {
              await FileService.openFile(
                '${await FileService.getSavePath()}/${sanitizedTitle}_answers.pdf',
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('Ошибка: $e')));
            }
          }
        }
      }

      if (await tempTasksFile.exists()) await tempTasksFile.delete();
      if (tempAnswersFile != null && await tempAnswersFile.exists())
        await tempAnswersFile.delete();
    }
  }

  pw.Widget _buildHeader(
      Map<String, pw.Font> fonts,
      int variantIndex,
      String dateString, {
        bool isAnswers = false,
      }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Text(
                'Дата: $dateString',
                style: pw.TextStyle(
                  font: fonts['regular'],
                  fontSize: 12,
                  color: PdfColors.grey,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            '${_titleController.text} - Вариант ${variantIndex + 1}${isAnswers ? " (Ответы)" : ""}',
            style: pw.TextStyle(font: fonts['bold'], fontSize: 24),
          ),
          pw.SizedBox(height: 5),
          if (!_isAllThemesMode)
            pw.Text(
              'Класс: $_selectedClass',
              style: pw.TextStyle(
                font: fonts['italic'],
                fontSize: 14,
                color: PdfColors.grey,
              ),
            ),
          pw.Text(
            'Темы: ${_selectedThemes.join(', ')}',
            style: pw.TextStyle(
              font: fonts['italic'],
              fontSize: 14,
              color: PdfColors.grey,
            ),
          ),
          if (!isAnswers) ...[
            pw.SizedBox(height: 10),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'ФИО ученика: _______________________________',
                  style: pw.TextStyle(font: fonts['regular'], fontSize: 12),
                ),
                pw.Text(
                  'Дата выполнения: ________________',
                  style: pw.TextStyle(font: fonts['regular'], fontSize: 12),
                ),
              ],
            ),
          ],
          pw.SizedBox(height: 10),
          pw.Divider(),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Map<String, pw.Font> fonts, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Сгенерировано с помощью MathWorks',
            style: pw.TextStyle(
              font: fonts['italic'],
              fontSize: 10,
              color: PdfColors.grey,
            ),
          ),
          pw.Text(
            'Страница ${context.pageNumber} из ${context.pagesCount}',
            style: pw.TextStyle(
              font: fonts['regular'],
              fontSize: 10,
              color: PdfColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  List<pw.Widget> _buildTaskContent(
      Map<String, pw.Font> fonts,
      List<MathTask> tasks,
      ) {
    Map<String, List<MathTask>> tasksByTheme = {};
    for (var task in tasks) {
      tasksByTheme.putIfAbsent(task.theme, () => []).add(task);
    }

    List<pw.Widget> widgets = [];
    tasksByTheme.forEach((theme, themeTasks) {
      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 10),
            pw.Text(
              theme,
              style: pw.TextStyle(font: fonts['bold'], fontSize: 16),
            ),
            pw.SizedBox(height: 5),
          ],
        ),
      );

      int themeTaskIndex = 1;
      for (var task in themeTasks) {
        pw.Widget taskWidget = _buildTaskWidget(fonts, task, themeTaskIndex);
        widgets.add(taskWidget);
        widgets.add(pw.SizedBox(height: 10));
        widgets.add(pw.Divider(height: 1, thickness: 0.5));
        widgets.add(pw.SizedBox(height: 10));
        themeTaskIndex++;
      }
    });

    return [
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: widgets,
        ),
      ),
    ];
  }

  List<pw.Widget> _buildAnswerContent(
      Map<String, pw.Font> fonts,
      List<MathTask> tasks,
      ) {
    Map<String, List<MathTask>> tasksByTheme = {};
    for (var task in tasks) {
      tasksByTheme.putIfAbsent(task.theme, () => []).add(task);
    }

    List<pw.Widget> widgets = [];
    tasksByTheme.forEach((theme, themeTasks) {
      widgets.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.SizedBox(height: 10),
            pw.Text(
              theme,
              style: pw.TextStyle(font: fonts['bold'], fontSize: 16),
            ),
            pw.SizedBox(height: 5),
          ],
        ),
      );

      int themeTaskIndex = 1;
      for (var task in themeTasks) {
        widgets.add(
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                '$themeTaskIndex.',
                style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                task.answer ?? 'Нет ответа',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
            ],
          ),
        );
        widgets.add(pw.SizedBox(height: 10));
        themeTaskIndex++;
      }
    });

    return [
      pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
        ),
        padding: const pw.EdgeInsets.all(10),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: widgets,
        ),
      ),
    ];
  }

  pw.Widget _buildTaskWidget(Map<String, pw.Font> fonts, MathTask task, int index) {
    if (task.structure != null) {
      switch (task.structure!['type']) {
        case 'fraction':
          return pw.Row(
            children: [
              pw.Text('$index.', style: pw.TextStyle(font: fonts['bold'], fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Column(
                children: [
                  pw.Text('${task.structure!['numerator']}', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
                  pw.Container(width: 20, height: 1, color: PdfColors.black),
                  pw.Text('${task.structure!['denominator']}', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
                ],
              ),
              if (task.text != null) pw.Text(' ${task.text}', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
            ],
          );
        case 'fractionOperation':
          return pw.Row(
            children: [
              pw.Text('$index.', style: pw.TextStyle(font: fonts['bold'], fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Column(
                children: [
                  pw.Text('${task.structure!['fraction1']['numerator']}', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
                  pw.Container(width: 20, height: 1, color: PdfColors.black),
                  pw.Text('${task.structure!['fraction1']['denominator']}', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
                ],
              ),
              pw.SizedBox(width: 8),
              pw.Text(task.structure!['operation'], style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Column(
                children: [
                  pw.Text('${task.structure!['fraction2']['numerator']}', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
                  pw.Container(width: 20, height: 1, color: PdfColors.black),
                  pw.Text('${task.structure!['fraction2']['denominator']}', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
                ],
              ),
            ],
          );
        case 'equation':
          return pw.Row(
            children: [
              pw.Text('$index.', style: pw.TextStyle(font: fonts['bold'], fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Text('${task.structure!['expression']} = ${task.structure!['rightSide']}', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
            ],
          );
        case 'trig':
          return pw.Row(
            children: [
              pw.Text('$index.', style: pw.TextStyle(font: fonts['bold'], fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Text(
                'Решите уравнение: ${task.structure!['coefficient']}${task.structure!['function']}(${task.structure!['argument']}) = 0',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
            ],
          );
        case 'power':
          return pw.Row(
            children: [
              pw.Text('$index.', style: pw.TextStyle(font: fonts['bold'], fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Text(
                'Вычислите: ${task.structure!['base']}^${task.structure!['exponent']}',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
            ],
          );
        case 'logarithm':
          return pw.Row(
            children: [
              pw.Text('$index.', style: pw.TextStyle(font: fonts['bold'], fontSize: 18)),
              pw.SizedBox(width: 8),
              pw.Text(
                'Вычислите: log_${task.structure!['base']}(${task.structure!['argument']})',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
            ],
          );
        default:
          return pw.Text('$index. Неизвестная структура');
      }
    }
    return pw.Row(
      children: [
        pw.Text('$index.', style: pw.TextStyle(font: fonts['bold'], fontSize: 18)),
        pw.SizedBox(width: 8),
        pw.Text(task.text ?? 'Ошибка: нет текста', style: pw.TextStyle(font: fonts['regular'], fontSize: 18)),
      ],
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth > 800;
          return SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: isLargeScreen ? constraints.maxWidth * 0.1 : 16.0,
              vertical: 24.0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildModernHeader('Создание работы', colorScheme),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          // Карточка "Основные параметры"
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).cardTheme.color,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withAlpha(13),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Основные параметры',
                                    style: GoogleFonts.inter(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  InputTextField(
                                    controller: _titleController,
                                    label: 'Название работы',
                                    icon: Icons.title,
                                    validator:
                                        (value) =>
                                    value!.isEmpty
                                        ? 'Введите название работы'
                                        : null,
                                  ),
                                  const SizedBox(height: 20),
                                  InputTextField(
                                    controller: _variantsController,
                                    label: 'Количество вариантов',
                                    icon: Icons.copy,
                                    keyboardType: TextInputType.number,
                                    validator: (value) {
                                      if (value!.isEmpty)
                                        return 'Введите количество вариантов';
                                      final count = int.tryParse(value);
                                      if (count == null || count <= 0)
                                        return 'Введите число больше 0';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  DropdownButtonFormField<String>(
                                    value: _selectedClass,
                                    decoration: InputDecoration(
                                      labelText: 'Класс',
                                      prefixIcon: const Icon(Icons.school),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                          12,
                                        ),
                                      ),
                                    ),
                                    items:
                                    _classes.map((String classNum) {
                                      return DropdownMenuItem<String>(
                                        value: classNum,
                                        child: Text(classNum),
                                      );
                                    }).toList(),
                                    onChanged:
                                    _isAllThemesMode
                                        ? null
                                        : (value) {
                                      setState(() {
                                        _selectedClass = value!;
                                        _updateSelectedThemes();
                                      });
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Icon(
                                      Icons.all_inclusive,
                                      color: colorScheme.primary,
                                    ),
                                    title: Text(
                                      'Режим "Все темы"',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    trailing: Switch(
                                      value: _isAllThemesMode,
                                      onChanged: (value) {
                                        setState(() {
                                          _isAllThemesMode = value;
                                          _updateSelectedThemes();
                                        });
                                      },
                                      activeColor: colorScheme.primary,
                                      inactiveThumbColor:
                                      colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    'Темы заданий:',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  MultiSelectDropdown(
                                    themes:
                                    _isAllThemesMode
                                        ? _themesByClass.values
                                        .expand((themes) => themes)
                                        .toSet()
                                        .toList()
                                        : _themesByClass[_selectedClass] ??
                                        [],
                                    selectedThemes: _selectedThemes,
                                    onChanged: (themes) {
                                      setState(() {
                                        _selectedThemes = themes;
                                        _tasksCount.clear();
                                        for (var theme in themes) {
                                          _tasksCount[theme] = 5;
                                        }
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Карточка "Дополнительные параметры"
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: Theme.of(context).cardTheme.color,
                              boxShadow: [
                                BoxShadow(
                                  color: colorScheme.primary.withAlpha(13),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Дополнительные параметры',
                                  style: GoogleFonts.inter(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.trending_up,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    'Сложность',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  trailing: DropdownButton<String>(
                                    value: _difficulty,
                                    items: const [
                                      DropdownMenuItem(
                                        value: 'simple',
                                        child: Text('Простые'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'complex',
                                        child: Text('Сложные'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _difficulty = value!;
                                      });
                                    },
                                    underline:
                                    const SizedBox(),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      color: colorScheme.onSurface,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                    elevation: 2,
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.check_circle_outline,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    'С ответами',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  trailing: Switch(
                                    value: _withAnswers,
                                    onChanged: (value) {
                                      setState(() {
                                        _withAnswers = value;
                                      });
                                    },
                                    activeColor: colorScheme.primary,
                                    inactiveThumbColor:
                                    colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: Icon(
                                          Icons.numbers,
                                          color: colorScheme.primary,
                                        ),
                                        title: Text(
                                          'Максимальное число: $_maxNumber',
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyLarge?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      SliderInput(
                                        value: _maxNumber.toDouble(),
                                        min: 10,
                                        max: 100,
                                        divisions: 9,
                                        label: '$_maxNumber',
                                        onChanged: (value) {
                                          setState(() {
                                            _maxNumber = value.round();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Icon(
                                    Icons.exposure_neg_1,
                                    color: colorScheme.primary,
                                  ),
                                  title: Text(
                                    'Отрицательные числа',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: colorScheme.onSurface,
                                    ),
                                  ),
                                  trailing: Switch(
                                    value: _allowNegatives,
                                    onChanged: (value) {
                                      setState(() {
                                        _allowNegatives = value;
                                      });
                                    },
                                    activeColor: colorScheme.primary,
                                    inactiveThumbColor:
                                    colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      flex: 1,
                      child:
                      _selectedThemes.isNotEmpty
                          ? Container(
                        padding: const EdgeInsets.all(16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Theme.of(context).cardTheme.color,
                          boxShadow: [
                            BoxShadow(
                              color: colorScheme.primary.withAlpha(
                                13,
                              ),
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Количество заданий',
                              style: GoogleFonts.inter(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._selectedThemes.map((theme) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: 16,
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$theme: ${_tasksCount[theme]}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                        fontWeight:
                                        FontWeight.bold,
                                        color:
                                        colorScheme
                                            .onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    SliderInput(
                                      value:
                                      _tasksCount[theme]!
                                          .toDouble(),
                                      min: 3,
                                      max: 30,
                                      divisions: 27,
                                      label:
                                      '${_tasksCount[theme]} заданий',
                                      onChanged: (value) {
                                        setState(() {
                                          _tasksCount[theme] =
                                              value.toInt();
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
                Center(
                  child: AnimatedButton(
                    onTap: _generateAndSavePDF,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Сгенерировать',
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
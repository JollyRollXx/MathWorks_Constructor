import 'package:flutter/material.dart';
import 'package:flutter/services.dart' as services;
import 'package:MathWorks/core/services/file_service.dart';
import 'package:MathWorks/core/services/task_generator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:math';
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
  final _searchController = TextEditingController();
  List<String> _filteredThemes = [];
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
    _updateFilteredThemes();
  }

  void _updateSelectedThemes() {
    _selectedThemes.clear();
    _tasksCount.clear();
    if (_isAllThemesMode) {
      final allThemes =
          _themesByClass.values.expand((themes) => themes).toSet().toList();

      if (_selectedThemes.isNotEmpty || _tasksCount.isNotEmpty) {
        _selectedThemes = allThemes;
        for (var theme in _selectedThemes) {
          _tasksCount[theme] ??= 3;
        }
      }
    } else {
      final classThemes = _themesByClass[_selectedClass] ?? [];

      if (_selectedThemes.isNotEmpty || _tasksCount.isNotEmpty) {
        _selectedThemes = List.from(classThemes);
        for (var theme in _selectedThemes) {
          _tasksCount[theme] ??= 3;
        }
      }
    }
    _updateFilteredThemes();
    setState(() {});
  }

  void _updateFilteredThemes() {
    final allThemes =
        _isAllThemesMode
            ? _themesByClass.values.expand((themes) => themes).toSet().toList()
            : _themesByClass[_selectedClass] ?? [];

    if (_searchController.text.isEmpty) {
      _filteredThemes = List.from(allThemes);
    } else {
      _filteredThemes =
          allThemes
              .where(
                (theme) => theme.toLowerCase().contains(
                  _searchController.text.toLowerCase(),
                ),
              )
              .toList();
    }
  }

  Future<Map<String, pw.Font>> _loadFonts() async {
    final regularFontData = await services.rootBundle.load(
      'assets/fonts/times.ttf',
    );
    final boldFontData = await services.rootBundle.load(
      'assets/fonts/timesbd.ttf',
    );
    final italicFontData = await services.rootBundle.load(
      'assets/fonts/timesi.ttf',
    );
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
                    _buildPdfHeader(fonts, variantIndex, dateString),
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
                  (pw.Context context) => _buildPdfHeader(
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
        final String answersFileName = '${sanitizedTitle}_Ответы.pdf';
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
          builder: (context) {
            final colorScheme = Theme.of(context).colorScheme;
            return Dialog(
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
                          Icons.save_alt_rounded,
                          color: colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Сохранение работы',
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
                      'Работа успешно сгенерирована. Хотите сохранить файлы?',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
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
                            'Вернуться',
                            style: TextStyle(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 12,
                            ),
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Сохранить'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );

        if (shouldSave == true) {
          try {
            await FileService.saveFile(tasksFileName, tasksBytes);
            if (_withAnswers) {
              await FileService.saveFile(
                '${sanitizedTitle}_Ответы.pdf',
                answersBytes!,
              );
            }
            await FileService.openFile(
              '${await FileService.getSavePath()}/$tasksFileName',
            );
            if (_withAnswers) {
              await FileService.openFile(
                '${await FileService.getSavePath()}/${sanitizedTitle}_Ответы.pdf',
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

  pw.Widget _buildPdfHeader(
    Map<String, pw.Font> fonts,
    int variantIndex,
    String dateString, {
    bool isAnswers = false,
  }) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  'Вариант ${variantIndex + 1}${isAnswers ? " (Ответы)" : ""}',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 12,
                    color: PdfColors.grey700,
                  ),
                ),
              ),
              pw.Text(
                'Дата: $dateString',
                style: pw.TextStyle(
                  font: fonts['regular'],
                  fontSize: 12,
                  color: PdfColors.grey600,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            _titleController.text,
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 24,
              color: PdfColors.black,
            ),
          ),
          pw.SizedBox(height: 8),
          if (!_isAllThemesMode)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'Класс: $_selectedClass',
                style: pw.TextStyle(
                  font: fonts['italic'],
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          pw.SizedBox(height: 8),
          if (!isAnswers)
            pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey300, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
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
            )
          else
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey50,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                'Темы: ${_selectedThemes.join(', ')}',
                style: pw.TextStyle(
                  font: fonts['italic'],
                  fontSize: 14,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          if (!isAnswers) pw.SizedBox(height: 16),
          pw.SizedBox(height: 20),
        ],
      ),
    );
  }

  pw.Widget _buildFooter(Map<String, pw.Font> fonts, pw.Context context) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      padding: const pw.EdgeInsets.symmetric(vertical: 8),
      decoration: pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Сгенерировано с помощью MathWorks',
            style: pw.TextStyle(
              font: fonts['italic'],
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              'Страница ${context.pageNumber} из ${context.pagesCount}',
              style: pw.TextStyle(
                font: fonts['regular'],
                fontSize: 10,
                color: PdfColors.grey700,
              ),
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
    List<pw.Widget> widgets = [];
    int globalTaskIndex = 1;

    for (var task in tasks) {
      pw.Widget taskWidget = _buildTaskWidget(fonts, task, globalTaskIndex);
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 12),
          padding: const pw.EdgeInsets.all(12),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey200, width: 1),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: taskWidget,
        ),
      );
      globalTaskIndex++;
    }

    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
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
    int globalTaskIndex = 1;

    tasksByTheme.forEach((theme, themeTasks) {
      widgets.add(
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 16),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  theme,
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 16,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(height: 8),
            ],
          ),
        ),
      );

      for (var task in themeTasks) {
        if (task.answer != null) {
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Text(
                      '$globalTaskIndex.',
                      style: pw.TextStyle(
                        font: fonts['bold'],
                        fontSize: 14,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  _parseAnswerText(task.answer!, fonts),
                ],
              ),
            ),
          );
        } else {
          widgets.add(
            pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 12),
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey200, width: 1),
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Row(
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(4),
                      ),
                    ),
                    child: pw.Text(
                      '$globalTaskIndex.',
                      style: pw.TextStyle(
                        font: fonts['bold'],
                        fontSize: 14,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 8),
                  pw.Text(
                    'Нет ответа',
                    style: pw.TextStyle(
                      font: fonts['regular'],
                      fontSize: 14,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        globalTaskIndex++;
      }
    });

    return [
      pw.Container(
        padding: const pw.EdgeInsets.all(16),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColors.grey300, width: 1),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: widgets,
        ),
      ),
    ];
  }

  pw.Widget _buildTaskWidget(
    Map<String, pw.Font> fonts,
    MathTask task,
    int index,
  ) {
    if (task.structure != null) {
      switch (task.structure!['type']) {
        case 'fraction':
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  '$index.',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              _buildFractionWidget(
                task.structure!['numerator'],
                task.structure!['denominator'],
                fonts,
              ),
              if (task.text != null)
                pw.Text(
                  ' ${task.text}',
                  style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
                ),
            ],
          );
        case 'fractionOperation':
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  '$index.',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Вычислите: ',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
              _buildFractionWidget(
                task.structure!['fraction1']['numerator'],
                task.structure!['fraction1']['denominator'],
                fonts,
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                task.structure!['operation'],
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
              pw.SizedBox(width: 8),
              _buildFractionWidget(
                task.structure!['fraction2']['numerator'],
                task.structure!['fraction2']['denominator'],
                fonts,
              ),
            ],
          );
        case 'equation':
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  '$index.',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Решите уравнение: ',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
              _formatExpressionWithPowers(task.structure!['expression'], fonts),
              pw.Text(
                ' = ',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
              _formatExpressionWithPowers(task.structure!['rightSide'], fonts),
            ],
          );
        case 'trig':
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  '$index.',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Решите уравнение: ${task.structure!['coefficient']}${task.structure!['function']}(${task.structure!['argument']}) = 0',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
            ],
          );
        case 'power':
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  '$index.',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Вычислите: ',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
              _buildPowerWidget(
                task.structure!['base'],
                task.structure!['exponent'],
                fonts,
              ),
            ],
          );
        case 'logarithm':
          return pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 2,
                ),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: const pw.BorderRadius.all(
                    pw.Radius.circular(4),
                  ),
                ),
                child: pw.Text(
                  '$index.',
                  style: pw.TextStyle(
                    font: fonts['bold'],
                    fontSize: 14,
                    color: PdfColors.grey800,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                'Вычислите: log',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '${task.structure!['base']}',
                  style: pw.TextStyle(font: fonts['regular'], fontSize: 12),
                ),
              ),
              pw.Text(
                '(${task.structure!['argument']})',
                style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
              ),
            ],
          );
        default:
          return pw.Text('$index. Неизвестная структура');
      }
    }

    if (task.text != null) {
      if (task.text!.contains('/') || task.text!.contains('^')) {
        return pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 6,
                vertical: 2,
              ),
              decoration: pw.BoxDecoration(
                color: PdfColors.grey100,
                borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
              ),
              child: pw.Text(
                '$index.',
                style: pw.TextStyle(
                  font: fonts['bold'],
                  fontSize: 14,
                  color: PdfColors.grey800,
                ),
              ),
            ),
            pw.SizedBox(width: 8),
            _parseMixedText(task.text!, fonts),
          ],
        );
      }

      return pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
            ),
            child: pw.Text(
              '$index.',
              style: pw.TextStyle(
                font: fonts['bold'],
                fontSize: 14,
                color: PdfColors.grey800,
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Text(
            task.text!,
            style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
          ),
        ],
      );
    }

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Text(
            '$index.',
            style: pw.TextStyle(
              font: fonts['bold'],
              fontSize: 14,
              color: PdfColors.grey800,
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          'Ошибка: нет текста',
          style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
        ),
      ],
    );
  }

  pw.Widget _buildFractionWidget(
    int numerator,
    int denominator,
    Map<String, pw.Font> fonts,
  ) {
    double lineWidth = max(
      numerator.toString().length * 8.0,
      denominator.toString().length * 8.0,
    );

    lineWidth = max(lineWidth, 20.0);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 2),
      child: pw.Column(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            '$numerator',
            style: pw.TextStyle(font: fonts['regular'], fontSize: 16),
            textAlign: pw.TextAlign.center,
          ),
          pw.Container(width: lineWidth, height: 1.0, color: PdfColors.black),
          pw.Text(
            '$denominator',
            style: pw.TextStyle(font: fonts['regular'], fontSize: 16),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  pw.Widget _buildPowerWidget(
    dynamic base,
    dynamic exponent,
    Map<String, pw.Font> fonts,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '$base',
          style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.only(top: 1),
          child: pw.Text(
            '$exponent',
            style: pw.TextStyle(font: fonts['regular'], fontSize: 12),
          ),
        ),
      ],
    );
  }

  pw.Widget _formatExpressionWithPowers(
    String expression,
    Map<String, pw.Font> fonts,
  ) {
    final RegExp powerRegex = RegExp(r'(\w+)\^(\d+)');
    final RegExp fractionRegex = RegExp(r'(\d+)/(\d+)');

    List<pw.Widget> parts = [];
    String remaining = expression;

    var powerMatches = powerRegex.allMatches(expression).toList();
    if (powerMatches.isNotEmpty) {
      int lastEnd = 0;
      for (var match in powerMatches) {
        if (match.start > lastEnd) {
          parts.add(
            pw.Text(
              remaining.substring(lastEnd, match.start),
              style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
            ),
          );
        }

        String base = match.group(1)!;
        String exponent = match.group(2)!;

        parts.add(_buildPowerWidget(base, exponent, fonts));

        lastEnd = match.end;
      }

      if (lastEnd < remaining.length) {
        parts.add(
          pw.Text(
            remaining.substring(lastEnd),
            style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
          ),
        );
      }
    } else {
      parts.add(
        pw.Text(
          remaining,
          style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
        ),
      );
    }

    return pw.Row(mainAxisSize: pw.MainAxisSize.min, children: parts);
  }

  pw.Widget _parseMixedText(String text, Map<String, pw.Font> fonts) {
    final RegExp fractionRegex = RegExp(r'(\d+)/(\d+)');
    final RegExp powerRegex = RegExp(r'(\w+)\^(\d+)');

    List<pw.Widget> parts = [];
    String remaining = text;

    List<RegExpMatch> allMatches = [];
    allMatches.addAll(fractionRegex.allMatches(text));
    allMatches.addAll(powerRegex.allMatches(text));

    allMatches.sort((a, b) => a.start.compareTo(b.start));

    if (allMatches.isNotEmpty) {
      int lastEnd = 0;
      for (var match in allMatches) {
        if (match.start > lastEnd) {
          parts.add(
            pw.Text(
              remaining.substring(lastEnd, match.start),
              style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
            ),
          );
        }

        if (match.pattern == fractionRegex) {
          int numerator = int.parse(match.group(1)!);
          int denominator = int.parse(match.group(2)!);
          parts.add(_buildFractionWidget(numerator, denominator, fonts));
        } else {
          String base = match.group(1)!;
          String exponent = match.group(2)!;
          parts.add(_buildPowerWidget(base, exponent, fonts));
        }

        lastEnd = match.end;
      }

      if (lastEnd < remaining.length) {
        parts.add(
          pw.Text(
            remaining.substring(lastEnd),
            style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
          ),
        );
      }
    } else {
      parts.add(
        pw.Text(
          remaining,
          style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
        ),
      );
    }

    return pw.Row(mainAxisSize: pw.MainAxisSize.min, children: parts);
  }

  pw.Widget _parseAnswerText(String answer, Map<String, pw.Font> fonts) {
    if (answer.contains('/') || answer.contains('^')) {
      return _parseMixedText(answer, fonts);
    }

    return pw.Text(
      answer,
      style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth > 800;
        final colorScheme = Theme.of(context).colorScheme;
        final textTheme = Theme.of(context).textTheme;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isLargeScreen ? constraints.maxWidth * 0.1 : 16.0,
            vertical: 24.0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildModernHeader('Конструктор заданий', colorScheme),
              const SizedBox(height: 24),
              Wrap(
                spacing: 16.0,
                runSpacing: 16.0,
                children: [
                  _buildMainSection(context),
                  _buildTasksSection(context),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: TweenAnimationBuilder(
                    duration: const Duration(milliseconds: 200),
                    tween: Tween<double>(begin: 0, end: 1),
                    builder: (context, double value, child) {
                      return Transform.scale(
                        scale: 1.0 + 0.02 * value,
                        child: Material(
                          color: Colors.transparent,
                          clipBehavior: Clip.antiAlias,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: _generateAndSavePDF,
                            borderRadius: BorderRadius.circular(16),
                            child: Ink(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 32,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color: colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorScheme.primary.withOpacity(0.3),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: colorScheme.primary.withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary.withOpacity(
                                        0.1,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.auto_awesome,
                                      color: colorScheme.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Сгенерировать работу',
                                        style: textTheme.titleMedium?.copyWith(
                                          color: colorScheme.onPrimaryContainer,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      Text(
                                        'Создать PDF с заданиями',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onPrimaryContainer
                                              .withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
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

  Widget _buildMainSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).cardTheme.color,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 0,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.settings, color: colorScheme.primary, size: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Основные параметры',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 50,
                height: 3,
                decoration: BoxDecoration(
                  color: colorScheme.primary,
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(
                    brightness == Brightness.dark ? 0.15 : 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Параметры работы',
                        style: Theme.of(
                          context,
                        ).textTheme.titleMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        child: InputTextField(
                          controller: _titleController,
                          label: 'Название работы',
                          icon: Icons.title,
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? 'Введите название работы'
                                      : null,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        child: Row(
                          children: [
                            Expanded(
                              child: InputTextField(
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
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                value: _selectedClass,
                                decoration: InputDecoration(
                                  labelText: 'Класс',
                                  prefixIcon: const Icon(Icons.school),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
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
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        child: _buildSwitchCard(
                          context,
                          title: 'Режим "Все темы"',
                          subtitle: 'Включить темы из всех классов',
                          icon: Icons.all_inclusive,
                          value: _isAllThemesMode,
                          onChanged: (value) {
                            setState(() {
                              _isAllThemesMode = value;
                              _updateSelectedThemes();
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildSettingsCard(
                        context,
                        child: _buildThemeSelector(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildCard(
          context,
          title: 'Дополнительные параметры',
          icon: Icons.tune,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant.withOpacity(
                    brightness == Brightness.dark ? 0.15 : 0.3,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Настройки генерации',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      context,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Сложность',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'simple',
                                label: Text('Простые'),
                                icon: Icon(Icons.emoji_emotions_outlined),
                              ),
                              ButtonSegment(
                                value: 'complex',
                                label: Text('Сложные'),
                                icon: Icon(Icons.psychology_outlined),
                              ),
                            ],
                            selected: {_difficulty},
                            onSelectionChanged: (Set<String> selection) {
                              setState(() {
                                _difficulty = selection.first;
                              });
                            },
                            style: ButtonStyle(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildSettingsCard(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Максимальное число: $_maxNumber',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                          const SizedBox(height: 12),
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
                    const SizedBox(height: 16),
                    _buildSettingsCard(
                      context,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Дополнительные настройки',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSwitchCard(
                                  context,
                                  title: 'С ответами',
                                  subtitle: 'Генерировать файл с ответами',
                                  icon: Icons.check_circle_outline,
                                  value: _withAnswers,
                                  onChanged: (value) {
                                    setState(() {
                                      _withAnswers = value;
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildSwitchCard(
                                  context,
                                  title: 'Отрицательные числа',
                                  subtitle: 'Использовать отрицательные числа',
                                  icon: Icons.exposure_neg_1,
                                  value: _allowNegatives,
                                  onChanged: (value) {
                                    setState(() {
                                      _allowNegatives = value;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required Widget child}) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Container(
      decoration: BoxDecoration(
        color:
            brightness == Brightness.dark
                ? colorScheme.surfaceVariant.withOpacity(0.3)
                : colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 18.0),
      margin: const EdgeInsets.only(bottom: 16.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).cardTheme.color,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colorScheme.primary, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: 50,
            height: 3,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          height: 120,
          decoration: BoxDecoration(
            color:
                value
                    ? colorScheme.primaryContainer.withOpacity(0.3)
                    : colorScheme.surfaceVariant.withOpacity(0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color:
                  value
                      ? colorScheme.primary.withOpacity(0.3)
                      : colorScheme.outlineVariant,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          value
                              ? colorScheme.primary.withOpacity(0.1)
                              : colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      color:
                          value
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            color:
                                value
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color:
                                value
                                    ? colorScheme.onPrimaryContainer
                                        .withOpacity(0.7)
                                    : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: value,
                    onChanged: onChanged,
                    activeColor: colorScheme.primary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final allThemes =
        _isAllThemesMode
            ? _themesByClass.values.expand((themes) => themes).toSet().toList()
            : _themesByClass[_selectedClass] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Выбор тем',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Поиск тем...',
            prefixIcon: const Icon(Icons.search),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 16,
            ),
          ),
          onChanged: (query) {
            setState(() {
              if (query.isEmpty) {
                _filteredThemes = List.from(allThemes);
              } else {
                _filteredThemes =
                    allThemes
                        .where(
                          (theme) =>
                              theme.toLowerCase().contains(query.toLowerCase()),
                        )
                        .toList();
              }
            });
          },
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.check_box_outlined, size: 20),
              label: const Text('Выбрать все'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                backgroundColor: colorScheme.primaryContainer,
                foregroundColor: colorScheme.onPrimaryContainer,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedThemes = List.from(allThemes);
                  for (var theme in _selectedThemes) {
                    _tasksCount[theme] ??= 3;
                  }
                });
              },
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
              icon: const Icon(Icons.check_box_outline_blank, size: 20),
              label: const Text('Снять все'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                backgroundColor: colorScheme.surfaceVariant,
                foregroundColor: colorScheme.onSurfaceVariant,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedThemes.clear();
                  _tasksCount.clear();
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        if (_searchController.text.isNotEmpty)
          _buildThemeTable(context, _filteredThemes)
        else if (_isAllThemesMode) ...[
          for (var classEntry in _themesByClass.entries)
            _buildThemeGroup(
              context,
              '${classEntry.key} класс',
              classEntry.value,
            ),
        ] else
          _buildThemeTable(context, _filteredThemes),
      ],
    );
  }

  Widget _buildThemeTable(BuildContext context, List<String> themes) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(10),
        color:
            brightness == Brightness.dark
                ? colorScheme.surfaceVariant.withOpacity(0.2)
                : colorScheme.surface,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color:
                  brightness == Brightness.dark
                      ? colorScheme.surfaceVariant.withOpacity(0.3)
                      : colorScheme.surfaceVariant.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      'Тема',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: Center(
                      child: Text(
                        'Выбор',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (themes.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Темы не найдены',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            else
              for (var theme in themes)
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: colorScheme.outlineVariant),
                    ),
                    color:
                        _selectedThemes.contains(theme)
                            ? (brightness == Brightness.dark
                                ? colorScheme.primaryContainer.withOpacity(0.2)
                                : colorScheme.primaryContainer.withOpacity(0.3))
                            : null,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Text(
                            theme,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 80,
                        child: Center(
                          child: Checkbox(
                            value: _selectedThemes.contains(theme),
                            checkColor:
                                brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                            fillColor: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                                if (states.contains(MaterialState.selected)) {
                                  return colorScheme.primary;
                                }
                                return Colors.transparent;
                              },
                            ),
                            visualDensity: VisualDensity.standard,
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedThemes.add(theme);
                                  _tasksCount[theme] = 3;
                                } else {
                                  _selectedThemes.remove(theme);
                                  _tasksCount.remove(theme);
                                }
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeGroup(
    BuildContext context,
    String title,
    List<String> themes,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final brightness = Theme.of(context).brightness;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      color:
          brightness == Brightness.dark
              ? colorScheme.surfaceVariant.withOpacity(0.2)
              : colorScheme.surface,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ExpansionTile(
          title: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          initiallyExpanded: false,
          collapsedBackgroundColor: Colors.transparent,
          backgroundColor: Colors.transparent,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16),
          shape: const RoundedRectangleBorder(),
          children: [
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: themes.length,
              itemBuilder: (context, index) {
                final theme = themes[index];
                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        if (_selectedThemes.contains(theme)) {
                          _selectedThemes.remove(theme);
                          _tasksCount.remove(theme);
                        } else {
                          _selectedThemes.add(theme);
                          _tasksCount[theme] = 3;
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: Container(
                      decoration: BoxDecoration(
                        color:
                            _selectedThemes.contains(theme)
                                ? colorScheme.primaryContainer.withOpacity(
                                  brightness == Brightness.dark ? 0.15 : 0.2,
                                )
                                : null,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Checkbox(
                            value: _selectedThemes.contains(theme),
                            checkColor:
                                brightness == Brightness.dark
                                    ? Colors.black
                                    : Colors.white,
                            fillColor: MaterialStateProperty.resolveWith<Color>(
                              (states) {
                                if (states.contains(MaterialState.selected)) {
                                  return colorScheme.primary;
                                }
                                return Colors.transparent;
                              },
                            ),
                            visualDensity: VisualDensity.compact,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (value == true) {
                                  _selectedThemes.add(theme);
                                  _tasksCount[theme] = 3;
                                } else {
                                  _selectedThemes.remove(theme);
                                  _tasksCount.remove(theme);
                                }
                              });
                            },
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              theme,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(color: colorScheme.onSurface),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    if (_selectedThemes.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;

    Map<String, List<String>> themesByClass = {};

    for (String theme in _selectedThemes) {
      String? classFound;

      for (var entry in _themesByClass.entries) {
        if (entry.value.contains(theme)) {
          classFound = entry.key;
          break;
        }
      }

      classFound ??= 'Другие';
      themesByClass.putIfAbsent(classFound, () => []).add(theme);
    }

    double averageTaskCount = 0;
    if (_tasksCount.isNotEmpty) {
      averageTaskCount =
          _tasksCount.values.reduce((a, b) => a + b) / _tasksCount.length;
    } else {
      averageTaskCount = 3;
    }

    return _buildCard(
      context,
      title: 'Количество заданий',
      icon: Icons.format_list_numbered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'Для всех тем:',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: SliderInput(
                  value: averageTaskCount,
                  min: 1,
                  max: 20,
                  divisions: 19,
                  label: '${averageTaskCount.round()} заданий',
                  onChanged: (value) {
                    setState(() {
                      final newCount = value.toInt();
                      for (var theme in _selectedThemes) {
                        _tasksCount[theme] = newCount;
                      }
                    });
                  },
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.check_circle_outline,
                  color: colorScheme.primary,
                  size: 22,
                ),
                tooltip: 'Применить ко всем',
                onPressed: () {
                  setState(() {
                    final newCount = averageTaskCount.round();
                    for (var theme in _selectedThemes) {
                      _tasksCount[theme] = newCount;
                    }
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 20),

          ...themesByClass.entries.map((entry) {
            final classNumber = entry.key;
            final themes = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 9,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.school,
                        size: 20,
                        color: colorScheme.onPrimaryContainer,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          classNumber == 'Другие'
                              ? 'Другие темы'
                              : '$classNumber класс',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Table(
                      border: TableBorder.symmetric(
                        inside: BorderSide(color: colorScheme.outlineVariant),
                      ),
                      defaultVerticalAlignment:
                          TableCellVerticalAlignment.middle,
                      columnWidths: const {
                        0: FlexColumnWidth(5),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(2),
                      },
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                          ),
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'Тема',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'Кол-во',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(10.0),
                              child: Text(
                                'Действия',
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                        ...themes
                            .map(
                              (theme) => TableRow(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      theme,
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(10.0),
                                    child: Text(
                                      '${_tasksCount[theme]}',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 6.0,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          iconSize: 22,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                          ),
                                          onPressed:
                                              _tasksCount[theme]! > 1
                                                  ? () => setState(
                                                    () =>
                                                        _tasksCount[theme] =
                                                            _tasksCount[theme]! -
                                                            1,
                                                  )
                                                  : null,
                                        ),
                                        const SizedBox(width: 12),
                                        IconButton(
                                          iconSize: 22,
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                          visualDensity: VisualDensity.compact,
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                          ),
                                          onPressed:
                                              _tasksCount[theme]! < 20
                                                  ? () => setState(
                                                    () =>
                                                        _tasksCount[theme] =
                                                            _tasksCount[theme]! +
                                                            1,
                                                  )
                                                  : null,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )
                            .toList(),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            );
          }).toList(),
        ],
      ),
    );
  }
}

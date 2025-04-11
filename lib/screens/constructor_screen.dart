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
      final allThemes =
          _themesByClass.values.expand((themes) => themes).toSet().toList();

      if (_selectedThemes.isNotEmpty || _tasksCount.isNotEmpty) {
        _selectedThemes = allThemes;
        for (var theme in _selectedThemes) {
          _tasksCount[theme] = 3;
        }
      }
    } else {
      final classThemes = _themesByClass[_selectedClass] ?? [];

      if (_selectedThemes.isNotEmpty || _tasksCount.isNotEmpty) {
        _selectedThemes = List.from(classThemes);
        for (var theme in _selectedThemes) {
          _tasksCount[theme] = 3;
        }
      }
    }
    setState(() {});
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
        if (task.answer != null) {
          widgets.add(
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  '$themeTaskIndex.',
                  style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
                ),
                pw.SizedBox(width: 8),
                _parseAnswerText(task.answer!, fonts),
              ],
            ),
          );
        } else {
          widgets.add(
            pw.Row(
              children: [
                pw.Text(
                  '$themeTaskIndex.',
                  style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
                ),
                pw.SizedBox(width: 8),
                pw.Text(
                  'Нет ответа',
                  style: pw.TextStyle(font: fonts['regular'], fontSize: 18),
                ),
              ],
            ),
          );
        }
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

  pw.Widget _buildTaskWidget(
    Map<String, pw.Font> fonts,
    MathTask task,
    int index,
  ) {
    if (task.structure != null) {
      switch (task.structure!['type']) {
        case 'fraction':
          return pw.Row(
            children: [
              pw.Text(
                '$index.',
                style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
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
            children: [
              pw.Text(
                '$index.',
                style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
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
            children: [
              pw.Text(
                '$index.',
                style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
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
            children: [
              pw.Text(
                '$index.',
                style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
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
            children: [
              pw.Text(
                '$index.',
                style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
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
            children: [
              pw.Text(
                '$index.',
                style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
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
          children: [
            pw.Text(
              '$index.',
              style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
            ),
            pw.SizedBox(width: 8),
            _parseMixedText(task.text!, fonts),
          ],
        );
      }

      return pw.Row(
        children: [
          pw.Text(
            '$index.',
            style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
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
      children: [
        pw.Text(
          '$index.',
          style: pw.TextStyle(font: fonts['bold'], fontSize: 18),
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
    final colorScheme = Theme.of(context).colorScheme;
    final isLargeScreen = MediaQuery.of(context).size.width > 1200;
    final isMediumScreen = MediaQuery.of(context).size.width > 800;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMediumScreen ? 32.0 : 16.0),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 1400),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPageHeader(context),
                  const SizedBox(height: 32),
                  if (isLargeScreen)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _buildMainSection(context)),
                        const SizedBox(width: 24),
                        Expanded(child: _buildTasksSection(context)),
                      ],
                    )
                  else
                    Column(
                      children: [
                        _buildMainSection(context),
                        const SizedBox(height: 24),
                        _buildTasksSection(context),
                      ],
                    ),
                  const SizedBox(height: 40),
                  _buildActionButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(Icons.edit_document, size: 32, color: colorScheme.primary),
              const SizedBox(width: 16),
              Text(
                'Конструктор работы',
                style: GoogleFonts.inter(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Создайте индивидуальную работу с настраиваемыми параметрами',
            style: GoogleFonts.inter(
              fontSize: 16,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _buildCard(
          context,
          title: 'Основные параметры',
          icon: Icons.settings,
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InputTextField(
                  controller: _titleController,
                  label: 'Название работы',
                  icon: Icons.title,
                  validator:
                      (value) =>
                          value!.isEmpty ? 'Введите название работы' : null,
                ),
                const SizedBox(height: 24),
                Row(
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
                const SizedBox(height: 24),
                _buildSwitchTile(
                  context,
                  title: 'Режим "Все темы"',
                  subtitle: 'Включить задания из всех классов',
                  value: _isAllThemesMode,
                  onChanged: (value) {
                    setState(() {
                      _isAllThemesMode = value;
                      _updateSelectedThemes();
                    });
                  },
                  icon: Icons.all_inclusive,
                ),
                const SizedBox(height: 24),
                Text(
                  'Выбранные темы',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 12),
                MultiSelectDropdown(
                  themes:
                      _isAllThemesMode
                          ? _themesByClass.values
                              .expand((themes) => themes)
                              .toSet()
                              .toList()
                          : _themesByClass[_selectedClass] ?? [],
                  selectedThemes: _selectedThemes,
                  onChanged: (themes) {
                    setState(() {
                      _selectedThemes = themes;
                      _tasksCount.clear();
                      for (var theme in themes) {
                        _tasksCount[theme] = 3;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        _buildCard(
          context,
          title: 'Дополнительные параметры',
          icon: Icons.tune,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: _buildSwitchTile(
                      context,
                      title: 'С ответами',
                      value: _withAnswers,
                      onChanged: (value) {
                        setState(() {
                          _withAnswers = value;
                        });
                      },
                      icon: Icons.check_circle_outline,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(
                        Icons.trending_up,
                        color: colorScheme.primary,
                      ),
                      title: Text(
                        'Сложность',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w500),
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
                        underline: const SizedBox(),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'Максимальное число: $_maxNumber',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
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
              const SizedBox(height: 16),
              _buildSwitchTile(
                context,
                title: 'Отрицательные числа',
                value: _allowNegatives,
                onChanged: (value) {
                  setState(() {
                    _allowNegatives = value;
                  });
                },
                icon: Icons.exposure_neg_1,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTasksSection(BuildContext context) {
    if (_selectedThemes.isEmpty) return const SizedBox.shrink();

    return _buildCard(
      context,
      title: 'Количество заданий',
      icon: Icons.format_list_numbered,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            _selectedThemes.map((theme) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      theme,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          '${_tasksCount[theme]}',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: SliderInput(
                            value: _tasksCount[theme]!.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: '${_tasksCount[theme]} заданий',
                            onChanged: (value) {
                              setState(() {
                                _tasksCount[theme] = value.toInt();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _buildCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
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
          Row(
            children: [
              Icon(icon, color: colorScheme.primary),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          child,
        ],
      ),
    );
  }

  Widget _buildSwitchTile(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: colorScheme.primary),
      title: Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: GoogleFonts.inter(color: colorScheme.onSurfaceVariant),
              )
              : null,
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: colorScheme.primary,
      ),
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return Center(
      child: AnimatedButton(
        onTap: _generateAndSavePDF,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow, color: Colors.white, size: 24),
              const SizedBox(width: 12),
              Text(
                'Сгенерировать PDF',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

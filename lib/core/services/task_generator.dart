import 'dart:math';

class MathTask {
  final String theme;
  String? text;
  final Map<String, dynamic>? structure;
  String? answer;

  MathTask({required this.theme, this.text, this.structure, this.answer});

  factory MathTask.simple(String theme, String text, {String? answer}) {
    return MathTask(theme: theme, text: text, answer: answer);
  }

  factory MathTask.fraction(String theme, int numerator, int denominator, {String? answer}) {
    return MathTask(
      theme: theme,
      structure: {'type': 'fraction', 'numerator': numerator, 'denominator': denominator},
      answer: answer,
    );
  }

  factory MathTask.fractionOperation(String theme, String operation, int num1, int den1, int num2, int den2, {String? answer}) {
    return MathTask(
      theme: theme,
      structure: {
        'type': 'fractionOperation',
        'operation': operation,
        'fraction1': {'numerator': num1, 'denominator': den1},
        'fraction2': {'numerator': num2, 'denominator': den2},
      },
      answer: answer,
    );
  }

  factory MathTask.power(String theme, int base, int exponent, {String? answer}) {
    return MathTask(
      theme: theme,
      structure: {'type': 'power', 'base': base, 'exponent': exponent},
      answer: answer,
    );
  }

  factory MathTask.root(String theme, int radicand, int index, {String? answer}) {
    return MathTask(
      theme: theme,
      structure: {'type': 'root', 'radicand': radicand, 'index': index},
      answer: answer,
    );
  }

  factory MathTask.logarithm(String theme, int base, int argument, {String? answer}) {
    return MathTask(
      theme: theme,
      structure: {'type': 'logarithm', 'base': base, 'argument': argument},
      answer: answer,
    );
  }

  factory MathTask.trig(String theme, String function, int coefficient, String argument, {String? answer}) {
    return MathTask(
      theme: theme,
      structure: {
        'type': 'trig',
        'function': function,
        'coefficient': coefficient,
        'argument': argument,
      },
      answer: answer,
    );
  }

  factory MathTask.equation(String theme, String expression, String rightSide, {String? answer}) {
    return MathTask(
      theme: theme,
      structure: {
        'type': 'equation',
        'expression': expression,
        'rightSide': rightSide,
      },
      answer: answer,
    );
  }
}

class TaskGenerator {
  static final Random _random = Random();

  static MathTask generateTask(String theme, {required String difficulty, required int maxNumber, required bool allowNegatives}) {
    bool isComplex = difficulty == 'complex';
    int range = maxNumber > 0 ? maxNumber : (isComplex ? 20 : 10);

    switch (theme) {
      case 'Обыкновенные дроби':
        int num1 = _random.nextInt(range) + 1;
        int den1 = _random.nextInt(range) + 1;
        int num2 = _random.nextInt(range) + 1;
        int den2 = _random.nextInt(range) + 1;
        if (isComplex) {
          int choice = _random.nextInt(4);
          String operation;
          String answer;
          switch (choice) {
            case 0:
              operation = '+';
              answer = _calculateFractionAddition(num1, den1, num2, den2);
              return MathTask.fractionOperation(theme, operation, num1, den1, num2, den2, answer: answer);
            case 1:
              operation = '-';
              answer = _calculateFractionSubtraction(num1, den1, num2, den2);
              return MathTask.fractionOperation(theme, operation, num1, den1, num2, den2, answer: answer);
            case 2:
              operation = '×';
              answer = _calculateFractionMultiplication(num1, den1, num2, den2);
              return MathTask.fractionOperation(theme, operation, num1, den1, num2, den2, answer: answer);
            case 3:
              operation = '÷';
              answer = _calculateFractionDivision(num1, den1, num2, den2);
              return MathTask.fractionOperation(theme, operation, num1, den1, num2, den2, answer: answer);
            default:
              return MathTask.simple(theme, 'Ошибка в генерации дробей');
          }
        } else {
          String answer = '$num1/$den1';
          return MathTask.fraction(theme, num1, den1, answer: answer);
        }

      case 'Десятичные дроби':
        double a = allowNegatives ? (_random.nextInt(range * 2) - range).toDouble() : _random.nextInt(range).toDouble();
        double b = allowNegatives ? (_random.nextInt(range * 2) - range).toDouble() : _random.nextInt(range).toDouble();
        a = double.parse((a + _random.nextDouble()).toStringAsFixed(2));
        b = double.parse((b + _random.nextDouble()).toStringAsFixed(2));
        if (isComplex) {
          int choice = _random.nextInt(4);
          switch (choice) {
            case 0:
              return MathTask.simple(theme, 'Найдите сумму: $a + $b', answer: (a + b).toStringAsFixed(2));
            case 1:
              return MathTask.simple(theme, 'Найдите разность: $a - $b', answer: (a - b).toStringAsFixed(2));
            case 2:
              return MathTask.simple(theme, 'Найдите произведение: $a × $b', answer: (a * b).toStringAsFixed(2));
            case 3:
              return MathTask.simple(theme, 'Найдите частное: $a ÷ $b', answer: (a / b).toStringAsFixed(2));
            default:
              return MathTask.simple(theme, 'Ошибка в десятичных дробях');
          }
        } else {
          return MathTask.simple(theme, 'Запишите число как десятичную дробь: $a', answer: a.toStringAsFixed(2));
        }

      case 'Натуральные числа':
        int a = _random.nextInt(range) + 1;
        int b = _random.nextInt(range) + 1;
        if (isComplex) {
          int choice = _random.nextInt(4);
          switch (choice) {
            case 0:
              return MathTask.simple(theme, 'Найдите сумму: $a + $b', answer: '${a + b}');
            case 1:
              return MathTask.simple(theme, 'Найдите разность: $a - $b', answer: '${a - b}');
            case 2:
              return MathTask.simple(theme, 'Найдите произведение: $a × $b', answer: '${a * b}');
            case 3:
              return MathTask.simple(theme, 'Найдите частное: $a ÷ $b (округлите до целого)', answer: '${(a / b).round()}');
            default:
              return MathTask.simple(theme, 'Ошибка в натуральных числах');
          }
        } else {
          return MathTask.simple(theme, 'Найдите сумму: $a + $b', answer: '${a + b}');
        }

      case 'Рациональные числа':
        int a = _random.nextInt(range) + 1;
        int b = allowNegatives ? _random.nextInt(range * 2) - range : _random.nextInt(range);
        int c = allowNegatives ? _random.nextInt(range * 2) - range : _random.nextInt(range);
        if (isComplex) {
          String answer = _solveQuadratic(a, b, c);
          return MathTask.equation(theme, '${a}x² + ${b}x', '$c', answer: answer);
        } else {
          String answer = _solveLinear(a, b, c);
          return MathTask.equation(theme, '${a}x + $b', '$c', answer: answer);
        }

      case 'Преобразование буквенных выражений':
        int a = _random.nextInt(range) + 1;
        int b = _random.nextInt(range) + 1;
        if (isComplex) {
          return MathTask.simple(theme, 'Упростите выражение: (${a}x + $b) - (${a}x - $b)', answer: '${2 * b}');
        } else {
          return MathTask.simple(theme, 'Упростите выражение: ${a}x + ${b}x', answer: '${a + b}x');
        }

      case 'Одночлены':
        int coef = _random.nextInt(range) + 1;
        int exp = _random.nextInt(4) + 1;
        if (isComplex) {
          int coef2 = _random.nextInt(range) + 1;
          return MathTask.simple(theme, 'Умножьте одночлены: ${coef}x^$exp * ${coef2}x^2', answer: '${coef * coef2}x^${exp + 2}');
        } else {
          return MathTask.power(theme, coef, exp, answer: '${pow(coef, exp)}');
        }

      case 'Многочлены':
        int a = _random.nextInt(range) + 1;
        int b = _random.nextInt(range) + 1;
        if (isComplex) {
          int c = _random.nextInt(range) + 1;
          return MathTask.simple(theme, 'Упростите: (${a}x² + ${b}x + $c) + (${a}x² - ${b}x)', answer: '${2 * a}x² + $c');
        } else {
          return MathTask.simple(theme, 'Упростите: ${a}x² + ${b}x', answer: '${a}x² + ${b}x');
        }

      case 'Квадратичная функция':
        int a = _random.nextInt(range) + 1;
        int b = allowNegatives ? _random.nextInt(range * 2) - range : _random.nextInt(range);
        int c = allowNegatives ? _random.nextInt(range * 2) - range : _random.nextInt(range);
        String answer = _solveQuadratic(a, b, c);
        return MathTask.equation(theme, '${a}x² + ${b}x + $c', '0', answer: answer);

      case 'Алгебраические дроби':
        int num = _random.nextInt(range) + 1;
        int den = _random.nextInt(range) + 1;
        if (isComplex) {
          int num2 = _random.nextInt(range) + 1;
          int den2 = _random.nextInt(range) + 1;
          String answer = _calculateFractionMultiplication(num, den, num2, den2);
          return MathTask.fractionOperation(theme, '×', num, den, num2, den2, answer: answer);
        } else {
          return MathTask.fraction(theme, num, den, answer: '$num/$den');
        }

      case 'Неравенства':
        int a = _random.nextInt(range) + 1;
        int b = allowNegatives ? _random.nextInt(range * 2) - range : _random.nextInt(range);
        if (isComplex) {
          String answer = a > 0 ? 'x > ${-b / a}' : 'x < ${-b / a}';
          return MathTask.equation(theme, '${a}x + $b', '0', answer: answer);
        } else {
          String answer = _solveLinear(a, b, 0);
          return MathTask.equation(theme, '${a}x', '$b', answer: answer);
        }

      case 'Квадратные уравнения':
        int a = _random.nextInt(range) + 1;
        int b = allowNegatives ? _random.nextInt(range * 2) - range : _random.nextInt(range);
        int c = allowNegatives ? _random.nextInt(range * 2) - range : _random.nextInt(range);
        String answer = _solveQuadratic(a, b, c);
        return MathTask.equation(theme, '${a}x² + ${b}x + $c', '0', answer: answer);

      case 'Системы уравнений':
        int a1 = _random.nextInt(range) + 1;
        int b1 = _random.nextInt(range) + 1;
        int c1 = _random.nextInt(range) + 1;
        int a2 = _random.nextInt(range) + 1;
        int b2 = _random.nextInt(range) + 1;
        int c2 = _random.nextInt(range) + 1;
        String answer = _solveSystem(a1, b1, c1, a2, b2, c2);
        return MathTask.simple(theme, 'Решите систему: ${a1}x + ${b1}y = $c1, ${a2}x + ${b2}y = $c2', answer: answer);

      case 'Числовые функции':
        int a = _random.nextInt(range) + 1;
        return MathTask.simple(theme, 'Найдите значение функции f(x) = ${a}x при x = 2', answer: '${a * 2}');

      case 'Тригонометрические уравнения':
        int coef = _random.nextInt(range) + 1;
        String func = _random.nextBool() ? 'sin' : 'cos';
        String answer = func == 'sin' ? 'pi/2' : '0'; // Заменяем π на pi
        return MathTask.trig(theme, func, coef, 'x', answer: 'x = $answer');

      case 'Действительные числа':
        double a = allowNegatives ? (_random.nextInt(range * 2) - range).toDouble() : _random.nextInt(range).toDouble();
        return MathTask.simple(theme, 'Найдите модуль числа: $a', answer: '${a.abs()}');

      case 'Степенные функции':
        int base = _random.nextInt(range) + 1;
        int exp = _random.nextInt(4) + 1;
        int result = pow(base, exp).toInt();
        return MathTask.power(theme, base, exp, answer: '$base^$exp = $result');

      case 'Логарифмы':
        int base = _random.nextInt(range - 1) + 2; // base > 1
        int arg = _random.nextInt(4) + 1;
        int argument = pow(base, arg).toInt();
        return MathTask.logarithm(theme, base, argument, answer: 'log_$base($argument) = $arg');

      case 'Производная':
        int a = _random.nextInt(range) + 1;
        int b = _random.nextInt(range) + 1;
        return MathTask.simple(theme, 'Найдите производную: f(x) = ${a}x² + ${b}x', answer: '${2 * a}x + $b');

      case 'Задачи по теории вероятностей':
        int total = _random.nextInt(range) + 1;
        int favorable = _random.nextInt(total) + 1;
        return MathTask.simple(theme, 'Найдите вероятность (в долях): $favorable из $total', answer: '${favorable / total}');

      case 'Неравенства и системы неравенств':
        int a = _random.nextInt(range) + 1;
        int b = allowNegatives ? _random.nextInt(range * 2) - range : _random.nextInt(range);
        String answer = a > 0 ? 'x > ${-b / a}' : 'x < ${-b / a}';
        return MathTask.equation(theme, '${a}x + $b', '0', answer: answer);

      default:
        return MathTask.simple(theme, 'Ошибка: нет шаблона для темы "$theme"');
    }
  }

  static String _calculateFractionAddition(int num1, int den1, int num2, int den2) {
    int resultNum = num1 * den2 + num2 * den1;
    int resultDen = den1 * den2;
    return '$resultNum/$resultDen';
  }

  static String _calculateFractionSubtraction(int num1, int den1, int num2, int den2) {
    int resultNum = num1 * den2 - num2 * den1;
    int resultDen = den1 * den2;
    return '$resultNum/$resultDen';
  }

  static String _calculateFractionMultiplication(int num1, int den1, int num2, int den2) {
    int resultNum = num1 * num2;
    int resultDen = den1 * den2;
    return '$resultNum/$resultDen';
  }

  static String _calculateFractionDivision(int num1, int den1, int num2, int den2) {
    int resultNum = num1 * den2;
    int resultDen = den1 * num2;
    return '$resultNum/$resultDen';
  }

  static String _solveLinear(int a, int b, int c) {
    double x = (c - b) / a.toDouble();
    return 'x = ${x.toStringAsFixed(2)}';
  }

  static String _solveQuadratic(int a, int b, int c) {
    double discriminant = (b * b - 4 * a * c).toDouble();
    if (discriminant < 0) return 'Нет действительных корней';
    double x1 = (-b + sqrt(discriminant)) / (2 * a);
    double x2 = (-b - sqrt(discriminant)) / (2 * a);
    return 'x1 = ${x1.toStringAsFixed(2)}, x2 = ${x2.toStringAsFixed(2)}';
  }

  static String _solveSystem(int a1, int b1, int c1, int a2, int b2, int c2) {
    double det = (a1 * b2 - a2 * b1).toDouble(); // Приводим результат к double
    if (det == 0) return 'Нет единственного решения';
    double x = (c1 * b2 - c2 * b1) / det;
    double y = (a1 * c2 - a2 * c1) / det;
    return 'x = ${x.toStringAsFixed(2)}, y = ${y.toStringAsFixed(2)}';
  }

  static List<List<MathTask>> generateTaskVariants(Map<String, int> selectedThemes, int variantCount,
      {required String difficulty, required int maxNumber, required bool allowNegatives}) {
    List<List<MathTask>> variants = [];
    for (int i = 0; i < variantCount; i++) {
      List<MathTask> tasks = [];
      for (var entry in selectedThemes.entries) {
        String theme = entry.key;
        int count = entry.value;
        for (int j = 0; j < count; j++) {
          tasks.add(generateTask(theme, difficulty: difficulty, maxNumber: maxNumber, allowNegatives: allowNegatives));
        }
      }
      variants.add(tasks);
    }
    return variants;
  }
}
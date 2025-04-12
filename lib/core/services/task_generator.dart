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

  factory MathTask.fraction(
    String theme,
    int numerator,
    int denominator, {
    String? answer,
  }) {
    return MathTask(
      theme: theme,
      structure: {
        'type': 'fraction',
        'numerator': numerator,
        'denominator': denominator,
      },
      answer: answer,
    );
  }

  factory MathTask.fractionOperation(
    String theme,
    String operation,
    int num1,
    int den1,
    int num2,
    int den2, {
    String? answer,
  }) {
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

  factory MathTask.power(
    String theme,
    int base,
    int exponent, {
    String? answer,
  }) {
    return MathTask(
      theme: theme,
      structure: {'type': 'power', 'base': base, 'exponent': exponent},
      answer: answer,
    );
  }

  factory MathTask.root(
    String theme,
    int radicand,
    int index, {
    String? answer,
  }) {
    return MathTask(
      theme: theme,
      structure: {'type': 'root', 'radicand': radicand, 'index': index},
      answer: answer,
    );
  }

  factory MathTask.logarithm(
    String theme,
    int base,
    int argument, {
    String? answer,
  }) {
    return MathTask(
      theme: theme,
      structure: {'type': 'logarithm', 'base': base, 'argument': argument},
      answer: answer,
    );
  }

  factory MathTask.trig(
    String theme,
    String function,
    int coefficient,
    String argument, {
    String? answer,
  }) {
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

  factory MathTask.equation(
    String theme,
    String expression,
    String rightSide, {
    String? answer,
  }) {
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

  static MathTask generateTask(
    String theme, {
    required String difficulty,
    required int maxNumber,
    required bool allowNegatives,
  }) {
    bool isComplex = difficulty == 'complex';
    int range = maxNumber > 0 ? maxNumber : (isComplex ? 20 : 10);

    switch (theme) {
      case 'Обыкновенные дроби':
        int num1 = _random.nextInt(range) + 1;
        int den1 = _random.nextInt(range) + 1;
        int num2 = _random.nextInt(range) + 1;
        int den2 = _random.nextInt(range) + 1;
        if (isComplex) {
          int choice = _random.nextInt(6);
          String operation;
          String answer;
          switch (choice) {
            case 0:
              operation = '+';
              answer = _calculateFractionAddition(num1, den1, num2, den2);
              return MathTask.fractionOperation(
                theme,
                operation,
                num1,
                den1,
                num2,
                den2,
                answer: answer,
              );
            case 1:
              operation = '-';
              answer = _calculateFractionSubtraction(num1, den1, num2, den2);
              return MathTask.fractionOperation(
                theme,
                operation,
                num1,
                den1,
                num2,
                den2,
                answer: answer,
              );
            case 2:
              operation = '×';
              answer = _calculateFractionMultiplication(num1, den1, num2, den2);
              return MathTask.fractionOperation(
                theme,
                operation,
                num1,
                den1,
                num2,
                den2,
                answer: answer,
              );
            case 3:
              operation = '÷';
              answer = _calculateFractionDivision(num1, den1, num2, den2);
              return MathTask.fractionOperation(
                theme,
                operation,
                num1,
                den1,
                num2,
                den2,
                answer: answer,
              );
            case 4:
              String comparison = num1 * den2 > num2 * den1 ? '>' : '<';
              answer = '$num1/$den1 $comparison $num2/$den2';
              return MathTask.simple(
                theme,
                'Сравните дроби: $num1/$den1 и $num2/$den2',
                answer: answer,
              );
            case 5:
              int lcm = _findLCM(den1, den2);
              answer =
                  '${num1 * (lcm ~/ den1)}/$lcm и ${num2 * (lcm ~/ den2)}/$lcm';
              return MathTask.simple(
                theme,
                'Приведите дроби $num1/$den1 и $num2/$den2 к общему знаменателю',
                answer: answer,
              );
            default:
              return MathTask.simple(theme, 'Ошибка в генерации дробей');
          }
        } else {
          int choice = _random.nextInt(3);
          switch (choice) {
            case 0:
              return MathTask.fraction(
                theme,
                num1,
                den1,
                answer: '$num1/$den1',
              );
            case 1:
              return MathTask.simple(
                theme,
                'Сократите дробь: ${num1 * 2}/${den1 * 2}',
                answer: '$num1/$den1',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Запишите число $num1 в виде дроби со знаменателем $den1',
                answer: '$num1/$den1',
              );
            default:
              return MathTask.fraction(
                theme,
                num1,
                den1,
                answer: '$num1/$den1',
              );
          }
        }

      case 'Десятичные дроби':
        double a =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        double b =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        a = double.parse((a + _random.nextDouble()).toStringAsFixed(2));
        b = double.parse((b + _random.nextDouble()).toStringAsFixed(2));
        if (isComplex) {
          int choice = _random.nextInt(6);
          switch (choice) {
            case 0:
              return MathTask.simple(
                theme,
                'Найдите сумму: $a + $b',
                answer: (a + b).toStringAsFixed(2),
              );
            case 1:
              return MathTask.simple(
                theme,
                'Найдите разность: $a - $b',
                answer: (a - b).toStringAsFixed(2),
              );
            case 2:
              return MathTask.simple(
                theme,
                'Найдите произведение: $a × $b',
                answer: (a * b).toStringAsFixed(2),
              );
            case 3:
              return MathTask.simple(
                theme,
                'Найдите частное: $a ÷ $b',
                answer: (a / b).toStringAsFixed(2),
              );
            case 4:
              return MathTask.simple(
                theme,
                'Округлите число $a до целых',
                answer: a.round().toString(),
              );
            case 5:
              String comparison = a > b ? '>' : '<';
              return MathTask.simple(
                theme,
                'Сравните числа: $a и $b',
                answer: '$a $comparison $b',
              );
            default:
              return MathTask.simple(theme, 'Ошибка в десятичных дробях');
          }
        } else {
          int choice = _random.nextInt(3);
          switch (choice) {
            case 0:
              return MathTask.simple(
                theme,
                'Запишите число как десятичную дробь: $a',
                answer: a.toStringAsFixed(2),
              );
            case 1:
              return MathTask.simple(
                theme,
                'Округлите число $a до одного знака после запятой',
                answer: a.toStringAsFixed(1),
              );
            case 2:
              return MathTask.simple(
                theme,
                'Запишите число $a в виде обыкновенной дроби',
                answer: '${(a * 100).round()}/100',
              );
            default:
              return MathTask.simple(
                theme,
                'Запишите число как десятичную дробь: $a',
                answer: a.toStringAsFixed(2),
              );
          }
        }

      case 'Натуральные числа':
        int a = _random.nextInt(range) + 1;
        int b = _random.nextInt(range) + 1;
        if (isComplex) {
          int choice = _random.nextInt(6);
          switch (choice) {
            case 0:
              return MathTask.simple(
                theme,
                'Найдите сумму: $a + $b',
                answer: '${a + b}',
              );
            case 1:
              return MathTask.simple(
                theme,
                'Найдите разность: $a - $b',
                answer: '${a - b}',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Найдите произведение: $a × $b',
                answer: '${a * b}',
              );
            case 3:
              return MathTask.simple(
                theme,
                'Найдите частное: $a ÷ $b (округлите до целого)',
                answer: '${(a / b).round()}',
              );
            case 4:
              int gcd = _findGCD(a, b);
              return MathTask.simple(
                theme,
                'Найдите наибольший общий делитель чисел $a и $b',
                answer: '$gcd',
              );
            case 5:
              int lcm = _findLCM(a, b);
              return MathTask.simple(
                theme,
                'Найдите наименьшее общее кратное чисел $a и $b',
                answer: '$lcm',
              );
            default:
              return MathTask.simple(theme, 'Ошибка в натуральных числах');
          }
        } else {
          int choice = _random.nextInt(4);
          switch (choice) {
            case 0:
              return MathTask.simple(
                theme,
                'Найдите сумму: $a + $b',
                answer: '${a + b}',
              );
            case 1:
              return MathTask.simple(
                theme,
                'Запишите число $a в виде суммы двух натуральных чисел',
                answer: '${a - 1} + 1',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Разложите число $a на простые множители',
                answer: _factorize(a),
              );
            case 3:
              return MathTask.simple(
                theme,
                'Является ли число $a четным?',
                answer: a % 2 == 0 ? 'Да' : 'Нет',
              );
            default:
              return MathTask.simple(
                theme,
                'Найдите сумму: $a + $b',
                answer: '${a + b}',
              );
          }
        }

      case 'Рациональные числа':
        double a = (_random.nextInt(range) + 1).toDouble();
        double b =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        double c =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        if (isComplex) {
          int choice = _random.nextInt(5);
          switch (choice) {
            case 0:
              String answer = _solveQuadratic(a, b, c);
              return MathTask.equation(
                theme,
                '${a}x² + ${b}x',
                '$c',
                answer: answer,
              );
            case 1:
              return MathTask.simple(
                theme,
                'Найдите модуль числа: $b',
                answer: '${b.abs()}',
              );
            case 2:
              String comparison = b > c ? '>' : '<';
              return MathTask.simple(
                theme,
                'Сравните числа: $b и $c',
                answer: '$b $comparison $c',
              );
            case 3:
              return MathTask.simple(
                theme,
                'Найдите число, противоположное $b',
                answer: '${-b}',
              );
            case 4:
              return MathTask.simple(
                theme,
                'Найдите число, обратное $b',
                answer: '${1 / b}',
              );
            default:
              String answer = _solveQuadratic(a, b, c);
              return MathTask.equation(
                theme,
                '${a}x² + ${b}x',
                '$c',
                answer: answer,
              );
          }
        } else {
          int choice = _random.nextInt(3);
          switch (choice) {
            case 0:
              String answer = _solveLinear(a, b, c);
              return MathTask.equation(
                theme,
                '${a}x + $b',
                '$c',
                answer: answer,
              );
            case 1:
              return MathTask.simple(
                theme,
                'Найдите модуль числа: $b',
                answer: '${b.abs()}',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Запишите число $b в виде дроби со знаменателем $a',
                answer: '${b * a}/$a',
              );
            default:
              String answer = _solveLinear(a, b, c);
              return MathTask.equation(
                theme,
                '${a}x + $b',
                '$c',
                answer: answer,
              );
          }
        }

      case 'Преобразование буквенных выражений':
        int a = _random.nextInt(range) + 1;
        int b = _random.nextInt(range) + 1;
        if (isComplex) {
          int choice = _random.nextInt(6);
          switch (choice) {
            case 0:
              return MathTask.simple(
                theme,
                'Упростите выражение: (${a}x + $b) - (${a}x - $b)',
                answer: '${2 * b}',
              );
            case 1:
              return MathTask.simple(
                theme,
                'Раскройте скобки: ${a}(x + $b)',
                answer: '${a}x + ${a * b}',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Вынесите общий множитель: ${a * b}x + ${a * b}y',
                answer: '${a * b}(x + y)',
              );
            case 3:
              return MathTask.simple(
                theme,
                'Приведите подобные: ${a}x + ${b}x + ${a}y',
                answer: '${a + b}x + ${a}y',
              );
            case 4:
              return MathTask.simple(
                theme,
                'Упростите: (x + $a)(x + $b)',
                answer: 'x² + ${a + b}x + ${a * b}',
              );
            case 5:
              return MathTask.simple(
                theme,
                'Упростите: (x + $a)²',
                answer: 'x² + ${2 * a}x + ${a * a}',
              );
            default:
              return MathTask.simple(
                theme,
                'Упростите выражение: ${a}x + ${b}x',
                answer: '${a + b}x',
              );
          }
        } else {
          int choice = _random.nextInt(4);
          switch (choice) {
            case 0:
              return MathTask.simple(
                theme,
                'Упростите выражение: ${a}x + ${b}x',
                answer: '${a + b}x',
              );
            case 1:
              return MathTask.simple(
                theme,
                'Раскройте скобки: ${a}(x + y)',
                answer: '${a}x + ${a}y',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Вынесите общий множитель: ${a}x + ${a}y',
                answer: '${a}(x + y)',
              );
            case 3:
              return MathTask.simple(
                theme,
                'Приведите подобные: ${a}x + ${b}x',
                answer: '${a + b}x',
              );
            default:
              return MathTask.simple(
                theme,
                'Упростите выражение: ${a}x + ${b}x',
                answer: '${a + b}x',
              );
          }
        }

      case 'Одночлены':
        int coef = _random.nextInt(range) + 1;
        int exp = _random.nextInt(4) + 1;
        if (isComplex) {
          int choice = _random.nextInt(6);
          switch (choice) {
            case 0:
              int coef2 = _random.nextInt(range) + 1;
              return MathTask.simple(
                theme,
                'Умножьте одночлены: ${coef}x^$exp * ${coef2}x^2',
                answer: '${coef * coef2}x^${exp + 2}',
              );
            case 1:
              int coef2 = _random.nextInt(range) + 1;
              return MathTask.simple(
                theme,
                'Разделите одночлены: ${coef * coef2}x^${exp + 2} ÷ ${coef2}x^2',
                answer: '${coef}x^$exp',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Возведите в степень: (${coef}x^$exp)²',
                answer: '${coef * coef}x^${exp * 2}',
              );
            case 3:
              return MathTask.simple(
                theme,
                'Приведите к стандартному виду: ${coef * 2}x^${exp + 1} * x^${exp - 1}',
                answer: '${2 * coef}x^${2 * exp}',
              );
            case 4:
              int coef2 = _random.nextInt(range) + 1;
              String comparison = coef > coef2 ? '>' : '<';
              return MathTask.simple(
                theme,
                'Сравните одночлены: ${coef}x^$exp и ${coef2}x^$exp',
                answer: '${coef}x^$exp $comparison ${coef2}x^$exp',
              );
            case 5:
              return MathTask.simple(
                theme,
                'Найдите степень одночлена: ${coef}x^$exp',
                answer: '$exp',
              );
            default:
              return MathTask.power(
                theme,
                coef,
                exp,
                answer: '${pow(coef, exp)}',
              );
          }
        } else {
          int choice = _random.nextInt(4);
          switch (choice) {
            case 0:
              return MathTask.power(
                theme,
                coef,
                exp,
                answer: '${pow(coef, exp)}',
              );
            case 1:
              return MathTask.simple(
                theme,
                'Запишите одночлен в стандартном виде: ${coef * 2}x^${exp + 1} * x^${exp - 1}',
                answer: '${2 * coef}x^${2 * exp}',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Найдите коэффициент одночлена: ${coef}x^$exp',
                answer: '$coef',
              );
            case 3:
              return MathTask.simple(
                theme,
                'Найдите степень одночлена: ${coef}x^$exp',
                answer: '$exp',
              );
            default:
              return MathTask.power(
                theme,
                coef,
                exp,
                answer: '${pow(coef, exp)}',
              );
          }
        }

      case 'Многочлены':
        int a = _random.nextInt(range) + 1;
        int b = _random.nextInt(range) + 1;
        if (isComplex) {
          int choice = _random.nextInt(6);
          switch (choice) {
            case 0:
              int c = _random.nextInt(range) + 1;
              return MathTask.simple(
                theme,
                'Упростите: (${a}x² + ${b}x + $c) + (${a}x² - ${b}x)',
                answer: '${2 * a}x² + $c',
              );
            case 1:
              return MathTask.simple(
                theme,
                'Умножьте: (x + $a)(x + $b)',
                answer: 'x² + ${a + b}x + ${a * b}',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Разделите: (${a * b}x² + ${a * b}x) ÷ ${b}x',
                answer: '${a}x + $a',
              );
            case 3:
              return MathTask.simple(
                theme,
                'Разложите на множители: x² - ${a * a}',
                answer: '(x + $a)(x - $a)',
              );
            case 4:
              return MathTask.simple(
                theme,
                'Вынесите общий множитель: ${a * b}x² + ${a * b}x',
                answer: '${a * b}x(x + 1)',
              );
            case 5:
              return MathTask.simple(
                theme,
                'Приведите подобные: ${a}x² + ${b}x² + ${a}x + ${b}x',
                answer: '${a + b}x² + ${a + b}x',
              );
            default:
              return MathTask.simple(
                theme,
                'Упростите: ${a}x² + ${b}x',
                answer: '${a}x² + ${b}x',
              );
          }
        } else {
          int choice = _random.nextInt(4);
          switch (choice) {
            case 0:
              return MathTask.simple(
                theme,
                'Упростите: ${a}x² + ${b}x',
                answer: '${a}x² + ${b}x',
              );
            case 1:
              return MathTask.simple(
                theme,
                'Приведите подобные: ${a}x² + ${b}x²',
                answer: '${a + b}x²',
              );
            case 2:
              return MathTask.simple(
                theme,
                'Вынесите общий множитель: ${a * b}x + ${a * b}',
                answer: '${a * b}(x + 1)',
              );
            case 3:
              return MathTask.simple(
                theme,
                'Раскройте скобки: ${a}(x + $b)',
                answer: '${a}x + ${a * b}',
              );
            default:
              return MathTask.simple(
                theme,
                'Упростите: ${a}x² + ${b}x',
                answer: '${a}x² + ${b}x',
              );
          }
        }

      case 'Квадратичная функция':
        double a = (_random.nextInt(range) + 1).toDouble();
        double b =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        double c =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        if (isComplex) {
          int choice = _random.nextInt(6);
          switch (choice) {
            case 0:
              String answer = _solveQuadratic(a, b, c);
              return MathTask.equation(
                theme,
                '${a}x² + ${b}x + $c',
                '0',
                answer: answer,
              );
            case 1:
              double x0 = -b / (2 * a);
              double y0 = (a * x0 * x0 + b * x0 + c).toDouble();
              return MathTask.simple(
                theme,
                'Найдите координаты вершины параболы y = ${a}x² + ${b}x + $c',
                answer: '(${x0.toStringAsFixed(2)}, ${y0.toStringAsFixed(2)})',
              );
            case 2:
              double x0 = -b / (2 * a);
              return MathTask.simple(
                theme,
                'Найдите уравнение оси симметрии параболы y = ${a}x² + ${b}x + $c',
                answer: 'x = ${x0.toStringAsFixed(2)}',
              );
            case 3:
              String direction = a > 0 ? 'вверх' : 'вниз';
              return MathTask.simple(
                theme,
                'Определите направление ветвей параболы y = ${a}x² + ${b}x + $c',
                answer: direction,
              );
            case 4:
              return MathTask.simple(
                theme,
                'Найдите точку пересечения параболы y = ${a}x² + ${b}x + $c с осью Oy',
                answer: '(0, $c)',
              );
            case 5:
              double discriminant = b * b - 4 * a * c;
              return MathTask.simple(
                theme,
                'Найдите дискриминант квадратного уравнения ${a}x² + ${b}x + $c = 0',
                answer: discriminant.toStringAsFixed(2),
              );
            default:
              String answer = _solveQuadratic(a, b, c);
              return MathTask.equation(
                theme,
                '${a}x² + ${b}x + $c',
                '0',
                answer: answer,
              );
          }
        } else {
          int choice = _random.nextInt(4);
          switch (choice) {
            case 0:
              String answer = _solveQuadratic(a, b, c);
              return MathTask.equation(
                theme,
                '${a}x² + ${b}x + $c',
                '0',
                answer: answer,
              );
            case 1:
              int x = _random.nextInt(5) - 2;
              double y = (a * x * x + b * x + c).toDouble();
              return MathTask.simple(
                theme,
                'Найдите значение функции y = ${a}x² + ${b}x + $c при x = $x',
                answer: y.toStringAsFixed(2),
              );
            case 2:
              String direction = a > 0 ? 'вверх' : 'вниз';
              return MathTask.simple(
                theme,
                'Определите направление ветвей параболы y = ${a}x² + ${b}x + $c',
                answer: direction,
              );
            case 3:
              return MathTask.simple(
                theme,
                'Найдите точку пересечения параболы y = ${a}x² + ${b}x + $c с осью Oy',
                answer: '(0, $c)',
              );
            default:
              String answer = _solveQuadratic(a, b, c);
              return MathTask.equation(
                theme,
                '${a}x² + ${b}x + $c',
                '0',
                answer: answer,
              );
          }
        }

      case 'Алгебраические дроби':
        int num = _random.nextInt(range) + 1;
        int den = _random.nextInt(range) + 1;
        if (isComplex) {
          int num2 = _random.nextInt(range) + 1;
          int den2 = _random.nextInt(range) + 1;
          String answer = _calculateFractionMultiplication(
            num,
            den,
            num2,
            den2,
          );
          return MathTask.fractionOperation(
            theme,
            '×',
            num,
            den,
            num2,
            den2,
            answer: answer,
          );
        } else {
          return MathTask.fraction(theme, num, den, answer: '$num/$den');
        }

      case 'Неравенства':
        int a = _random.nextInt(range) + 1;
        int b =
            allowNegatives
                ? _random.nextInt(range * 2) - range
                : _random.nextInt(range);
        if (isComplex) {
          String answer = a > 0 ? 'x > ${-b / a}' : 'x < ${-b / a}';
          return MathTask.equation(theme, '${a}x + $b', '0', answer: answer);
        } else {
          String answer = _solveLinear(a.toDouble(), b.toDouble(), 0.0);
          return MathTask.equation(theme, '${a}x', '$b', answer: answer);
        }

      case 'Квадратные уравнения':
        double a = (_random.nextInt(range) + 1).toDouble();
        double b =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        double c =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        String answer = _solveQuadratic(a, b, c);
        return MathTask.equation(
          theme,
          '${a}x² + ${b}x + $c',
          '0',
          answer: answer,
        );

      case 'Системы уравнений':
        int a1 = _random.nextInt(range) + 1;
        int b1 = _random.nextInt(range) + 1;
        int c1 = _random.nextInt(range) + 1;
        int a2 = _random.nextInt(range) + 1;
        int b2 = _random.nextInt(range) + 1;
        int c2 = _random.nextInt(range) + 1;
        String answer = _solveSystem(a1, b1, c1, a2, b2, c2);
        return MathTask.simple(
          theme,
          'Решите систему: ${a1}x + ${b1}y = $c1, ${a2}x + ${b2}y = $c2',
          answer: answer,
        );

      case 'Числовые функции':
        int a = _random.nextInt(range) + 1;
        return MathTask.simple(
          theme,
          'Найдите значение функции f(x) = ${a}x при x = 2',
          answer: '${a * 2}',
        );

      case 'Тригонометрические уравнения':
        int coef = _random.nextInt(range) + 1;
        String func = _random.nextBool() ? 'sin' : 'cos';
        String answer = func == 'sin' ? 'pi/2' : '0'; // Заменяем π на pi
        return MathTask.trig(theme, func, coef, 'x', answer: 'x = $answer');

      case 'Действительные числа':
        double a =
            allowNegatives
                ? (_random.nextInt(range * 2) - range).toDouble()
                : _random.nextInt(range).toDouble();
        return MathTask.simple(
          theme,
          'Найдите модуль числа: $a',
          answer: '${a.abs()}',
        );

      case 'Степенные функции':
        int base = _random.nextInt(range) + 1;
        int exp = _random.nextInt(4) + 1;
        int result = pow(base, exp).toInt();
        return MathTask.power(theme, base, exp, answer: '$base^$exp = $result');

      case 'Логарифмы':
        int base = _random.nextInt(range - 1) + 2; // base > 1
        int arg = _random.nextInt(4) + 1;
        int argument = pow(base, arg).toInt();
        return MathTask.logarithm(
          theme,
          base,
          argument,
          answer: 'log_$base($argument) = $arg',
        );

      case 'Производная':
        int a = _random.nextInt(range) + 1;
        int b = _random.nextInt(range) + 1;
        return MathTask.simple(
          theme,
          'Найдите производную: f(x) = ${a}x² + ${b}x',
          answer: '${2 * a}x + $b',
        );

      case 'Задачи по теории вероятностей':
        int total = _random.nextInt(range) + 1;
        int favorable = _random.nextInt(total) + 1;
        return MathTask.simple(
          theme,
          'Найдите вероятность (в долях): $favorable из $total',
          answer: '${favorable / total}',
        );

      case 'Неравенства и системы неравенств':
        int a = _random.nextInt(range) + 1;
        int b =
            allowNegatives
                ? _random.nextInt(range * 2) - range
                : _random.nextInt(range);
        String answer = a > 0 ? 'x > ${-b / a}' : 'x < ${-b / a}';
        return MathTask.equation(theme, '${a}x + $b', '0', answer: answer);

      default:
        return MathTask.simple(theme, 'Ошибка: нет шаблона для темы "$theme"');
    }
  }

  static String _calculateFractionAddition(
    int num1,
    int den1,
    int num2,
    int den2,
  ) {
    int resultNum = num1 * den2 + num2 * den1;
    int resultDen = den1 * den2;
    return '$resultNum/$resultDen';
  }

  static String _calculateFractionSubtraction(
    int num1,
    int den1,
    int num2,
    int den2,
  ) {
    int resultNum = num1 * den2 - num2 * den1;
    int resultDen = den1 * den2;
    return '$resultNum/$resultDen';
  }

  static String _calculateFractionMultiplication(
    int num1,
    int den1,
    int num2,
    int den2,
  ) {
    int resultNum = num1 * num2;
    int resultDen = den1 * den2;
    return '$resultNum/$resultDen';
  }

  static String _calculateFractionDivision(
    int num1,
    int den1,
    int num2,
    int den2,
  ) {
    int resultNum = num1 * den2;
    int resultDen = den1 * num2;
    return '$resultNum/$resultDen';
  }

  static String _solveLinear(double a, double b, double c) {
    double x = (c - b) / a;
    return 'x = ${x.toStringAsFixed(2)}';
  }

  static String _solveQuadratic(double a, double b, double c) {
    double discriminant = b * b - 4 * a * c;
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

  static List<List<MathTask>> generateTaskVariants(
    Map<String, int> selectedThemes,
    int variantCount, {
    required String difficulty,
    required int maxNumber,
    required bool allowNegatives,
  }) {
    List<List<MathTask>> variants = [];
    for (int i = 0; i < variantCount; i++) {
      List<MathTask> tasks = [];
      for (var entry in selectedThemes.entries) {
        String theme = entry.key;
        int count = entry.value;
        for (int j = 0; j < count; j++) {
          tasks.add(
            generateTask(
              theme,
              difficulty: difficulty,
              maxNumber: maxNumber,
              allowNegatives: allowNegatives,
            ),
          );
        }
      }
      variants.add(tasks);
    }
    return variants;
  }

  static int _findLCM(int a, int b) {
    return (a * b) ~/ _findGCD(a, b);
  }

  static int _findGCD(int a, int b) {
    while (b != 0) {
      int temp = b;
      b = a % b;
      a = temp;
    }
    return a;
  }

  static String _factorize(int n) {
    List<int> factors = [];
    int divisor = 2;

    while (n > 1) {
      while (n % divisor == 0) {
        factors.add(divisor);
        n ~/= divisor;
      }
      divisor++;
      if (divisor * divisor > n) {
        if (n > 1) factors.add(n);
        break;
      }
    }

    return factors.join(' × ');
  }
}

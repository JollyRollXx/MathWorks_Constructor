// widgets/input_fields.dart
import 'package:flutter/material.dart';

class InputTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType; // Новый параметр

  const InputTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.validator,
    this.keyboardType, // Добавляем в конструктор
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      validator: validator,
      keyboardType: keyboardType, // Передаем в TextFormField
    );
  }
}

// Остальные классы (ClassDropdown, ThemeDropdown) остаются без изменений
class ClassDropdown extends StatelessWidget {
  final int selectedClass;
  final Function(int?)? onChanged;

  const ClassDropdown({super.key, required this.selectedClass, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      value: selectedClass,
      decoration: InputDecoration(
        labelText: 'Класс',
        prefixIcon: const Icon(Icons.school),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: List.generate(7, (i) => 5 + i)
          .map(
            (classNumber) => DropdownMenuItem(
          value: classNumber,
          child: Text('$classNumber класс'),
        ),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}

class ThemeDropdown extends StatelessWidget {
  final String selectedTheme;
  final List<String> themes;
  final Function(String?)? onChanged;

  const ThemeDropdown({
    super.key,
    required this.selectedTheme,
    required this.themes,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: selectedTheme,
      decoration: InputDecoration(
        labelText: 'Тема',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: themes
          .map(
            (theme) => DropdownMenuItem(value: theme, child: Text(theme)),
      )
          .toList(),
      onChanged: onChanged,
    );
  }
}
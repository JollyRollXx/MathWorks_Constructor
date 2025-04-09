import 'package:flutter/material.dart';

class MultiSelectDropdown extends StatefulWidget {
  final List<String> themes;
  final List<String> selectedThemes;
  final Function(List<String>) onChanged;

  const MultiSelectDropdown({
    super.key,
    required this.themes,
    required this.selectedThemes,
    required this.onChanged,
  });

  @override
  State<MultiSelectDropdown> createState() => _MultiSelectDropdownState();
}

class _MultiSelectDropdownState extends State<MultiSelectDropdown> {
  final List<String> _selectedItems = [];

  @override
  void initState() {
    super.initState();
    _selectedItems.addAll(widget.selectedThemes);
  }

  void _toggleSelection(String theme) {
    setState(() {
      if (_selectedItems.contains(theme)) {
        _selectedItems.remove(theme);
      } else {
        _selectedItems.add(theme);
      }
      widget.onChanged(_selectedItems);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Wrap(
          spacing: 8, // Расстояние между элементами в строке
          runSpacing: 8, // Расстояние между строками
          children: widget.themes.map((theme) {
            final isSelected = _selectedItems.contains(theme);
            return ChoiceChip(
              label: Text(theme),
              selected: isSelected,
              onSelected: (_) => _toggleSelection(theme),
              selectedColor: colorScheme.primary,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : colorScheme.onSurface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }
}
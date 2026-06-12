import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Reusable category picker: shows the available categories as selectable
/// chips and lets the user add new ones or remove the ones they created,
/// all dynamically. Single category is selected at a time.
class CategorySelector extends StatefulWidget {
  const CategorySelector({
    required this.options,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  /// Initial list of categories to offer (e.g. categories already in use).
  final List<String> options;

  /// Currently selected category, or null when none.
  final String? selected;

  /// Called whenever the selection changes (may be null when deselected).
  final ValueChanged<String?> onSelected;

  @override
  State<CategorySelector> createState() => _CategorySelectorState();
}

class _CategorySelectorState extends State<CategorySelector> {
  late final List<String> _options;
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _options = _dedupe([
      ...widget.options,
      if (widget.selected != null && widget.selected!.isNotEmpty)
        widget.selected!,
    ]);
  }

  @override
  void dispose() {
    _newCategoryController.dispose();
    super.dispose();
  }

  List<String> _dedupe(Iterable<String> values) {
    final seen = <String>{};
    final result = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) continue;
      final key = trimmed.toLowerCase();
      if (seen.add(key)) {
        result.add(trimmed);
      }
    }
    return result;
  }

  void _addCategory() {
    final text = _newCategoryController.text.trim();
    if (text.isEmpty) return;

    final existing = _options.firstWhere(
      (option) => option.toLowerCase() == text.toLowerCase(),
      orElse: () => '',
    );

    setState(() {
      if (existing.isEmpty) {
        _options.add(text);
      }
      _newCategoryController.clear();
    });
    widget.onSelected(existing.isEmpty ? text : existing);
  }

  void _removeCategory(String category) {
    setState(() {
      _options.removeWhere(
        (option) => option.toLowerCase() == category.toLowerCase(),
      );
    });
    if (widget.selected?.toLowerCase() == category.toLowerCase()) {
      widget.onSelected(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_options.isEmpty)
          const Text(
            'Nenhuma categoria. Adicione abaixo.',
            style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final category in _options)
                InputChip(
                  label: Text(category),
                  selected: widget.selected?.toLowerCase() ==
                      category.toLowerCase(),
                  selectedColor: AppTheme.primary.withValues(alpha: 0.15),
                  checkmarkColor: AppTheme.primary,
                  onSelected: (isSelected) =>
                      widget.onSelected(isSelected ? category : null),
                  onDeleted: () => _removeCategory(category),
                  deleteIconColor: AppTheme.textMuted,
                ),
            ],
          ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCategoryController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _addCategory(),
                decoration: InputDecoration(
                  hintText: 'Nova categoria',
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: AppTheme.inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide:
                        const BorderSide(color: AppTheme.primary, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addCategory,
              icon: const Icon(Icons.add_circle, color: AppTheme.primary),
              tooltip: 'Adicionar categoria',
            ),
          ],
        ),
      ],
    );
  }
}

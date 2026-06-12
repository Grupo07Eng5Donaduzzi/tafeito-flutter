import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/pricing_type.dart';

/// Reusable dropdown for selecting the service pricing method.
class PricingTypeDropdown extends StatelessWidget {
  const PricingTypeDropdown({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final PricingType value;
  final ValueChanged<PricingType> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<PricingType>(
      initialValue: value,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.inputBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppTheme.primary, width: 2),
        ),
      ),
      items: [
        for (final type in PricingType.values)
          DropdownMenuItem<PricingType>(
            value: type,
            child: Text(type.label),
          ),
      ],
      onChanged: (selected) {
        if (selected != null) {
          onChanged(selected);
        }
      },
    );
  }
}

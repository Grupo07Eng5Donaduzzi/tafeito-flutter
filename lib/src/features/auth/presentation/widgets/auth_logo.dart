import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AuthLogo extends StatelessWidget {
  const AuthLogo({
    this.fontSize = 38,
    this.centered = true,
    super.key,
  });

  final double fontSize;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final logo = Text.rich(
      TextSpan(
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textPrimary,
              fontSize: fontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
        children: const [
          TextSpan(text: 'Tá'),
          TextSpan(
            text: 'Feito',
            style: TextStyle(
              color: AppTheme.primary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
      textAlign: centered ? TextAlign.center : TextAlign.start,
    );

    if (!centered) {
      return logo;
    }

    return Center(child: logo);
  }
}

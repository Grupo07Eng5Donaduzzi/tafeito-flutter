import 'package:flutter/services.dart';

class CpfCnpjInputFormatter extends TextInputFormatter {
  static const _maxDigits = 14;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limitedDigits =
        digits.length > _maxDigits ? digits.substring(0, _maxDigits) : digits;
    final formatted = limitedDigits.length <= 11
        ? _formatCpf(limitedDigits)
        : _formatCnpj(limitedDigits);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatCpf(String digits) {
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index == 3 || index == 6) {
        buffer.write('.');
      }
      if (index == 9) {
        buffer.write('-');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }

  String _formatCnpj(String digits) {
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index == 2 || index == 5) {
        buffer.write('.');
      }
      if (index == 8) {
        buffer.write('/');
      }
      if (index == 12) {
        buffer.write('-');
      }
      buffer.write(digits[index]);
    }

    return buffer.toString();
  }
}

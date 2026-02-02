import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String text = newValue.text;

    // Allow empty
    if (text.isEmpty) {
      return newValue;
    }

    // Regex to allow digits and a single comma
    // Valid formats: "123", "123,", "123,45"
    final regExp = RegExp(r'^\d*,?\d*$');
    
    if (regExp.hasMatch(text)) {
       return newValue;
    }

    return oldValue;
  }
}

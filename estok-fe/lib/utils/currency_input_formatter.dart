import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final NumberFormat _currencyFormat;

  CurrencyInputFormatter({String locale = 'pt_BR', String symbol = 'R\$'})
      : _currencyFormat = NumberFormat.currency(locale: locale, symbol: symbol);

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    double value = double.parse(newValue.text) / 100;

    String newText = _currencyFormat.format(value);

    return newValue.copyWith(
        text: newText,
        selection: TextSelection.collapsed(offset: newText.length));
  }
}

class CurrencyInputFormatterNumeric extends TextInputFormatter {
   // This formatter enforces numeric only input but displays formatted currency
   // It's tricky because we want the user to type "123" and see "R$ 1,23"
   // The standard TextInputFormatter receives the new state of text. 
   // If the user types '1', newValue is 'R$ 0,001' (appended) which is wrong.
   
   // A better approach for "ATM style" is:
   // 1. Keep raw value (integer representing cents)
   // 2. Format on display.
   
   // Let's implement a simpler version that assumes the input is only digits being added/removed
   
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    
    // 1. Get only digits from the new value
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    
    // 2. If empty, return consistent zero state
    if (newText.isEmpty) {
      newText = '0';
    }
    
    // 3. Parse as integer (cents)
    int valueInCents = int.tryParse(newText) ?? 0;
    
    // 4. Format
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    String newFormattedText = formatter.format(valueInCents / 100);
    
    return TextEditingValue(
      text: newFormattedText,
      selection: TextSelection.collapsed(offset: newFormattedText.length),
    );
  }
}

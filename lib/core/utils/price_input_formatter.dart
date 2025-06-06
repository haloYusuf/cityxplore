import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class PriceInputFormatter extends TextInputFormatter {
  static const int maxPrice = 100000000;

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    String cleanText = newValue.text.replaceAll(RegExp(r'\D'), '');

    if (cleanText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    int? parsedValue = int.tryParse(cleanText);

    if (parsedValue == null) {
      return oldValue;
    }

    if (parsedValue > maxPrice) {
      parsedValue = maxPrice;
      cleanText = parsedValue.toString();
    }

    final formatter = NumberFormat('#,##0', 'en_US');
    String formattedText = formatter.format(parsedValue);

    // Hitung posisi kursor yang benar setelah format
    TextSelection newSelection = newValue.selection;
    if (formattedText != newValue.text) {
      int delta = formattedText.length - newValue.text.length;
      newSelection = newValue.selection.copyWith(
        baseOffset: newSelection.baseOffset + delta,
        extentOffset: newSelection.extentOffset + delta,
      );
    }

    if (newSelection.baseOffset > formattedText.length) {
      newSelection = TextSelection.collapsed(offset: formattedText.length);
    }

    return newValue.copyWith(
      text: formattedText,
      selection: newSelection,
    );
  }
}

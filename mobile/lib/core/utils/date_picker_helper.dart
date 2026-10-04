import 'package:flutter/material.dart';

/// Opens a Date Picker that restricts selection to future dates (today and onwards by default).
/// If a past date is selected, it prevents selection and shows a SnackBar: "Can't select past date".
Future<void> selectDate(
  BuildContext context,
  TextEditingController controller, {
  DateTime? initialDate,
  bool allowPastDate = false,
}) async {
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);

  DateTime initial;
  try {
    if (controller.text.trim().isNotEmpty) {
      initial = DateTime.parse(controller.text.trim().split(' ')[0]);
    } else {
      initial = initialDate ?? todayMidnight;
    }
  } catch (_) {
    initial = initialDate ?? todayMidnight;
  }

  final firstDate = allowPastDate ? DateTime(1970) : todayMidnight;
  if (initial.isBefore(firstDate)) {
    initial = todayMidnight;
  }

  final DateTime? picked = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: DateTime(2100),
  );

  if (picked != null) {
    if (!allowPastDate && picked.isBefore(todayMidnight)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Can't select past date"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final year = picked.year.toString().padLeft(4, '0');
    final month = picked.month.toString().padLeft(2, '0');
    final day = picked.day.toString().padLeft(2, '0');
    controller.text = '$year-$month-$day';
  }
}

/// Opens Date Picker followed by Time Picker for date-time fields, restricting selection to future dates.
Future<void> selectDateTimePicker(
  BuildContext context,
  TextEditingController controller, {
  DateTime? initialDate,
  bool allowPastDate = false,
}) async {
  final now = DateTime.now();
  final todayMidnight = DateTime(now.year, now.month, now.day);

  DateTime initial;
  try {
    if (controller.text.trim().isNotEmpty) {
      initial = DateTime.parse(controller.text.trim().split(' ')[0]);
    } else {
      initial = initialDate ?? todayMidnight;
    }
  } catch (_) {
    initial = initialDate ?? todayMidnight;
  }

  final firstDate = allowPastDate ? DateTime(1970) : todayMidnight;
  if (initial.isBefore(firstDate)) {
    initial = todayMidnight;
  }

  final DateTime? pickedDate = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: firstDate,
    lastDate: DateTime(2100),
  );

  if (pickedDate != null && context.mounted) {
    if (!allowPastDate && pickedDate.isBefore(todayMidnight)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Can't select past date"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final TimeOfDay initialTime = TimeOfDay.now();
    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    final time = pickedTime ?? const TimeOfDay(hour: 18, minute: 0);
    final year = pickedDate.year.toString().padLeft(4, '0');
    final month = pickedDate.month.toString().padLeft(2, '0');
    final day = pickedDate.day.toString().padLeft(2, '0');
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    controller.text = '$year-$month-$day $hour:$minute:00';
  }
}

/// Validator function to ensure chosen date is not in the past.
String? validateFutureDate(String? v) {
  if (v == null || v.trim().isEmpty) return 'Date is required';
  try {
    final dateStr = v.trim().split(' ')[0];
    final parsed = DateTime.parse(dateStr);
    final now = DateTime.now();
    final todayMidnight = DateTime(now.year, now.month, now.day);
    if (parsed.isBefore(todayMidnight)) {
      return "Can't select past date";
    }
  } catch (_) {
    return 'Invalid date format';
  }
  return null;
}

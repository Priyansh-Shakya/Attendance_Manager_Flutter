import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class customCheckBox extends StatefulWidget {
  const customCheckBox({super.key});

  @override
  State<customCheckBox> createState() => _customCheckBoxState();
}

class _customCheckBoxState extends State<customCheckBox> {
  bool isChecked = false;
  @override
  Widget build(BuildContext context) {
    return Checkbox(
      value: isChecked,
      checkColor: Colors.white,
      onChanged: (value) {
        setState(() {
          isChecked = value!;
        });
      },
    );
  }
}

// Time and days
class AcademicYear {
  final List<Month> months;
  AcademicYear({required this.months});
}

class Month {
  final String name;
  final List<Week> weeks;
  Month({required this.name, required this.weeks});
}

class Week {
  final List<AttendanceDay> days;
  Week({required this.days});
}

class AttendanceDay {
  final DateTime date;
  bool isPresent = false;
  AttendanceDay({required this.date});
}

String _monthName(int month) {
  const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  return monthNames[month - 1];
}

AcademicYear createAcademicYear(DateTime start, DateTime end) {
  List<AttendanceDay> allDays = [];
  int totalDays = end.difference(start).inDays + 1;

  for (int i = 0; i < totalDays; i++) {
    DateTime date = start.add(Duration(days: i));
    allDays.add(AttendanceDay(date: date));
  }

  // Group by month
  Map<String, List<AttendanceDay>> monthMap = {};
  for (var day in allDays) {
    String key = "${day.date.year}-${day.date.month}";
    monthMap.putIfAbsent(key, () => []).add(day);
  }

  List<Month> months = [];

  monthMap.forEach((key, daysInMonth) {
    List<Week> weeks = [];
    List<AttendanceDay?> currentWeek = [];

    // First day padding (if not Sunday)
    DateTime firstDay = daysInMonth.first.date;
    int startPadding = firstDay.weekday % 7; // Sunday = 0, Monday = 1...
    currentWeek.addAll(List.filled(startPadding, null));

    for (var day in daysInMonth) {
      currentWeek.add(day);
      if (currentWeek.length == 7) {
        weeks.add(
          Week(days: currentWeek.whereType<AttendanceDay>().toList()),
        ); // remove nulls
        currentWeek = [];
      }
    }

    // Last week padding
    if (currentWeek.isNotEmpty) {
      currentWeek.addAll(List.filled(7 - currentWeek.length, null));
      weeks.add(
        Week(days: currentWeek.whereType<AttendanceDay>().toList()),
      ); // remove nulls
    }
    print(
      "Month key: $key → month name: ${_monthName(daysInMonth.first.date.month)}",
    );

    String monthName =
        "${_monthName(daysInMonth.first.date.month)} ${daysInMonth.first.date.year}";
    months.add(Month(name: monthName, weeks: weeks));
  });

  return AcademicYear(months: months);
}

class Vibration {
  // Checkbox toggle , app bar iconButtons
  static void checkboxToggle() {
    HapticFeedback.selectionClick();
    print("small vibration");
  }

  // Individual class button
  static void buttonPress() {
    HapticFeedback.mediumImpact();
    print("medium vibration");
  }

  // Select all classes
  static void selectAll() {
    HapticFeedback.heavyImpact();
    print("heavy vibration");
  }

  // Snackbar
  static void snackbar() {
    HapticFeedback.lightImpact();
    print("snacker bar vibration");
  }

  // Long press or generic
  static void longPress() {
    HapticFeedback.vibrate();
  }
}

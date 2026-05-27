import 'package:attendance_manager/DataBase/model_class.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'utils.dart';
import 'DataBase/IoFunctions.dart';
import 'package:hive/hive.dart';

class WeekCard extends StatefulWidget {
  final int weekNumber;
  final List<AttendanceDay> days;
  final int sessionId;
  final bool showFuture;
  final bool planningMode;
  final List<AttendanceData>? tempAttendance;
  final void Function(DateTime date, bool value)? onDayToggle;

  final bool classBased;

  final bool planning;

  const WeekCard({
    required this.weekNumber,
    required this.days,
    required this.sessionId,
    required this.showFuture,
    required this.planningMode,
    required this.classBased,
    required this.planning,
    this.tempAttendance,
    this.onDayToggle,
    super.key,
  });

  @override
  State<WeekCard> createState() => _WeekCardState();
}

class _WeekCardState extends State<WeekCard> {
  final List<String> fullWeekdayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  DateTime _todayTruncated() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  bool _isFutureDay(DateTime date) => date.isAfter(_todayTruncated());

  bool _sameDate(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _presentFromTemp(DateTime date) {
    return widget.tempAttendance?.any(
          (a) => _sameDate(a.date, date) && a.isPresent,
        ) ??
        false;
  }

  SessionData? _getSession() {
    final myBox = Hive.box<SessionData>("SessionBoxV3");
    return myBox.get(widget.sessionId);
  }

  AttendanceDay? _findDay(int weekdayNum) {
    try {
      return widget.days.firstWhere((d) => d.date.weekday == weekdayNum);
    } catch (_) {
      return null;
    }
  }

  int _weekdayIndexToNum(int index) => index == 0 ? 7 : index;

  @override
  Widget build(BuildContext context) {
    final session = _getSession();

    return Card(
      color: const Color(0xFF111827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      elevation: 4,
      shadowColor: Colors.black54,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Week ${widget.weekNumber}',
              style: const TextStyle(
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Column(
              children: List.generate(7, (index) {
                final weekdayNum = _weekdayIndexToNum(index);
                final matchedDay = _findDay(weekdayNum);
                if (matchedDay == null) return const SizedBox();

                final isFuture = _isFutureDay(matchedDay.date);
                final isChecked = widget.planningMode
                    ? _presentFromTemp(matchedDay.date) || matchedDay.isPresent
                    : matchedDay.isPresent;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: Column(
                    children: [
                      // Check Box Row <--------
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            fullWeekdayNames[index],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: (index == 0 || index == 6)
                                  ? const Color(0xFFF06292)
                                  : Colors.white,
                            ),
                          ),
                          Text(
                            "${matchedDay.date.day.toString().padLeft(2, '0')}/${matchedDay.date.month.toString().padLeft(2, '0')}",
                            style: const TextStyle(
                              fontSize: 14,
                              color: Color(0xFF4FC3F7),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Checkbox(
                            value: isChecked,
                            checkColor: const Color(0xFF1DE9B6),
                            activeColor: const Color(0xFF1DE9B6),
                            fillColor: WidgetStateProperty.resolveWith((
                              states,
                            ) {
                              if (states.contains(WidgetState.disabled)) {
                                return Colors.white10;
                              }
                              if (states.contains(WidgetState.selected)) {
                                return const Color(0xFF1DE9B6);
                              }
                              return const Color(0xFF1A2332);
                            }),
                            side: WidgetStateBorderSide.resolveWith((states) {
                              if (states.contains(WidgetState.selected)) {
                                return const BorderSide(
                                  color: Color(0xFF1DE9B6),
                                  width: 2,
                                );
                              }
                              return const BorderSide(
                                color: Color(0xFF324558),
                                width: 1.5,
                              );
                            }),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(
                              horizontal: -2,
                              vertical: -2,
                            ),
                            onChanged: (!widget.showFuture && isFuture)
                                ? null
                                : (bool? value) {
                                    final newValue = value ?? false;
                                    if (session != null &&
                                        session.activeDaysPerWeek == 5 &&
                                        matchedDay.date.weekday ==
                                            DateTime.saturday) {
                                      Vibration.snackbar(); //vibrations
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.black,
                                          content: Text(
                                            "Saturday won't be counted in a 5-Days week!!",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    if (matchedDay.date.weekday ==
                                        DateTime.sunday) {
                                      Vibration.snackbar();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          backgroundColor: Colors.black,
                                          content: Text(
                                            "Sunday won't be counted!!",
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(
                                      () => matchedDay.isPresent = newValue,
                                    );
                                    if (widget.planningMode) {
                                      Vibration.checkboxToggle();
                                      widget.onDayToggle?.call(
                                        matchedDay.date,
                                        newValue,
                                      );
                                    } else {
                                      Vibration.checkboxToggle();
                                      IoFunctions.addAttendance(
                                        AttendanceData(
                                          sessionId: widget.sessionId,
                                          date: matchedDay.date,
                                          isPresent: newValue,
                                        ),
                                      );
                                    }
                                  },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (isChecked &&
                          widget.classBased &&
                          widget.showFuture == false)
                        DailyClassWidget(
                          widget.sessionId,
                          matchedDay.date,
                          widget.planning,
                        ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

class MonthSection extends StatelessWidget {
  final Month month;
  final int monthIndex;
  final int sessionId;
  final bool showFuture;
  final bool planningMode;
  final List<AttendanceData>? tempAttendance;
  final void Function(DateTime date, bool value)? onDayToggle;
  final bool classBased;
  final bool planningM;

  const MonthSection({
    required this.month,
    required this.monthIndex,
    required this.sessionId,
    required this.showFuture,
    required this.planningMode,
    required this.planningM,
    this.tempAttendance,
    this.onDayToggle,
    required this.classBased,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            month.name,
            style: const TextStyle(
              fontSize: 22,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...List.generate(
          month.weeks.length,
          (i) => WeekCard(
            weekNumber: i + 1,
            days: month.weeks[i].days,
            sessionId: sessionId,
            showFuture: showFuture,
            planningMode: planningMode,
            tempAttendance: tempAttendance,
            onDayToggle: onDayToggle,
            classBased: classBased,
            planning: planningM,
          ),
        ),
      ],
    );
  }
}

// ---------------- Daily Class Button Row ----------------
class DailyClassWidget extends StatefulWidget {
  final int sessionId;
  final DateTime date;
  final bool planningMode;

  const DailyClassWidget(
    this.sessionId,
    this.date,
    this.planningMode, {
    super.key,
  });

  @override
  State<DailyClassWidget> createState() => _DailyClassWidgetState();
}

class _DailyClassWidgetState extends State<DailyClassWidget> {
  Set<int> pressedButtons = {};
  int totalClasses = 0;
  bool isLoading = true;

  ScrollController classRow = ScrollController();
  List<bool> classes = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final total = await IoFunctions.loadClassesPerDay(widget.sessionId);
    if (total == null) return;

    List<bool> dayClasses;

    // load from Hive if normal mode
    final pressed = await IoFunctions.loadPressedButtons(
      widget.sessionId,
      widget.date,
      total,
    );
    dayClasses = List.generate(total, (i) => pressed.contains(i));

    setState(() {
      totalClasses = total;
      classes = dayClasses;
      pressedButtons = classes
          .asMap()
          .entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toSet();
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 60,
        width: 60,
        child: Center(
          child: CircularProgressIndicator(strokeWidth: 4, color: Colors.green),
        ),
      );
    }

    return Card(
      elevation: 1,
      color: const Color(0xFF111827),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Scrollbar(
          thumbVisibility: true,
          trackVisibility: true,
          thickness: 2,
          controller: classRow,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            controller: classRow,
            child: Row(
              children: List.generate(totalClasses, (i) {
                final isPressed = pressedButtons.contains(i);

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: SizedBox(
                    height: 32,
                    width: 50,
                    child: ElevatedButton(
                      onLongPress: () async {
                        Vibration.selectAll();
                        final allSelected =
                            pressedButtons.length == totalClasses;

                        if (allSelected) {
                          // Deselect all
                          setState(() {
                            classes = List.generate(totalClasses, (_) => false);
                            pressedButtons.clear();
                          });

                          for (int i = 0; i < totalClasses; i++) {
                            await IoFunctions.toggleClass(
                              widget.sessionId,
                              widget.date,
                              i,
                              totalClasses,
                            );
                          }

                          debugPrint("All deselected");
                        } else {
                          // Select all
                          setState(() {
                            classes = List.generate(totalClasses, (_) => true);
                            pressedButtons = Set.from(
                              List.generate(totalClasses, (i) => i),
                            );
                          });

                          for (int i = 0; i < totalClasses; i++) {
                            await IoFunctions.toggleClass(
                              widget.sessionId,
                              widget.date,
                              i,
                              totalClasses,
                            );
                          }

                          debugPrint("All selected");
                        }
                      },
                      onPressed: () {
                        Vibration.buttonPress();
                        final newValue = !classes[i];

                        setState(() {
                          classes[i] = newValue;
                          if (newValue) {
                            pressedButtons.add(i);
                          } else {
                            pressedButtons.remove(i);
                          }
                        });

                        // persist into Hive
                        IoFunctions.toggleClass(
                          widget.sessionId,
                          widget.date,
                          i,
                          totalClasses,
                        );

                        debugPrint("Tapped");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF161B2A),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 6,
                          horizontal: 6,
                        ),
                        elevation: 0,
                        minimumSize: const Size(16, 32),
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "C${i + 1}",
                          style: TextStyle(
                            color: isPressed
                                ? const Color(0xFF80CBC4)
                                : const Color(0xFFFF8A80),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

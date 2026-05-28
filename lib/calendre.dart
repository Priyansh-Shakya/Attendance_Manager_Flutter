import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:attendance_manager/DataBase/model_class.dart';
import 'package:attendance_manager/dailogBoxes.dart';
import 'package:attendance_manager/utils.dart';
import 'package:attendance_manager/year-month-week.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class CalenderView extends StatefulWidget {
  final String scrollId;
  final int? sessionID;
  final bool showFuture;
  final bool planningMode; // New
  final List<AttendanceData>? tempAttendance; // New
  final Function(DateTime, bool)? onDayToggle; // New

  final Function(bool)? classBasedToggle;

  final classBased;

  final bool planningC;

  const CalenderView({
    super.key,
    required this.scrollId,
    required this.sessionID,
    required this.showFuture,
    required this.planningC,
    this.planningMode = false,
    this.tempAttendance,
    this.onDayToggle,
    this.classBasedToggle,
    required this.classBased,
  });

  @override
  State<CalenderView> createState() => _CalenderViewState();
}

class _CalenderViewState extends State<CalenderView> {
  AcademicYear? yearData;

  bool isSelected = false;
  late String screenScrollId;

  bool _isClassBased = false;

  @override
  void initState() {
    super.initState();

    //Class based load.
    if (widget.sessionID != null) {
      IoFunctions.checkClassBased(widget.sessionID!).then((value) {
        if (value != null) {
          setState(() {
            _isClassBased = value;
          });
          widget.classBasedToggle?.call(_isClassBased);
        }
      });
    }

    screenScrollId = widget.scrollId;
    if (widget.sessionID != null) {
      final myBox = Hive.box<SessionData>("SessionBoxV3");
      final session = myBox.get(widget.sessionID);
      if (session != null) {
        yearData = createAcademicYear(session.sessionStart, session.sessionEnd);

        setState(() {
          isSelected = true;
        });

        // show dailog
        WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
          if (isSelected) {
            showCustomDialog(
              context,
              title: "Calendar",
              screenNumber: "screen_1",
              customContent: const Column(
                children: [
                  Text(
                    "A calendar is formed for your academic session.\nYou can mark 'Presents' by checking the boxes for each day. You can only see boxes till latest (present) day, future boxes are locked.\nMarking or un-marking weekends or days beyond 'Active Days per week' you have set while creating Session won't change anything in your stats.",
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "Note: You can switch to class based attendance by clicking the app bar button.",
                    style: TextStyle(color: Colors.green, fontSize: 12),
                  ),
                ],
              ),
            );
          }
        });

        List<AttendanceData> attendanceSource;

        // If in planning mode → use tempAttendance
        if (widget.planningMode && widget.tempAttendance != null) {
          attendanceSource = widget.tempAttendance!;
        } else {
          // Normal mode → load from Hive
          attendanceSource = IoFunctions.getAllAttendance()
              .where((a) => a.sessionId == widget.sessionID)
              .toList();
        }

        // Apply attendance to days
        for (var month in yearData!.months) {
          for (var week in month.weeks) {
            for (var day in week.days) {
              final record = attendanceSource.firstWhereOrNull(
                (a) => a.date == day.date,
              );
              if (record != null) {
                day.isPresent = record.isPresent;
              }
            }
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("Calendar $widget.sessionId");
    if (widget.sessionID == null) {
      setState(() {
        _isClassBased = false;
      });
      return const Center(
        child: Text(
          'No session selected',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    if (yearData == null) {
      return const Center(
        child: Text('No session found', style: TextStyle(color: Colors.white)),
      );
    }

    return ListView(
      key: PageStorageKey("${screenScrollId}_key"),
      children: [
        const SizedBox(height: 24),
        const Center(
          child: Text(
            "Academic Year - 2025",
            style: TextStyle(
              fontSize: 26,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(yearData!.months.length, (monthIndex) {
          final month = yearData!.months[monthIndex];
          final today = DateTime.now();

          final weeksToShow = month.weeks.map((week) {
            final daysToShow = (widget.showFuture || widget.planningMode)
                ? week.days
                : week.days
                      .where(
                        (day) =>
                            day.date.isBefore(today) ||
                            day.date.isAtSameMomentAs(today),
                      )
                      .toList();

            return Week(days: daysToShow);
          }).toList();

          final filteredMonth = Month(name: month.name, weeks: weeksToShow);

          return MonthSection(
            month: filteredMonth,
            monthIndex: monthIndex,
            sessionId: widget.sessionID!,
            showFuture: widget.showFuture,
            planningMode: widget.planningMode,
            onDayToggle: widget.onDayToggle, // Pass toggle callback
            classBased: widget.classBased,
            planningM: widget.planningC,
          );
        }),
        const SizedBox(height: 32),
      ],
    );
  }
}

class CalenderScreen extends StatefulWidget {
  final int? sessionID;
  final bool showFuture;
  final ValueChanged<bool>? onClassBasedChanged;

  const CalenderScreen({
    super.key,
    required this.sessionID,
    this.onClassBasedChanged,
    this.showFuture = false,
  });

  @override
  State<CalenderScreen> createState() => _CalenderScreenState();
}

class _CalenderScreenState extends State<CalenderScreen> {
  bool _isClassBased = false; // local state for icon color

  bool get isClassBasedSafe => widget.sessionID != null && _isClassBased;

  void _handleToggle() async {
    if (widget.sessionID == null) return;

    setState(() {
      _isClassBased = !_isClassBased;
    });

    // 🔹 Persist toggle
    await IoFunctions.toggleClassBased(widget.sessionID!, _isClassBased);

    if (widget.onClassBasedChanged != null) {
      widget.onClassBasedChanged!(_isClassBased);
    }
  }

  //------check if we need to show dailog--------
  void checkAndShowClassesDailoge() async {
    bool showClassesDailoge = await IoFunctions.checkClassesDailogShown();
    if (!showClassesDailoge) {
      // void checkAndShowClassesDailoge() async {
      //   bool showClassesDailoge = await IoFunctions.checkClassesDailogShown();
      //   if (!showClassesDailoge) {
      //     allClassesDailoge(
      //       context,
      //       "Classes Mode",
      //       "You can check or uncheck all classes by long pressing any of them.",
      //     );
      //     await IoFunctions.selectAllClassesDailog(true);
      //   }
      // }

      allClassesDailoge(
        context,
        "Classes Mode",
        "You can check or uncheck all classes by long pressing any of them.\nNote: Before checking or unchecking the entire row for a day... Make sure there's no checked class already.",
      );
      await IoFunctions.selectAllClassesDailog(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            onPressed: () {
              Vibration.checkboxToggle();
              if (widget.sessionID != null) {
                _handleToggle();
              }
              checkAndShowClassesDailoge();
            },
            icon: Icon(
              isClassBasedSafe ? Icons.grid_view : Icons.calendar_today,
              color: isClassBasedSafe ? Colors.green : Colors.white,
            ),
          ),
        ],
        backgroundColor: const Color(0xFF10131A),
        title: const Text(
          "Calender",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFF0B0D14),
      body: CalenderView(
        scrollId: "Calendre",
        sessionID: widget.sessionID,
        showFuture: widget.showFuture,
        planningMode: false,
        classBased: _isClassBased,
        planningC: false,
        classBasedToggle: (value) {
          setState(() {
            _isClassBased = value;
          });
        },
      ),
    );
  }
}

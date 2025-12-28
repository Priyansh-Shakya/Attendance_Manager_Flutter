import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:attendance_manager/DataBase/model_class.dart';
import 'package:attendance_manager/calendre.dart';
import 'package:attendance_manager/dailogBoxes.dart';
import 'package:attendance_manager/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TestScreen extends StatefulWidget {
  final int? sessionId;

  const TestScreen({required this.sessionId, super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  late List<AttendanceData> tempAttendance;
  late List<AttendanceData> originalAttendance; // For reset

  SessionData? session;
  DateTime? presentDay; // cut-off date for stats
  int adjustment = 0;

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _loadAdjustment();
    if (widget.sessionId != null) {
      _showPlanningModeDialog(context);
    }

    _checkClassMode();
  }

  //show dailog for introducing scree, one time.

  Future<void> _showPlanningModeDialog(BuildContext context) async {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showCustomDialog(
        context,
        title: "Planning Mode",
        screenNumber: "planning_mode_dialog", // unique key for prefs
        customContent: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Planning mode enables you to experiment and plan your future attendance by 'setting a future day as present day', you can experiment with your attendance.",
              style: TextStyle(fontSize: 15, color: Colors.white),
            ),
            SizedBox(height: 12),
            Text(
              "Note: Changing attendance in here doesn't affect your actual attendance.",
              style: TextStyle(fontSize: 14, color: Colors.green),
            ),
          ],
        ),
      );
    });
  }

  //show dailog for class based
  Future<void> _checkClassMode() async {
    final isClassBased = await IoFunctions.checkClassBased(widget.sessionId!);

    if (isClassBased == null) {
      return;
    }
    if (isClassBased) {
      // Delay to ensure context is ready
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,

          builder: (context) => AlertDialog(
            title: const Text("Day-based Mode Only"),
            content: const Text(
              "Note! Test screen only works in day-based attendance mode. "
              "To ensure stats don't change unexpectedly, please switch to day mode.",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("OK"),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _loadAdjustment() async {
    final prefs = await SharedPreferences.getInstance();

    final value = prefs.getInt("adjustment_${widget.sessionId}") ?? 0;
    setState(() {
      adjustment = value;
    });
    print(adjustment);
  }

  void _loadSessionData() {
    if (widget.sessionId != null) {
      final sessionBox = Hive.box<SessionData>("SessionBoxV3");
      session = sessionBox.get(widget.sessionId);

      if (session != null) {
        // Pull real Hive data
        final hiveData = Hive.box<AttendanceData>(
          "AttendanceBoxV3",
        ).values.where((a) => a.sessionId == widget.sessionId).toList();

        // Save original for reset
        originalAttendance = hiveData
            .map(
              (a) => AttendanceData(
                sessionId: a.sessionId,
                date: a.date,
                isPresent: a.isPresent,
              ),
            )
            .toList();

        // Clone for temp editing
        tempAttendance = originalAttendance
            .map(
              (a) => AttendanceData(
                sessionId: a.sessionId,
                date: a.date,
                isPresent: a.isPresent,
              ),
            )
            .toList();

        // ✅ Default present day = today or sessionEnd (whichever is earlier)
        final today = DateTime.now();
        presentDay = today.isAfter(session!.sessionEnd)
            ? session!.sessionEnd
            : today;
      } else {
        tempAttendance = [];
        originalAttendance = [];
        presentDay = DateTime.now();
      }
    } else {
      tempAttendance = [];
      originalAttendance = [];
      presentDay = DateTime.now();
    }
  }

  void toggleDay(DateTime date, bool value) {
    if (widget.sessionId == null) return;

    final idx = tempAttendance.indexWhere(
      (a) =>
          a.date.year == date.year &&
          a.date.month == date.month &&
          a.date.day == date.day,
    );

    setState(() {
      if (idx != -1) {
        tempAttendance[idx].isPresent = value;
      } else {
        tempAttendance.add(
          AttendanceData(
            sessionId: widget.sessionId!,
            date: date,
            isPresent: value,
          ),
        );
      }
    });
  }

  void resetChanges() {
    setState(() {
      tempAttendance = originalAttendance
          .map(
            (a) => AttendanceData(
              sessionId: a.sessionId,
              date: a.date,
              isPresent: a.isPresent,
            ),
          )
          .toList();
    });
  }

  int countPlannedWorkingDays(
    DateTime start,
    DateTime end,
    int activeDaysPerWeek,
  ) {
    int total = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(last)) {
      if (current.weekday <= activeDaysPerWeek) total++;
      current = current.add(const Duration(days: 1));
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    print("Stats $widget.sessionId");
    if (widget.sessionId == null || session == null || presentDay == null) {
      return const Scaffold(
        backgroundColor: Color(0xff242424),
        body: Center(
          child: Text(
            "No session found",
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    // Stats from temp data (using presentDay limit)
    // 1. Total working days till presentDay
    final plannedWorkingDays = countPlannedWorkingDays(
      session!.sessionStart,
      presentDay!,
      session!.activeDaysPerWeek,
    );

    // 2. Count present days
    final presentCount = tempAttendance
        .where((a) => !a.date.isAfter(presentDay!) && a.isPresent == true)
        .length;

    // 3. Calculate absent days
    int absentCountRaw = plannedWorkingDays - presentCount;

    // 4. Apply adjustment
    final absentCount = (absentCountRaw - adjustment).clamp(0, absentCountRaw);

    // 5. Total marked days
    final totalMarked = presentCount + absentCount;

    // 6. Attendance percentage
    final attendancePct = totalMarked == 0
        ? 0.0
        : (presentCount / totalMarked) * 100.0;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff242424),
        title: const Text(
          "Planning",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: "Reset Changes",
            onPressed: () {
              Vibration.checkboxToggle();
              resetChanges();
            },
          ),
        ],
      ),
      backgroundColor: const Color(0xff000000),
      body: Stack(
        children: [
          // Full page content
          Column(
            children: [
              // Stats section
              Container(
                color: Colors.black,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      "Present Day: ${presentDay!.day}/${presentDay!.month}/${presentDay!.year}",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Total Working Days (Till Present Day): $plannedWorkingDays",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Present: $presentCount",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Absent: $absentCount",
                      style: const TextStyle(color: Colors.white),
                    ),
                    Text(
                      "Attendance: ${attendancePct.toStringAsFixed(1)}%",
                      style: TextStyle(
                        color: attendancePct < session!.targetAttendance
                            ? Colors.red
                            : Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(color: Colors.white24, height: 1),

              // Calendar takes all available height
              Expanded(
                child: CalenderView(
                  classBased: false,
                  planningC: true,
                  scrollId: "Calendre",
                  key: ValueKey(tempAttendance.hashCode),
                  sessionID: widget.sessionId,
                  showFuture: true,
                  planningMode: true,
                  tempAttendance: tempAttendance,
                  onDayToggle: toggleDay,
                ),
              ),
            ],
          ),

          // Floating button overlay
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Vibration.buttonPress();
                    print("Absent raw:$absentCountRaw");
                    print("absent with adjustment $absentCount");
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: presentDay!,
                      firstDate: session!.sessionStart,
                      lastDate: session!.sessionEnd,
                    );

                    if (picked != null) {
                      setState(() {
                        presentDay = picked;
                      });
                    }
                  },
                  icon: const Icon(Icons.check, color: Colors.black, size: 18),
                  label: const Text(
                    "Set Present Day",
                    style: TextStyle(color: Colors.black, fontSize: 14),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: const StadiumBorder(),
                    elevation: 3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

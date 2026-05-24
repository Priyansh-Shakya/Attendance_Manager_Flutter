import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:attendance_manager/DataBase/model_class.dart';
import 'package:attendance_manager/utils.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';

class StatisticsView extends StatefulWidget {
  final int? sessionId;
  final bool isClassBased;

  const StatisticsView({
    super.key,
    required this.sessionId,
    required this.isClassBased,
  });

  @override
  State<StatisticsView> createState() => _StatisticsViewState();
}

class _StatisticsViewState extends State<StatisticsView> {
  int? perDay;
  int adjustment = 0; // store compensation in state
  bool isClassBased = false;
  bool _loadingConfig = true;

  @override
  void initState() {
    super.initState();
    _initConfig();
  }

  Future<void> _initConfig() async {
    if (widget.sessionId == null) {
      setState(() {
        _loadingConfig = false;
      });
      return;
    }

    // load async configuration values
    final classes = await IoFunctions.loadClassesPerDay(widget.sessionId!);
    final based = await IoFunctions.checkClassBased(widget.sessionId!);
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getInt("adjustment_${widget.sessionId}") ?? 0;

    setState(() {
      perDay = classes;
      isClassBased = based ?? widget.isClassBased;
      print("mode for session: ${widget.sessionId} = $isClassBased");
      adjustment = saved;
      print("Adjustment for session - ${widget.sessionId} = $adjustment");
      _loadingConfig = false;
    });
  }

  // Save adjustment (compensator) to SharedPreferences
  void addCompensation(int sessionId, int adjustment) async {
    final pref = await SharedPreferences.getInstance();
    final current = pref.getInt("adjustment_$sessionId") ?? 0;
    final updated = current + adjustment;

    await pref.setInt("adjustment_$sessionId", updated);

    setState(() {
      this.adjustment = updated;
    });
  }

  // Reset adjustment back to 0
  Future<void> _restoreOriginal(int sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt("adjustment_${widget.sessionId}", 0);

    setState(() {
      adjustment = 0;
    });
  }

  // Count planned working days (inclusive)
  int countPlannedWorkingDays(
    DateTime start,
    DateTime end,
    int activeDaysPerWeek,
    int adjustment,
  ) {
    int total = 0;
    DateTime current = DateTime(start.year, start.month, start.day);
    final last = DateTime(end.year, end.month, end.day);

    while (!current.isAfter(last)) {
      if (current.weekday <= activeDaysPerWeek) {
        total++;
      }
      current = current.add(const Duration(days: 1));
    }

    return (total - adjustment).clamp(0, total);
  }

  // Adjustment dialog
  Future<void> _showAdjustmentDialog() async {
    final TextEditingController daysController = TextEditingController();

    final int? newAdjustment = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Adjustment"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Enter number of holidays/leaves to exclude.\n"
                "They will be subtracted from total working days and absents.",
              ),
              const SizedBox(height: 10),
              Text(
                "Total days removed: $adjustment",
                style: const TextStyle(color: Colors.blue, fontSize: 15),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: daysController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: "Enter days",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                final days = int.tryParse(daysController.text) ?? 0;
                Navigator.pop(context, days); // return entered days
              },
              child: const Text("Save"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _restoreOriginal(widget.sessionId!);
                Navigator.pop(context);
              },
              child: const Text("Restore Original"),
            ),
          ],
        );
      },
    );

    if (newAdjustment != null) {
      addCompensation(widget.sessionId!, newAdjustment);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingConfig) {
      // waiting for async config
      return const Center(child: CircularProgressIndicator());
    }

    final sessionBox = Hive.box<SessionData>("SessionBoxV3");
    final session = sessionBox.get(widget.sessionId);

    if (session == null) {
      return const Center(
        child: Text("No session found", style: TextStyle(color: Colors.white)),
      );
    }

    // plannedWorkingDays (with adjustment applied)
    final plannedWorkingDays = countPlannedWorkingDays(
      session.sessionStart,
      session.sessionEnd,
      session.activeDaysPerWeek,
      adjustment,
    );

    // ValueListenableBuilder reacts to attendance Hive changes
    return ValueListenableBuilder(
      valueListenable: Hive.box<AttendanceData>("AttendanceBoxV3").listenable(),
      builder: (context, Box<AttendanceData> atBox, _) {
        final sessionAttendance = atBox.values
            .where((a) => a.sessionId == widget.sessionId)
            .toList();

        // -------- Day Based (synchronous) ----------
        final today = DateTime.now();

        final presentDaysCount = sessionAttendance.where((a) {
          if (a.date.isAfter(today)) return false; // ignore future
          return a.isPresent && a.date.weekday <= session.activeDaysPerWeek;
        }).length;
        print("Present days: $presentDaysCount");

        int absentDaysCount = 0;
        DateTime current = DateTime(
          session.sessionStart.year,
          session.sessionStart.month,
          session.sessionStart.day,
        );

        while (!current.isAfter(today) &&
            !current.isAfter(session.sessionEnd)) {
          if (current.weekday <= session.activeDaysPerWeek) {
            final record = sessionAttendance.firstWhereOrNull(
              (a) =>
                  a.date.year == current.year &&
                  a.date.month == current.month &&
                  a.date.day == current.day,
            );

            if (record == null || !record.isPresent) {
              absentDaysCount++;
            }
          }
          current = current.add(const Duration(days: 1));
        }

        absentDaysCount = (absentDaysCount - adjustment).clamp(
          0,
          absentDaysCount,
        );

        // -------- Class Based (async) ----------
        // total classes in plannedWorkingDays:
        final int totalClasses = (perDay != null)
            ? (plannedWorkingDays * perDay!)
            : 0;

        // If class-based, we need to fetch presentClasses asynchronously
        if (isClassBased) {
          return FutureBuilder<int>(
            future: IoFunctions.getTotalMarkedClasses(widget.sessionId!),

            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              int presentClasses = 0;
              int absentClassesRaw = 0;

              DateTime current = DateTime(
                session.sessionStart.year,
                session.sessionStart.month,
                session.sessionStart.day,
              );

              while (!current.isAfter(today) &&
                  !current.isAfter(session.sessionEnd)) {
                if (current.weekday <= session.activeDaysPerWeek) {
                  final record = sessionAttendance.firstWhereOrNull(
                    (a) =>
                        a.date.year == current.year &&
                        a.date.month == current.month &&
                        a.date.day == current.day,
                  );

                  if (record != null && record.classesPresent != null) {
                    // Count classes individually
                    for (final isClassPresent in record.classesPresent!) {
                      if (isClassPresent) {
                        presentClasses++;
                      } else {
                        absentClassesRaw++;
                      }
                    }
                  } else {
                    // No record for this day → all classes absent
                    absentClassesRaw +=
                        perDay!; // or whatever field stores per-day total
                  }
                }
                current = current.add(const Duration(days: 1));
              }

              print("Present classes: $presentClasses");
              print("Absent classes raw: $absentClassesRaw");

              // apply adjustment on absents safely
              final adjustedAbsent = (absentClassesRaw - adjustment * perDay!)
                  .clamp(0, absentClassesRaw);

              // total = present + adjusted absent
              final totalMarkedClasses = presentClasses + adjustedAbsent;

              final classAttendancePct = totalMarkedClasses == 0
                  ? 0
                  : (presentClasses / totalMarkedClasses) * 100;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    _buildStatRow(
                      "Total working days:",
                      plannedWorkingDays.toString(),
                    ),
                    const SizedBox(height: 20),
                    _buildStatRow(
                      "Total Classes/Lectures:",
                      (perDay != null) ? "$totalClasses" : "Not Set",
                    ),
                    const SizedBox(height: 20),
                    _buildStatRow(
                      "Present Classes:",
                      presentClasses.toString(),
                    ),
                    const SizedBox(height: 20),
                    _buildStatRow("Absent Classes:", adjustedAbsent.toString()),
                    const SizedBox(height: 20),
                    _buildStatRow(
                      "Target attendance:",
                      "${session.targetAttendance}%",
                    ),
                    const SizedBox(height: 12),
                    _buildPercentageRow(
                      "Attendance percentage:",
                      classAttendancePct.toDouble(),
                      session.targetAttendance,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      "Based on classes you marked present.\nUnmarked days (incl. future) don't affect %.\nAdjusted with compensations (holidays/leaves).",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        } else {
          // Day-based UI (synchronous)
          final totalMarked = presentDaysCount + absentDaysCount;
          final double attendancePct = totalMarked == 0
              ? 0.0
              : (presentDaysCount / totalMarked) * 100.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                _buildStatRow(
                  "Total working days/classes:",
                  plannedWorkingDays.toString(),
                ),
                const SizedBox(height: 20),
                _buildStatRow(
                  "Total Classes/Lectures:",
                  perDay != null
                      ? "${plannedWorkingDays * perDay!}"
                      : "Not Set",
                ),
                const SizedBox(height: 20),
                _buildStatRow("Present Days:", presentDaysCount.toString()),
                const SizedBox(height: 20),
                _buildStatRow("Absent Days:", absentDaysCount.toString()),
                const SizedBox(height: 20),
                _buildStatRow(
                  "Target attendance:",
                  "${session.targetAttendance}%",
                ),
                const SizedBox(height: 12),
                _buildPercentageRow(
                  "Attendance percentage:",
                  attendancePct,
                  session.targetAttendance,
                ),
                const SizedBox(height: 20),
                const Text(
                  "Based on days you've marked Present or Absent.\nUnmarked days (incl. future) don't affect %.\nAdjusted with compensations (holidays/leaves).",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          );
        }
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111826),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22303F)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFFEF5350),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPercentageRow(String label, double value, double target) {
    final percentText = "${value.toStringAsFixed(1)}%";
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFF111826),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF22303F)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                percentText,
                style: TextStyle(
                  color: value < target ? Colors.redAccent : Colors.greenAccent,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: (value / 100).clamp(0, 1),
              minHeight: 8,
              backgroundColor: Colors.white10,
              color: value < target ? Colors.redAccent : Colors.greenAccent,
            ),
          ),
        ],
      ),
    );
  }

  void openAdjustmentDialog() {
    _showAdjustmentDialog();
  }
}

class StatisticsScreen extends StatelessWidget {
  final int? sessionId;
  final GlobalKey<_StatisticsViewState> _viewKey = GlobalKey();
  final bool isClassBased;

  StatisticsScreen({
    super.key,
    required this.isClassBased,
    required this.sessionId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF10131A),
        actions: [
          IconButton(
            icon: const Icon(Icons.schedule_rounded),
            onPressed: () {
              Vibration.checkboxToggle();
              _viewKey.currentState?.openAdjustmentDialog();
            },
          ),
        ],
        title: const Text(
          "Statistics",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      backgroundColor: const Color(0xFF0B0D14),
      body: StatisticsView(
        key: _viewKey,
        sessionId: sessionId,
        isClassBased: isClassBased,
      ),
    );
  }
}

import 'package:attendance_manager/DataBase/model_class.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IoFunctions {
  static const String sesBoxName = "SessionBoxV3";
  static const String atBoxName = "AttendanceBoxV3";

  // Hive Set-Up
  static Future<void> initHive() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AttendanceDataAdapter());
      print("Registered attendance adapter");
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(SessionDataAdapter());
      print("Registered session adapter");
    }

    await Hive.openBox<SessionData>(sesBoxName);
    print("Box Opened: $sesBoxName");
    await Hive.openBox<AttendanceData>(atBoxName);
    print("Box Opened: $atBoxName");

    print("Box initialized");
  }

  // ------------------ Session Methods ------------------

  // Create a new session
  static Future<void> createSession(
    DateTime start,
    DateTime end,
    int days,
    double target,
    String name,
    int perDay,
  ) async {
    final sessionBox = Hive.box<SessionData>(sesBoxName);
    final attendanceBox = Hive.box<AttendanceData>(atBoxName); // ✅ declare box

    final data = SessionData(
      sessionStart: start,
      sessionEnd: end,
      creationDate: DateTime.now(),
      activeDaysPerWeek: days,
      targetAttendance: target,
      sessionName: name,
    );

    // Add session once and get the sessionId
    final newSessionId = await sessionBox.add(data);

    // Save classes per day using this new sessionId
    await IoFunctions.classesPerDay(newSessionId, perDay);

    // Clear attendance for new session (safety)
    final existing =
        attendanceBox.values.where((a) => a.sessionId == newSessionId).toList();

    if (existing.isNotEmpty) {
      print(
          "Deleting ${existing.length} existing attendance records for session $newSessionId");
    }

    for (final a in existing) {
      print("Deleting record for ${a.date} → isPresent: ${a.isPresent}");
      await a.delete();
    }

    print("Session saved: $data");
    final sessions = IoFunctions.getAllSessions();
    print("Sessions at HomeScreen:");
    for (var s in sessions) {
      print(
          "Session: ${s.sessionStart} to ${s.sessionEnd}, Active days: ${s.activeDaysPerWeek}");
    }

    //--------Setting adjustment to 0------------
    final pref = await SharedPreferences.getInstance();
    await pref.setInt("adjustment_${newSessionId}", 0);

    final saved = pref.getInt("adjustment_${newSessionId}");
    print("Adjustment for session - ${newSessionId} = $saved");

    //--------Setting class based to false------------
    await pref.setBool('toggleToClassBased_$newSessionId', false);
  }

  //Update session
  static Future<void> updateSession(int? sessionId, DateTime newstart,
      DateTime newend, int newdays, double newtarget, String newName) async {
    final myBox = Hive.box<SessionData>(sesBoxName);
    final session = myBox.get(sessionId);
    if (session != null) {
      session.sessionStart = newstart;
      session.sessionEnd = newend;
      session.activeDaysPerWeek = newdays;
      session.creationDate = DateTime.now();
      session.targetAttendance = newtarget;
      session.sessionName = newName;
      await session.save();

      // Uncheck old saturdays
      if (newdays == 5) {
        final attBox = Hive.box<AttendanceData>(atBoxName);
        for (var att in attBox.values.where((a) => a.sessionId == sessionId)) {
          if (att.date.weekday == DateTime.saturday && att.isPresent) {
            att.isPresent = false;
            await att.save();
          }
        }
      }
    }
  }

  /// Get all sessions
  static List<SessionData> getAllSessions() {
    final sessionBox = Hive.box<SessionData>(sesBoxName);
    return sessionBox.values.toList();
  }

  /// Delete session by index
  static Future<void> deleteSessionAt(int index) async {
    final sessionBox = Hive.box<SessionData>(sesBoxName);
    final key = sessionBox.keyAt(index);
    await sessionBox.deleteAt(index);
    final prefs = await SharedPreferences.getInstance();
    final selected = prefs.getInt('selectedSessionId');
    print("Deleting index: $index, Hive key: $key, Prefs selected: $selected");

    if (selected == key) {
      await prefs.remove('selectedSessionId');
      print("Removed");
    }
  }

  /// Get session at index
  static SessionData? getSessionAt(int index) {
    final sessionBox = Hive.box<SessionData>(sesBoxName);
    return sessionBox.get(index);
  }

  // ------------------ Attendance Methods ------------------
  //  Add Attendance
  static Future<void> addAttendance(AttendanceData data) async {
    final attendanceBox = Hive.box<AttendanceData>(atBoxName);

    // Remove existing attendance for the same date & session (optional)
    final existingRecords = attendanceBox.values.where(
      (a) => a.date == data.date && a.sessionId == data.sessionId,
    );
    if (existingRecords.isNotEmpty) {
      await existingRecords.first.delete();
    }

    await attendanceBox.add(data);
    print("Attendance saved for session ${data.sessionId}: ${data.date}");
  }

  /// Get all attendance
  static List<AttendanceData> getAllAttendance() {
    final attendanceBox = Hive.box<AttendanceData>(atBoxName);
    return attendanceBox.values.toList();
  }

  /// Delete attendance by index
  static Future<void> deleteAttendanceAt(int index) async {
    final attendanceBox = Hive.box<AttendanceData>(atBoxName);
    await attendanceBox.deleteAt(index);
  }

  /// Get attendance at index
  static AttendanceData? getAttendanceAt(int index) {
    final attendanceBox = Hive.box<AttendanceData>(atBoxName);
    return attendanceBox.getAt(index);
  }

  static final Map<String, AttendanceData> _tempAttendanceMap = {};

  static AttendanceData? getTempAttendance(int sessionId, DateTime date) {
    return _tempAttendanceMap["$sessionId-${date.toIso8601String()}"];
  }

  static void updateTempAttendanceClass(
      int sessionId, DateTime date, int classIndex, bool value) {
    final key = "$sessionId-${date.toIso8601String()}";
    if (!_tempAttendanceMap.containsKey(key)) {
      _tempAttendanceMap[key] = AttendanceData(
        sessionId: sessionId,
        date: date,
        isPresent: false,
        classesPresent: List.filled(0, false),
      );
    }
    final dayData = _tempAttendanceMap[key]!;

    if (dayData.classesPresent == null ||
        dayData.classesPresent!.length <= classIndex) {
      // final oldLength = dayData.classesPresent?.length ?? 0;
      dayData.classesPresent ??= List.filled(classIndex + 1, false);
      if (dayData.classesPresent!.length < classIndex + 1) {
        dayData.classesPresent!.addAll(List.filled(
            classIndex + 1 - dayData.classesPresent!.length, false));
      }
    }

    dayData.classesPresent![classIndex] = value;
  }

  // classes per day marking
  static Future<void> toggleClass(
    int sessionId,
    DateTime date,
    int classIndex,
    int perDay,
  ) async {
    final attendanceBox = Hive.box<AttendanceData>(atBoxName);

    // 🔍 Find existing record for that date + session
    AttendanceData? record;
    try {
      record = attendanceBox.values.firstWhere(
        (a) =>
            a.sessionId == sessionId &&
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day,
      );
    } catch (_) {
      record = null;
    }

    if (record == null) {
      // Create a new record if none exists
      record = AttendanceData(
        sessionId: sessionId,
        date: date,
        isPresent: true,
        classesPresent: List.filled(perDay, false),
      );
    } else {
      // Ensure correct list size
      if (record.classesPresent == null ||
          record.classesPresent!.length != perDay) {
        record.classesPresent = List.filled(perDay, false);
      }
    }

    // ✅ Toggle once
    record.classesPresent![classIndex] = !record.classesPresent![classIndex];

    // Save (either update or add new)
    if (record.isInBox) {
      await record.save();
    } else {
      await attendanceBox.add(record);
    }

    print(
        "Saved class $classIndex for ${record.date} in session $sessionId → ${record.classesPresent}");
  }

  // load classes
  /// Load pressed buttons (classes marked present) for a given date & session
  static Future<Set<int>> loadPressedButtons(
    int sessionId,
    DateTime date,
    int totalClasses,
  ) async {
    final attendanceBox = Hive.box<AttendanceData>(atBoxName);

    AttendanceData? record;
    try {
      record = attendanceBox.values.firstWhere(
        (a) =>
            a.sessionId == sessionId &&
            a.date.year == date.year &&
            a.date.month == date.month &&
            a.date.day == date.day,
      );
    } catch (_) {
      record = null;
    }

    if (record == null || record.classesPresent == null) return <int>{};

    final pressed = <int>{};
    for (int i = 0; i < record.classesPresent!.length; i++) {
      if (record.classesPresent![i]) pressed.add(i);
    }

    return pressed;
  }

  // 🔹 Count total attended (marked) classes for a session
  static Future<int> getTotalMarkedClasses(int sessionId) async {
    final attendanceBox = Hive.box<AttendanceData>(atBoxName);

    final records = attendanceBox.values.where((a) => a.sessionId == sessionId);

    int total = 0;

    for (final record in records) {
      if (record.classesPresent != null) {
        total += record.classesPresent!
            .where((isPresent) => isPresent == true)
            .length;
      }
    }

    return total;
  }

  // Shared preference functions.

  // Session ID
  // Save to pref
  static Future<void> saveSelectedSession(int sessionId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('selectedSessionId', sessionId);
  }

  // load from prefs
  static Future<int?> loadSelectedSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt('selectedSessionId');
  }

  // Number of classes per day.
  static Future<void> classesPerDay(int sessionId, int? perDay) async {
    final pref = await SharedPreferences.getInstance();
    if (perDay == null) {
      await pref.remove('classesPerDay$sessionId');
    } else {
      await pref.setInt('classesPerDay$sessionId', perDay);
    }
  }

  static Future<int?> loadClassesPerDay(int sessionId) async {
    final pref = await SharedPreferences.getInstance();
    return pref.getInt('classesPerDay$sessionId');
  }

  // toggle classes per day instead of days
  static Future<void> toggleClassBased(int sessionId, bool isClassBased) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('toggleToClassBased_$sessionId', isClassBased);
  }

  static Future<bool?> checkClassBased(int sessionId) async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool('toggleToClassBased_$sessionId');
  }

  //----------Select all classes Dailog, appearance one------------
  static Future<void> selectAllClassesDailog(bool isShown) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool('allClassesDailogShown', isShown);
  }

  static Future<bool> checkClassesDailogShown() async {
    final pref = await SharedPreferences.getInstance();
    return pref.getBool('allClassesDailogShown') ?? false;
  }
}

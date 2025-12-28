import 'package:hive/hive.dart';

part 'model_class.g.dart'; // ✅ lowercase and snake_case only!

//Box 1
@HiveType(typeId: 0)
class AttendanceData extends HiveObject {
  @HiveField(0)
  DateTime date;

  @HiveField(1)
  bool isPresent;

  @HiveField(2)
  List<bool>? classesPresent;

  @HiveField(3)
  int sessionId;

  AttendanceData(
      {required this.date,
      required this.isPresent,
      this.classesPresent,
      required this.sessionId});
}

// Box 2
@HiveType(typeId: 1)
class SessionData extends HiveObject {
  @HiveField(0)
  DateTime sessionStart;

  @HiveField(1)
  DateTime sessionEnd;

  @HiveField(2)
  DateTime creationDate;

  @HiveField(3)
  int activeDaysPerWeek;

  @HiveField(4)
  double targetAttendance;

  @HiveField(5)
  String sessionName;

  SessionData({
    required this.sessionStart,
    required this.sessionEnd,
    required this.creationDate,
    required this.activeDaysPerWeek,
    required this.targetAttendance,
    required this.sessionName,
  });
}

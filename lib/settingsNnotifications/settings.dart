import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'NotificationService.dart';

class Settings extends StatefulWidget {
  final int? sessionId;
  const Settings({super.key, required this.sessionId});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  bool isNoti = false;
  late TimeOfDay? dailyTime;

  late int weekDays;

  @override
  void initState() {
    super.initState();

    // Handle null safely
    if (widget.sessionId == null) return;

    getNotiFromPref(widget.sessionId!);
    _loadTime();

    final session = IoFunctions.getSessionAt(widget.sessionId!);
    if (session != null) {
      weekDays = session.activeDaysPerWeek;
    }
  }

  Future<void> _loadTime() async {
    final time = await NotificationService.getTime(widget.sessionId!);
    setState(() {
      dailyTime = time;
    });
  }

  // Save to prefs
  void addNotiToPref(int sessionId, bool isNoti) async {
    final pref = await SharedPreferences.getInstance();
    await pref.setBool("isNotification_$sessionId", isNoti);
  }

  // Get from prefs
  void getNotiFromPref(int sessionId) async {
    final pref = await SharedPreferences.getInstance();
    final saved = pref.getBool("isNotification_$sessionId") ?? false;
    setState(() {
      isNoti = saved;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessionId == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Settings"),
          backgroundColor: const Color(0xFF10131A),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        backgroundColor: const Color(0xFF0B0D14),
        body: const Center(
          child: Text(
            "No session yet. Create new",
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0B0D14),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF10131A),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            const Text(
              "Notifications",
              style: TextStyle(color: Colors.white, fontSize: 26),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121825),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2C344A)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 18,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Expanded(
                      child: Text(
                        "Enable Notifications",
                        style: TextStyle(color: Colors.white, fontSize: 17),
                      ),
                    ),
                    Switch(
                      value: isNoti,
                      onChanged: (bool newVal) {
                        setState(() {
                          isNoti = newVal;
                        });
                        if (isNoti == false) {
                          NotificationService.cancelSessionNoti(
                            widget.sessionId!,
                          );
                        }
                        addNotiToPref(widget.sessionId!, newVal);
                      },
                      activeThumbColor: const Color(0xFF4FC3F7),
                      inactiveThumbColor: Colors.white54,
                      inactiveTrackColor: Colors.white12,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF121825),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF2C344A)),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: Text(
                  "You'll receive 2 different notifications:\n\n"
                  "1. A daily reminder to mark your attendance.\n"
                  "2. A warning if your attendance % falls below your target.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            if (isNoti)
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF121825),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2C344A)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          "Daily notification time",
                          style: TextStyle(color: Colors.white, fontSize: 15),
                        ),
                      ),
                      const SizedBox(width: 6),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await NotificationService.timePicker(
                            context,
                            dailyTime,
                            widget.sessionId!,
                          );
                          if (picked != null) {
                            setState(() {
                              dailyTime = picked;
                            });
                          }
                          if (dailyTime != null) {
                            NotificationService.createNotification(
                              dailyTime!,
                              weekDays,
                              widget.sessionId!,
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4FC3F7),
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: Text(
                          dailyTime != null
                              ? MaterialLocalizations.of(
                                  context,
                                ).formatTimeOfDay(
                                  dailyTime!,
                                  alwaysUse24HourFormat: false,
                                )
                              : "Set Time",
                          style: const TextStyle(fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

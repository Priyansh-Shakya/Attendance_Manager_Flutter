import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'NotificationService.dart';

class Settings extends StatefulWidget {
  final int? sessionId;
  const Settings({Key? key, required this.sessionId}) : super(key: key);

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
          backgroundColor: const Color(0xff1c1c1c),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context), // go back
          ),
        ),
        body: const Center(
          child: Text(
            "No Session yet. Create new",
            style: TextStyle(color: Colors.white, fontSize: 15),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xff141414),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "Settings",
          style: TextStyle(
              color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xff1c1c1c),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            const Text(
              "Notifications",
              style: TextStyle(color: Colors.white, fontSize: 25),
            ),
            const SizedBox(height: 10),

            // 🔔 Notification Switch
            Container(
              decoration: BoxDecoration(
                color: const Color(0xff2e2e2e),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Enable Notifications",
                        style: TextStyle(color: Colors.white, fontSize: 18)),
                    Switch(
                      value: isNoti,
                      onChanged: (bool newVal) {
                        setState(() {
                          isNoti = newVal;
                        });
                        if (isNoti == false) {
                          NotificationService.cancelSessionNoti(
                              widget.sessionId!);
                        }
                        addNotiToPref(widget.sessionId!, newVal);
                      },
                      activeColor: Colors.green,
                      inactiveThumbColor: Colors.grey,
                      inactiveTrackColor: Colors.grey[700],
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 📄 Info Card
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xff1f1f1f),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  "You'll receive 2 different notifications:\n\n"
                  "1. A daily reminder to mark your attendance.\n"
                  "2. A warning if your attendance % falls below your target.",
                  style:
                      TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
                ),
              ),
            ),
            SizedBox(
              height: 15,
            ),

            if (isNoti)
              // Input time
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xff1f1f1f),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Row(children: [
                    Expanded(
                      child: Text(
                        "Enter daily notification time:",
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    SizedBox(
                      width: 5,
                    ),
                    ElevatedButton(
                        onPressed: () async {
                          final picked = await NotificationService.timePicker(
                              context, dailyTime, widget.sessionId!);
                          if (picked != null) {
                            setState(() {
                              dailyTime = picked;
                            });
                          }
                          NotificationService.createNotification(
                              dailyTime!, weekDays, widget.sessionId!);
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xff424242)),
                        child: Text(
                          dailyTime != null
                              ? MaterialLocalizations.of(context)
                                  .formatTimeOfDay(
                                  dailyTime!,
                                  alwaysUse24HourFormat:
                                      false, // 👈 ensures AM/PM format
                                )
                              : "Time",
                        )),
                  ]),
                ),
              ),
          ],
        ),
      ),
    );
  }
}


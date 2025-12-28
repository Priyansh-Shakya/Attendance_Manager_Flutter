import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:attendance_manager/calendre.dart';
import 'package:attendance_manager/homeScreen.dart';
import 'package:attendance_manager/statistics.dart';
import 'package:attendance_manager/testScreen.dart';
import 'package:flutter/material.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int? sessionSelectedID;
  int currentIndex = 0;
  bool isClassBased = true;
  final PageStorageBucket bucket = PageStorageBucket();

  // Make these class fields
  int plannedWorkingDays = 0;
  int presentCount = 0;
  int absentCount = 0;
  double attendancePct = 0;

  @override
  void initState() {
    super.initState();
    _loadSessionAndClassMode();
  }

  Future<void> _loadSessionAndClassMode() async {
    final id = await IoFunctions.loadSelectedSession();
    if (id != null) {
      final classMode = await IoFunctions.checkClassBased(id) ?? false;

      setState(() {
        sessionSelectedID = id;

        print(sessionSelectedID);

        isClassBased = classMode;
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(
        onSessionSelected: (id) {
          setState(() {
            sessionSelectedID = id;
            print(sessionSelectedID);
          });
          IoFunctions.saveSelectedSession(id);
        },
      ),
      CalenderScreen(
        key: ValueKey(
            sessionSelectedID), // PageStorageKey("Calendar_$sessionSelectedID"),
        sessionID: sessionSelectedID,
        showFuture: false,
        onClassBasedChanged: (value) {
          setState(() {
            isClassBased = value;
          });
        },
      ),
      StatisticsScreen(
        key: ValueKey(
            sessionSelectedID), // PageStorageKey("Statistics_$sessionSelectedID"),
        sessionId: sessionSelectedID,
        isClassBased: isClassBased,
      ),
      TestScreen(
        key: ValueKey(
            sessionSelectedID), //PageStorageKey("Test_$sessionSelectedID"),
        sessionId: sessionSelectedID,
      ),
    ];

    return Scaffold(
      body: PageStorage(
        bucket: bucket,
        child: screens[currentIndex],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xff141414),
        selectedItemColor: Colors.red,
        unselectedItemColor: Colors.white,
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_month), label: "Calendar"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Stats"),
          BottomNavigationBarItem(icon: Icon(Icons.analytics), label: "Test")
        ],
      ),
    );
  }
}
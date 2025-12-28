import 'package:attendance_manager/DataBase/IoFunctions.dart';
import 'package:attendance_manager/mainScreen.dart';
import 'package:attendance_manager/settingsNnotifications/NotificationService.dart';
import 'package:flutter/material.dart';
import 'dart:async';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // root zone

  await IoFunctions.initHive();
  await NotificationService.initAwesomeNoti();
  await NotificationService.checkForPermission();
  runApp(const MyApp());
  // runZonedGuarded(
  //   () {
  //      // same zone as ensureInitialized ✅
  //   },
  //   (error, stack) {
  //     print('Uncaught error: $error');
  //   },
  // );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Attendance Manager',
      theme: ThemeData.dark(),
      home: const MainScreen(),
    );
  }
}

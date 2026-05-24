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
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0B0D14),
        canvasColor: const Color(0xFF0B0D14),
        cardColor: const Color(0xFF141B2C),
        primaryColor: const Color(0xFFEF5350),
        colorScheme: ThemeData.dark().colorScheme.copyWith(
          primary: const Color(0xFFEF5350),
          secondary: const Color(0xFF4FC3F7),
          surface: const Color(0xFF0B0D14),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF10131A),
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Color(0xFF10131A),
          selectedItemColor: Color(0xFFEF5350),
          unselectedItemColor: Colors.white70,
          selectedIconTheme: IconThemeData(size: 24),
          unselectedIconTheme: IconThemeData(size: 22),
          showUnselectedLabels: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFEF5350),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF172033),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.white12),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFF4FC3F7)),
          ),
          hintStyle: const TextStyle(color: Colors.white54),
          labelStyle: const TextStyle(color: Colors.white70),
        ),
      ),
      home: const MainScreen(),
    );
  }
}

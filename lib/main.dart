import 'package:child_and_student_care_and_tracking_app/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return  MaterialApp(
      title: 'Student Care Track System',
      debugShowCheckedModeBanner: false,
      //our themes applied here
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      //the ff setting lets the system choose(or we can force one)
      themeMode: ThemeMode.system,
      home: Center(
        child: Text('Theme is now active'),
      ),
    );
  }
}

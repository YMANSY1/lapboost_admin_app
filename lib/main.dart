import 'package:flutter/material.dart';
import 'package:lapboost_admin_app/screens/auth_screen.dart';

void main() {
  runApp(const LapboostAdminApp());
}

class LapboostAdminApp extends StatelessWidget {
  const LapboostAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: AuthScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

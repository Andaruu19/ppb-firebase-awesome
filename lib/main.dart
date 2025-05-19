import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:ppb_awesome_notification/firebase_options.dart'; // Impor file ini
import 'package:ppb_awesome_notification/screens/home_screen.dart';
import 'package:ppb_awesome_notification/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // Gunakan ini
  );
  await NotificationService.initializeNotifications();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Task Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const HomeScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
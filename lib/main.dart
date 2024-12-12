import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../Pages/SplashScreen.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await dotenv.load(fileName: "Backend/.env"); // Load the .env file
  runApp(MyApp());
}

//Backend\.env
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RemSenseAI',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF121C38)),
        useMaterial3: true,
      ),
      home: SplashScreen(),
    );
  }
}


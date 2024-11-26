import 'package:flutter/material.dart';
import 'MyHomePage.dart'; // Your Login Page

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // Navigate to the login page after 2 seconds
    Future.delayed(Duration(seconds: 2), () {//callback function.
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'Login Page')),
      );
    });
  }//init state done.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Change background color if needed
      body: Center(
        child: Image.asset('assets/logo.png',
            width: 150, height: 150), // Replace with your logo
      ),
    );
  }
}

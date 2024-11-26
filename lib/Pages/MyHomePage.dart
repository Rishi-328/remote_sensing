import 'package:flutter/material.dart';
import 'Sign_up_Page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'WelcomePage.dart';
import 'mainscreen.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // Text editing controllers for the text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String?> _getEmailFromUsername(String username) async {
    try {
      // Query the Firestore to find the email based on the entered username
      QuerySnapshot query = await _firestore
          .collection('users')
          .where('username', isEqualTo: username)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return query.docs.first['email'];
      } else {
        return null; // Username not found
      }
    } catch (e) {
      return null; // Error occurred
    }
  }

  Future<void> _login() async {
    String username = _usernameController.text;
    String password = _passwordController.text;

    // Get the email associated with the entered username
    String? email = await _getEmailFromUsername(username);

    if (email != null) {
      try {
        // Sign in using Firebase Authentication with the extracted email and password
        await _auth.signInWithEmailAndPassword(
            email: email, password: password);

        // Navigate to the Welcome Page on successful login
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const mainscreen()),
        );
      } on FirebaseAuthException catch (e) {
        String message;
        if (e.code == 'user-not-found') {
          message = 'No user found for that email.';
        } else if (e.code == 'wrong-password') {
          message = 'Wrong password provided.';
        } else {
          message = 'An error occurred: ${e.message}';
        }
        _showErrorMessage(message);
      }
    } else {
      _showErrorMessage('Username not found.');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      border: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }

  Widget _buildTextField(
      {required TextEditingController controller,
      required String label,
      bool obscureText = false}) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: _buildInputDecoration(label),
      cursorColor: Colors.white,
    );
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Container(
          height: mediaQuery.size.height, // Makes it fill the available space
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/background2.jpg'),
              fit: BoxFit.cover, // Better suited for full background images
            ),
          ),
          padding:
              const EdgeInsets.all(16.0), // You can adjust the padding here
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // TextField for email (username)
              _buildTextField(
                controller: _usernameController,
                label: 'Username',
              ),

              const SizedBox(height: 16), // Space between fields

              // TextField for password
              _buildTextField(
                controller: _passwordController,
                label: 'Password',
                obscureText: true,
              ),
              const SizedBox(
                  height: 16), // Space between the password field and button

              ElevatedButton(
                onPressed: _login,
                child: const Text('Login'),
              ),
              const SizedBox(height: 8),

              // Text button for sign up with underlined text
              TextButton(
                onPressed: () {
                  // Navigate to the SignUpPage
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignUpPage()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: 'New User ? Click on ',
                        style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 18.0, // Increase the font size here
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                      ),
                      TextSpan(
                        text: 'Sign Up',
                        style: TextStyle(
                          color: Color.fromARGB(
                              255, 255, 255, 255), // Color for the link
                          decoration: TextDecoration
                              .underline, // Underline the 'Sign Up' text
                          fontSize: 18.0, // Increase the font size here
                          fontWeight: FontWeight.bold, // Make the text bold
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

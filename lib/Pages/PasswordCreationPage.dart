import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'AccountCreatedPage.dart';
import 'CommonBackground.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PasswordCreationPage extends StatefulWidget {
  final String email;
  final String firstName;
  final String lastName;
  final String username;
  final String address;

  const PasswordCreationPage({
    Key? key,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.address,
  }) : super(key: key);

  @override
  State<PasswordCreationPage> createState() => _PasswordCreationPageState();
}

class _PasswordCreationPageState extends State<PasswordCreationPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _createAccountAndSaveToFirestore() async {
    try {
      // Create the user in Firebase Authentication using email and password
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: widget.email,
        password: _passwordController.text,
      );

      // Once the user is created, store additional user details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': widget.email,
        'firstName': widget.firstName,
        'lastName': widget.lastName,
        'username': widget.username,
        'address': widget.address,
        'created_at': DateTime.now(),
      });

      // Navigate to the Account Created Success Page
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AccountCreatedPage(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      // Handle Firebase Authentication errors
      _showErrorMessage(
        e.code == 'weak-password'
            ? 'The password provided is too weak.'
            : e.code == 'email-already-in-use'
                ? 'The account already exists for that email.'
                : 'An error occurred: ${e.message}',
      );
    } catch (e) {
      // Handle other potential errors
      _showErrorMessage('An error occurred: $e');
    }
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  InputDecoration _buildInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      border: const OutlineInputBorder(),
    );
  }

  Widget _buildPasswordTextField(
      {required TextEditingController controller, required String label}) {
    return TextField(
      controller: controller,
      obscureText: true,
      style: const TextStyle(color: Colors.white),
      decoration: _buildInputDecoration(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Password'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: CommonBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Create your password',
                style: TextStyle(fontSize: 16, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Password field
              _buildPasswordTextField(
                controller: _passwordController,
                label: 'Password',
              ),
              const SizedBox(height: 16),

              // Confirm Password field
              _buildPasswordTextField(
                controller: _confirmPasswordController,
                label: 'Confirm Password',
              ),
              const SizedBox(height: 16),

              // Set Password button
              ElevatedButton(
                onPressed: () async {
                  if (_passwordController.text ==
                      _confirmPasswordController.text) {
                    // Navigate to Account Created Success Page

                    // Create user account and save data to Firestore
                    await _createAccountAndSaveToFirestore();
                  } else {
                    // Show error if passwords don't match
                    _showPasswordMismatchDialog();
                  }
                },
                child: const Text('Set Password'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPasswordMismatchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: const Text('Passwords do not match, try again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

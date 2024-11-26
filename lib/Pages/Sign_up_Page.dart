import 'package:flutter/material.dart';
import 'EmailInputPage.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Text editing controllers for the sign-up fields
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    return Scaffold(
      

      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,

      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(16.0),
            constraints: BoxConstraints(
              minHeight: screenHeight,
            ),
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background2.jpg'),
                fit: BoxFit.cover,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // First name field
                _buildTextField(
                  controller: _firstNameController,
                  labelText: 'First Name',
                ),
                // Last name field
                _buildTextField(
                  controller: _lastNameController,
                  labelText: 'Last Name',
                ),
                // Username field
                _buildTextField(
                  controller: _usernameController,
                  labelText: 'Username',
                ),
                // Address field
                _buildTextField(
                  controller: _addressController,
                  labelText: 'Address',
                ),
                // Submit button to navigate to email input
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EmailInputPage(
                          firstName: _firstNameController.text,
                          lastName: _lastNameController.text,
                          username: _usernameController.text,
                          address: _addressController.text,
                        ),
                      ),
                    );
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method to create a common InputDecoration
  InputDecoration _buildInputDecoration(String labelText) {
    return InputDecoration(
      labelText: labelText,
      labelStyle: const TextStyle(color: Colors.white),
      border: const OutlineInputBorder(),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white),
      ),
    );
  }

  // Helper method to create a common TextField
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
  }) {
    return Column(
      children: [
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: _buildInputDecoration(labelText),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'MyHomePage.dart';
import 'CommonBackground.dart';

class AccountCreatedPage extends StatelessWidget {
  const AccountCreatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Password Creation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: CommonBackground(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Your account has been created successfully.\nYou can now login with your credentials.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white, // Set the text color to white
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // RichText for login link with white text
              RichText(
                text: TextSpan(
                  text: 'Click here to ',
                  style: const TextStyle(
                    color: Colors.white, // Set the regular text to white
                    fontSize: 16,
                  ),
                  children: [
                    TextSpan(
                      text: 'Login',
                      style: const TextStyle(
                        color: Colors.white, // Set the link text to white
                        decoration: TextDecoration
                            .underline, // Keep the underline for the link
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          // Navigate to the existing MyHomePage
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const MyHomePage(
                                title: 'Login Page',
                              ),
                            ),
                          );
                        },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

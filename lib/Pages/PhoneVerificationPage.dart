// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'package:remote_sensing/Pages/CommonBackground.dart';
// import 'dart:convert';
// import 'EmailInputPage.dart';
// import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

// class PhoneVerificationPage extends StatefulWidget {
//   final String phoneNumber;

//   // final String phoneNumber;
//   final String firstName;
//   final String lastName;
//   final String username;
//   final String address;

//   const PhoneVerificationPage({
//     Key? key,
//     required this.phoneNumber,
//     required this.firstName,
//     required this.lastName,
//     required this.username,
//     required this.address,
//   }) : super(key: key);

//   @override
//   _PhoneVerificationPageState createState() => _PhoneVerificationPageState();
// }

// class _PhoneVerificationPageState extends State<PhoneVerificationPage> {
//   final TextEditingController _otpController =
//       TextEditingController(); // OTP input field controller

//   Future<bool> verifyOtp(String phoneNumber, String otp) async {
//     // Load IP from the .env file
//     final serverIp = dotenv.env['SERVER_IP'];
//     final response = await http.post(
//       Uri.parse('http://$serverIp:5000/verify-otp'),
//       headers: {'Content-Type': 'application/json'},
//       body: jsonEncode({'phoneNumber': phoneNumber, 'otp': otp}),
//     );

//     if (response.statusCode == 200) {
//       // OTP verification successful, show success dialog
//       _showSuccessDialog();

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => EmailInputPage(
//             firstName: widget.firstName,
//             lastName: widget.lastName,
//             username: widget.username,
//             address: widget.address,
//             phoneNumber: widget.phoneNumber,
//           ),
//         ),
//       );
//       return true;
//     } else {
//       _showErrorDialog('Failed to verify OTP. Please try again.');
//     }
//     return false;
//   }

//   void _showErrorDialog(String message) {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Error'),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(ctx).pop();
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Show success dialog
//   void _showSuccessDialog() {
//     showDialog(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         title: const Text('Success'),
//         content: const Text('OTP verified successfully!'),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.of(ctx).pop();

//               Navigator.pushReplacement(
//                 context,
//                 MaterialPageRoute(
//                   builder: (context) => EmailInputPage(
//                     firstName: widget.firstName,
//                     lastName: widget.lastName,
//                     username: widget.username,
//                     address: widget.address,
//                     phoneNumber: widget.phoneNumber,
//                   ),
//                 ),
//               );
//             },
//             child: const Text('OK'),
//           ),
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Phone Verification'),
//         backgroundColor: Theme.of(context).colorScheme.inversePrimary,
//       ),
//       body: Center(
//         child: SingleChildScrollView(
//           child: CommonBackground(
//             child: Padding(
//               padding: const EdgeInsets.all(16.0), // Add padding for spacing
//               child: Column(
//                 mainAxisAlignment:
//                     MainAxisAlignment.center, // Center the content vertically
//                 mainAxisSize: MainAxisSize
//                     .min, // Ensures the column takes up only the necessary space
//                 children: [
//                   TextField(
//                     controller: _otpController,
//                     keyboardType: TextInputType.number,
//                     style: const TextStyle(
//                         color: Colors.white), // Make the input text white
//                     decoration: const InputDecoration(
//                       labelText: 'Enter OTP',
//                       labelStyle: TextStyle(
//                           color: Colors.white), // Make the label text white
//                       border: OutlineInputBorder(
//                         borderSide: BorderSide(
//                             color: Colors.white), // Make the border white
//                       ),
//                       enabledBorder: OutlineInputBorder(
//                         borderSide: BorderSide(
//                             color: Colors
//                                 .white), // Border color when field is enabled
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderSide: BorderSide(
//                             color: Colors
//                                 .white), // Border color when field is focused
//                       ),
//                     ),
//                   ),

//                   const SizedBox(height: 20),

//                   // Button to verify OTP
//                   ElevatedButton(
//                     onPressed: () {
//                       verifyOtp(widget.phoneNumber, _otpController.text);
//                     },
//                     child: const Text('Verify OTP'),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

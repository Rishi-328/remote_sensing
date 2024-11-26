// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import '../Pages/PhoneVerificationPage.dart';
// Future<void> _sendOTP() async {
//   await FirebaseAuth.instance.verifyPhoneNumber(
//     phoneNumber: '+91${_phoneController.text}',  // Replace with correct country code
//     verificationCompleted: (PhoneAuthCredential credential) async {
//       // Auto-retrieval or instant verification (Android only)
//       await FirebaseAuth.instance.signInWithCredential(credential);
//     },
//     verificationFailed: (FirebaseAuthException e) {
//       print('Failed to verify phone number: ${e.message}');
//     },
//     codeSent: (String verificationId, int? resendToken) {
//       // Store the verification ID to use for OTP verification
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => PhoneVerificationPage(verificationId: verificationId)),
//       );
//     },
//     codeAutoRetrievalTimeout: (String verificationId) {},
//   );
// }

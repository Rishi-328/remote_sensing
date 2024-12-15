import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv

class WelcomePage extends StatefulWidget {
  const WelcomePage({super.key});

  @override
  _WelcomePageState createState() => _WelcomePageState();
}

class _WelcomePageState extends State<WelcomePage> {
  File? _image;
  String? _prediction;
  String? _serverIp;
  String? _port;

  @override
  void initState() {
    super.initState();
    // Load the environment variables
    // _loadEnv();
  }

  // Future<void> _loadEnv() async {
  //   await dotenv.load(); // Load the environment variables
  //   setState(() {
  //     _serverIp = dotenv.env['SERVER_IP']; // Get the SERVER_IP
  //     print('Server IP loaded: $_serverIp'); // Debugging line
  //   });
  // }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage =
          await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
          print('Image selected: ${_image!.path}'); // Debugging line
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _uploadImage() async {
    final serverIp = dotenv.env['SERVER_IP'];
    final port = dotenv.env['PORT'];
    if (_image == null) {
      print('No image to upload'); // Debugging line
      return;
    }

    // Convert image to Base64
    String base64Image = base64Encode(_image!.readAsBytesSync());
    print(
        'Base64 image size: ${base64Image.length} characters'); // Debugging line

    // Prepare the request payload
    var response = await http.post(
      Uri.parse('http://$serverIp:$port/predict'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image': base64Image,
      }),
    );

    // Handle the response
    print('Response status: ${response.statusCode}'); // Debugging line
    if (response.statusCode == 200) {
      var resBody = json.decode(response.body);
      setState(() {
        _prediction = resBody['crop'];
        print('Prediction received: $_prediction'); // Debugging line
      });
    } else {
      print('Error: ${response.body}'); // Debugging line
      setState(() {
        _prediction = 'Error: Could not predict the crop.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crop Classification'),
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            
            const SizedBox(height: 16),
            _image == null
                ? const Text('No image selected.')
                : Image.file(
                    _image!,
                    height: 200,
                    width: 200,
                  ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickImage,
              child: const Text('Select Image from Gallery'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _uploadImage,
              child: const Text('Upload and Predict'),
            ),
            const SizedBox(height: 16),
            _prediction == null
                ? const Text('Prediction will appear here.')
                : Text(
                    'Predicted crop: $_prediction',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ],
        ),
      ),
    );
  }
}

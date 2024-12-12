import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:typed_data';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: const FloodDetection(),
    );
  }
}

class FloodDetection extends StatefulWidget {
  const FloodDetection({super.key});

  @override
  _FloodDetectionState createState() => _FloodDetectionState();
}

class _FloodDetectionState extends State<FloodDetection> {
  File? _image;
  String? _serverIp;
  Image? _originalImage;
  Image? _predictedMask;
  Image? _resultImage;
  bool? _floodDetected;

  @override
  void initState() {
    super.initState();
    // Uncomment and implement environment loading if needed
    // _loadEnv();
  }

  // Future<void> _loadEnv() async {
  //   await dotenv.load();
  //   setState(() {
  //     _serverIp = dotenv.env['SERVER_IP'];
  //     print('Server IP loaded: $_serverIp');
  //   });
  // }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? pickedImage = await picker.pickImage(source: ImageSource.gallery);

      if (pickedImage != null) {
        setState(() {
          _image = File(pickedImage.path);
          _originalImage = Image.file(_image!);
          print('Image selected: ${_image!.path}');
        });
      }
    } catch (e) {
      print("Error picking image: $e");
    }
  }

  Future<void> _detectFlood() async {
    final serverIp = dotenv.env['SERVER_IP'];
    if (_image == null) {
      print('No image to upload');
      return;
    }

    // Convert image to Base64
    String base64Image = base64Encode(_image!.readAsBytesSync());
    print('Base64 image size: ${base64Image.length} characters');

    // Prepare the request payload
    var response = await http.post(
      Uri.parse('http://$serverIp:5000/flood'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'image': base64Image,
      }),
    );

    // Handle the response
    print('Response status: ${response.statusCode}');
    if (response.statusCode == 200) {
      var resBody = json.decode(response.body);
      
      // Decode base64 images
      Uint8List predictedMaskBytes = base64Decode(resBody['predicted_mask']);
      Uint8List resultImageBytes = base64Decode(resBody['result_image']);

      setState(() {
        _predictedMask = Image.memory(predictedMaskBytes);
        _resultImage = Image.memory(resultImageBytes);
        _floodDetected = resBody['flood_detected'];
        print('Flood detection completed');
      });
    } else {
      print('Error: ${response.body}');
      setState(() {
        _floodDetected = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flood Detection'),
      ),
      backgroundColor: Colors.grey[200],
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 16),
                // Display selected image
                _originalImage == null
                    ? const Text('No image selected.')
                    : Column(
                        children: [
                          const Text('Original Image:'),
                          _originalImage!,
                        ],
                      ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _pickImage,
                  child: const Text('Select Image from Gallery'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _detectFlood,
                  child: const Text('Detect Flood'),
                ),
                const SizedBox(height: 16),
                // Display flood detection results
                if (_floodDetected != null) ...[
                  Text(
                    _floodDetected! 
                      ? 'Flood Detected!' 
                      : 'No Flood Detected',
                    style: TextStyle(
                      color: _floodDetected! ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                if (_predictedMask != null) ...[
                  const SizedBox(height: 16),
                  const Text('Predicted Flood Mask:'),
                  _predictedMask!,
                ],
                if (_resultImage != null) ...[
                  const SizedBox(height: 16),
                  const Text('Result Image with Flood Contours:'),
                  _resultImage!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
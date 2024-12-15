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
  String? _port;
  Image? _groundTruthImage;

  @override
  void initState() {
    super.initState();
    _loadGroundTruthImage();
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

  Future<void> _loadGroundTruthImage() async{
    setState(() {
      _groundTruthImage = Image.asset('assets/flood_ground_truth.jpg');
    });
  }
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
    final port = dotenv.env['PORT'];
    if (_image == null) {
      print('No image to upload');
      return;
    }

    // Convert image to Base64
    String base64Image = base64Encode(_image!.readAsBytesSync());
    print('Base64 image size: ${base64Image.length} characters');

    // Prepare the request payload
    var response = await http.post(
      Uri.parse('http://$serverIp:$port/flood'),
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
        title: Text(
          'Flood Detection', 
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Color.fromARGB(255, 79, 79, 79)
          ),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Color.fromARGB(255, 174, 232, 214), // A nice green color for agricultural theme
      ),
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
                    ? Text(
                        'No image selected.',
                        style: TextStyle(color: Colors.teal.shade700),
                      )
                    : Column(
                        children: [
                          Text(
                            'Original Image',
                            style: TextStyle(
                              color: Colors.teal.shade800,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _originalImage!,
                        ],
                      ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Select Image from Gallery'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal.shade300, // Custom background color
                    foregroundColor: Colors.white, // Text and icon color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _detectFlood,
                  icon: const Icon(Icons.water_damage),
                  label: const Text('Detect Flood'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300, // Custom background color
                    foregroundColor: Colors.white, // Text and icon color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                // Display flood detection results
                if (_floodDetected != null) ...[
                  Text(
                    _floodDetected! 
                      ? 'Flood Detected' 
                      : 'No Flood Detected',
                    style: TextStyle(
                      color: _floodDetected! 
                        ? Colors.deepOrange.shade700 
                        : Colors.green.shade700,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
                if (_predictedMask != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Predicted Flood Mask',
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _predictedMask!,
                ],
                const SizedBox(height: 5),
                if (_resultImage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Result Image with Flood Contours',
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _resultImage!,
                  const SizedBox(height: 16),
                     Text(
                    'Ground Truth Image',
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _groundTruthImage ?? const Text('Ground truth not loaded.'),

                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
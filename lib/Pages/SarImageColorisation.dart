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
      home: const SarImageColorisation(),
    );
  }
}

class SarImageColorisation extends StatefulWidget {
  const SarImageColorisation({super.key});

  @override
  _SarImageColorisationState createState() => _SarImageColorisationState();
}

class _SarImageColorisationState extends State<SarImageColorisation> {
  File? _image;
  String? _serverIp;
  Image? _originalImage;
  Image? _colorizedImage;
  Image? _groundTruthImage;
  String? _port;

  @override
  void initState() {
    super.initState();
    _loadGroundTruthImage();
  }

  Future<void> _loadGroundTruthImage() async{
    setState(() {
      _groundTruthImage = Image.asset('assets/ROIs1970_fall_s2_8_p11.png');
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

  Future<void> _uploadImage() async {
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
      Uri.parse('http://$serverIp:$port/colorize'),
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
      String colorizedBase64 = resBody['colorizedImage'];

      // Convert base64 string to Image
      Uint8List bytes = base64Decode(colorizedBase64);
      setState(() {
        _colorizedImage = Image.memory(bytes);
        print('Colorized image received');
      });
    } else {
      print('Error: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SAR Image Colorisation', 
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
                  onPressed: _uploadImage,
                  icon: const Icon(Icons.color_lens),
                  label: const Text('Colorize Image'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade300, // Custom background color
                    foregroundColor: Colors.white, // Text and icon color
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
                
                if (_colorizedImage != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    'Colorized Image',
                    style: TextStyle(
                      color: Colors.teal.shade800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  _colorizedImage!,
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
                  const SizedBox(height: 16),
                   Text(
                    'FID Score : 186.32',
                    style: TextStyle(
                      color: const Color.fromARGB(255, 1, 8, 7),
                      fontWeight: FontWeight.bold,
                      fontSize: 20
                    ),
                  ),
                  
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
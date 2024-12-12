import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'dart:typed_data';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Remove debug banner
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
  String? _prediction;
  String? _serverIp;
  Image? _colorizedImage; // Holds the colorized image
  Image? _groundTruthImage;

  @override
  void initState() {
    super.initState();
     _loadGroundTruthImage();
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


 
  Future<void> _loadGroundTruthImage() async{
    setState(() {
      _groundTruthImage = Image.asset('assets/ROIs1970_fall_s2_8_p11.png');
    });
  }

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
    if (_image == null) {
      print('No image to upload'); // Debugging line
      return;
    }

    // Convert image to Base64
    String base64Image = base64Encode(_image!.readAsBytesSync());
    print('Base64 image size: ${base64Image.length} characters'); // Debugging line

    // Prepare the request payload
    var response = await http.post(
      Uri.parse('http://$serverIp:5000/colorize'),
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
      String colorizedBase64 = resBody['colorizedImage'];

      // Convert base64 string to Image
      Uint8List bytes = base64Decode(colorizedBase64);
      setState(() {
        _colorizedImage = Image.memory(bytes); // Update the colorized image
        print('Colorized image received'); // Debugging line
      });
    } else {
      print('Error: ${response.body}'); // Debugging line
      setState(() {
        _prediction = 'Error: Could not colorize the image.';
      });
    }
  }

@override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Sar Image Colorisation'),
    ),
    backgroundColor: Colors.grey[200],
    body: SingleChildScrollView(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0), // Add padding for spacing
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center, // Center horizontally
            children: [
              const SizedBox(height: 16),
              // Display selected image if it's available
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
              // Display the colorized image if available
              _colorizedImage == null
                  ? const Text('Colorized image will appear here.')
                  : Column(
                      children: [
                        const Text('Colorized Image:'),
                        const SizedBox(height: 8),
                        _colorizedImage!,
                        const SizedBox(height: 16),
                        // Display the ground truth image only when colorized image is available
                        const Text('Ground Truth Image:'),
                        const SizedBox(height: 8),
                        _groundTruthImage ?? const Text('Ground truth not loaded.'),
                      ],
                    ),
            ],
          ),
        ),
      ),
    ),
  );
}

}

import 'package:flutter/material.dart';
import 'package:remote_sensing/Pages/CropImageClassificationPage.dart';
import 'package:remote_sensing/Pages/WelcomePage.dart';
import 'package:remote_sensing/Pages/SarImageColorisation.dart';
import 'package:remote_sensing/Pages/CropImageClassificationVIT.dart';
import 'package:remote_sensing/Pages/FloodDetection.dart';


// class FloodDetection extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Flood Detection'),
//       ),
//       body: Center(
//         child: Text(
//           'Flood Detection Page',
//           style: TextStyle(fontSize: 20),
//         ),
//       ),
//     );
//   }
// }
// Main Welcome Page
class mainScreen extends StatefulWidget {
  const mainScreen({Key? key}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<mainScreen> {
  bool _isDarkMode = false;

  // Define a list of feature buttons to reduce repetition
  final List<FeatureButton> _featureButtons = [
    FeatureButton(
      title: 'Crop Image Classification\nUsing VGG16',
      imagePath: 'assets/crop_image.jpg',
      onPressed: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CropImageClassificationPage()),
      ),
    ),
    FeatureButton(
      title: 'Crop Image Classification\nUsing VIT',
      imagePath: 'assets/crop_image2.jpg',
      onPressed: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => CropImageClassificationVIT()),
      ),
    ),
    FeatureButton(
      title: 'SAR Image Colorisation',
      imagePath: 'assets/sar_image.jpg',
      onPressed: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SarImageColorisation()),
      ),
    ),
    FeatureButton(
      title: 'Flood Detection',
      imagePath: 'assets/flood_image.jpg',
      onPressed: (context) => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => FloodDetection()),
      ),
    ),
  ];

  @override 
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: _isDarkMode ? ThemeData.dark() : ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Remote Sensing App'),
          actions: [
            IconButton(
              icon: Icon(
                _isDarkMode ? Icons.dark_mode : Icons.light_mode,
              ),
              onPressed: () {
                setState(() {
                  _isDarkMode = !_isDarkMode;
                });
              },
            ),
          ],
        ),
        backgroundColor: _isDarkMode ? Colors.black : Colors.grey[200],
        body: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _featureButtons
                  .map((button) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: button.build(context),
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

// Custom class to encapsulate feature button properties and creation
class FeatureButton {
  final String title;
  final String imagePath;
  final Function(BuildContext) onPressed;

  FeatureButton({
    required this.title,
    required this.imagePath,
    required this.onPressed,
  });

  Widget build(BuildContext context) {
    return Container(
      width: 300,
      height: 100,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage(imagePath),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton(
        onPressed: () => onPressed(context),
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          shadowColor: WidgetStateProperty.all(Colors.transparent),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        child: Center(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(
    title: 'Remote Sensing App',
    home:mainScreen(),
    debugShowCheckedModeBanner: false,
  ));
}
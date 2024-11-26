import 'package:flutter/material.dart';
import 'package:remote_sensing/Pages/WelcomePage.dart';
import 'package:remote_sensing/Pages/SarImageColorisation.dart';


// Placeholder pages for SAR Image Colorisation and Crop Image Classification
// class SARImageColorisationPage extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('SAR Image Colorisation'),
//       ),
//       body: Center(
//         child: Text(
//           'SAR Image Colorisation Page',
//           style: TextStyle(fontSize: 20),
//         ),
//       ),
//     );
//   }
// }


class FloodDetection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Flood Detection'),
      ),
      body: Center(
        child: Text(
          'Flood Detection Page',
          style: TextStyle(fontSize: 20),
        ),
      ),
    );
  }
}
// Main Welcome Page
class mainscreen extends StatelessWidget {
  const mainscreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home'),
      ),
      backgroundColor: Colors.grey[200],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Crop Image Classification Button with Background Image using BoxDecoration
            Container(
              width: 300,
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/crop_image.jpg'), // Background image for Crop Image Classification button
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12), // Optional: Adds rounded corners to the background
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WelcomePage(),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                      Colors.transparent), // Makes the button's color transparent
                  shadowColor: WidgetStateProperty.all(
                      Colors.transparent), // Removes button shadow
                  padding: WidgetStateProperty.all(
                      EdgeInsets.zero), // Removes padding to match the background
                ),
                child: Center(
                  child: Text(
                    'Crop Image Classification',
                    style: TextStyle(
                      color: Colors.white, // Set text color to white
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // SAR Image Colorisation Button with Background Image using BoxDecoration
            Container(
              width: 300,
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/sar_image.jpg'), // Background image for SAR Image Colorisation button
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12), // Optional: Adds rounded corners to the background
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SarImageColorisation(),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                      Colors.transparent), // Makes the button's color transparent
                  shadowColor: WidgetStateProperty.all(
                      Colors.transparent), // Removes button shadow
                  padding: WidgetStateProperty.all(
                      EdgeInsets.zero), // Removes padding to match the background
                ),
                child: Center(
                  child: Text(
                    'SAR Image Colorisation',
                    style: TextStyle(
                      color: Colors.white, // Set text color to white
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              width: 300,
              height: 100,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/flood_image.jpg'), // Background image for Crop Image Classification button
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(12), // Optional: Adds rounded corners to the background
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FloodDetection(),
                    ),
                  );
                },
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all(
                      Colors.transparent), // Makes the button's color transparent
                  shadowColor: WidgetStateProperty.all(
                      Colors.transparent), // Removes button shadow
                  padding: WidgetStateProperty.all(
                      EdgeInsets.zero), // Removes padding to match the background
                ),
                child: Center(
                  child: Text(
                    'Flood detection',
                    style: TextStyle(
                      color: Colors.white, // Set text color to white
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20)
          ],
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    title: 'Welcome App',
    home: mainscreen(),
    debugShowCheckedModeBanner: false
  ));
}

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;


void main() {
  runApp(const MaterialApp(home: HomeScreen()));
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image;
  final picker = ImagePicker();
  bool _isLoading = false;
  String _resultText = "No data yet.";

  // ⚠️ REPLACE THIS WITH YOUR COMPUTER'S LOCAL IP IF USING PHYSICAL DEVICE
  // Android Emulator uses 10.0.2.2 to access localhost
  final String apiUrl = "https://fbdc-27-107-13-254.ngrok-free.app/scan"; 

  Future<void> _getImage(ImageSource source) async {
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        _resultText = "Image captured. Ready to analyze.";
      });
    }
  }

  Future<void> _uploadImage() async {
    if (_image == null) return;

    setState(() {
      _isLoading = true;
      _resultText = "Uploading & Analyzing... (This may take 10-15s)";
    });

    try {
      // Create Multipart Request
      var request = http.MultipartRequest('POST', Uri.parse(apiUrl));
      
      // Add the file
      request.files.add(await http.MultipartFile.fromPath('file', _image!.path));

      // Send
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        // Pretty print the JSON
        JsonEncoder encoder = const JsonEncoder.withIndent('  ');
        String prettyPrint = encoder.convert(data['data']); // We only want the 'data' part

        setState(() {
          _resultText = prettyPrint;
        });
      } else {
        setState(() {
          _resultText = "Error: ${response.statusCode} - ${response.body}";
        });
      }
    } catch (e) {
      setState(() {
        _resultText = "Connection Error: $e";
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("ScriptFlow MVP")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // IMAGE PREVIEW
            if (_image != null)
              Image.file(_image!, height: 200, fit: BoxFit.cover)
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: Text("No Image Selected")),
              ),

            const SizedBox(height: 20),

            // BUTTONS
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _getImage(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Camera"),
                ),
                ElevatedButton.icon(
                  onPressed: () => _getImage(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text("Gallery"),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ANALYZE BUTTON
            if (_image != null)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _uploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("EXTRACT DATA"),
                ),
              ),

            const SizedBox(height: 20),

            // RESULT DISPLAY
            const Text(
              "Extracted Data:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _resultText,
                style: const TextStyle(
                  color: Colors.greenAccent, 
                  fontFamily: 'monospace', 
                  fontSize: 14
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
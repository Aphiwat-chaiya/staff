import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' show basename;
import 'package:async/async.dart';

class ImageUploadPage extends StatefulWidget {
  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  List<Map<String, dynamic>> _selectedImages = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final _descriptionController = TextEditingController();

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _chooseImagesFromGallery() async {
    if (_selectedImages.length >= 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("You can only upload up to 10 images.")),
      );
      return;
    }

    final pickedFiles = await _picker.pickMultiImage();
    if (pickedFiles != null) {
      for (var pickedFile in pickedFiles) {
        if (_selectedImages.length < 10) {
          setState(() {
            _selectedImages.add({
              'file': File(pickedFile.path),
              'description': '',
            });
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("You can only upload up to 10 images.")),
          );
          break;
        }
      }
    }
  }

  void _showDescriptionDialog(int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Description"),
          content:
              Text(_selectedImages[index]['description'] ?? "No description"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
    });

    for (var imageInfo in _selectedImages) {
      var image = imageInfo['file'] as File;
      var stream = http.ByteStream(DelegatingStream.typed(image.openRead()));
      var length = await image.length();
      var uri = Uri.parse("http://192.168.1.19:3000/upload_news");

      var request = http.MultipartRequest("POST", uri);
      request.fields['description'] = imageInfo['description'] ?? '';
      var multipartFile = http.MultipartFile('image', stream, length,
          filename: basename(image.path));
      request.files.add(multipartFile);

      var response = await request.send();

      if (response.statusCode != 200) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to upload image and description")),
        );
        return;
      }
    }

    setState(() {
      _isUploading = false;
      _selectedImages.clear();
      _descriptionController.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("All images and descriptions uploaded successfully!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Upload News Images"),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_selectedImages.isNotEmpty)
              Container(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        GestureDetector(
                          onTap: () => _showDescriptionDialog(index),
                          child: Container(
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            width: 150,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(color: Colors.black26, blurRadius: 5)
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.file(
                                _selectedImages[index]['file'],
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 5,
                          top: 5,
                          child: GestureDetector(
                            onTap: () => _removeImage(index),
                            child: CircleAvatar(
                              backgroundColor: Colors.red,
                              child: Icon(Icons.close, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              )
            else
              Container(
                height: 250,
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.teal, width: 2),
                ),
                child: Center(
                  child: Text("No images selected",
                      style: TextStyle(color: Colors.teal)),
                ),
              ),
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: "Description",
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onChanged: (text) {
                if (_selectedImages.isNotEmpty) {
                  setState(() {
                    _selectedImages.last['description'] = text;
                  });
                }
              },
            ),
            SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _chooseImagesFromGallery,
              icon: Icon(Icons.photo),
              label: Text("Choose from Gallery"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
            ),
            SizedBox(height: 20),
            _isUploading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _uploadImages,
                    style:
                        ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                    child: Text("Upload Images"),
                  ),
          ],
        ),
      ),
    );
  }
}

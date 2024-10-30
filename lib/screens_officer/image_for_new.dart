import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path; // เปลี่ยนเป็น path_package แทน

class ImageUploadPage extends StatefulWidget {
  final String officer_id;

  const ImageUploadPage({super.key, required this.officer_id});

  @override
  _ImageUploadPageState createState() => _ImageUploadPageState();
}

class _ImageUploadPageState extends State<ImageUploadPage> {
  File? _imageFile;
  String _description = '';
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _uploadImage(File imageFile) async {
    setState(() {
      _isLoading = true; // ตั้งค่าสถานะการโหลด
    });

    try {
      final uri = Uri.parse('http://192.168.1.30:3000/upload_image'); // เปลี่ยนเป็น URL เซิร์ฟเวอร์ของคุณ

      // สร้าง request
      var request = http.MultipartRequest('POST', uri);
      request.fields['description'] = _description; // ส่งคำบรรยาย
      
      // เพิ่มภาพใน request
      var stream = http.ByteStream(imageFile.openRead());
      var length = await imageFile.length();
      var multipartFile = http.MultipartFile('image', stream, length, filename: path.basename(imageFile.path)); // ใช้ path.basename แทน
      request.files.add(multipartFile);

      // ส่ง request
      var response = await request.send();

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Image uploaded successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error occurred during upload')),
      );
    } finally {
      setState(() {
        _isLoading = false; // ตั้งค่าสถานะการโหลดกลับ
      });
    }
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Image'),
        backgroundColor: Colors.blueAccent, // เปลี่ยนสีของ AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () {
              // แสดงข้อมูลเกี่ยวกับการใช้งาน
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Information'),
                  content: const Text('Upload an image for management.'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select an Image',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blueAccent, width: 2),
                  ),
                  child: _imageFile == null
                      ? const Icon(Icons.camera_alt, size: 50, color: Colors.blueAccent)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            _imageFile!,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Description',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            TextField(
              onChanged: (value) {
                setState(() {
                  _description = value;
                });
              },
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Enter a description...',
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: _isLoading ? null : () {
                  if (_imageFile != null) {
                    _uploadImage(_imageFile!);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please select an image')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent, // สีของปุ่ม
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator() // แสดง indicator ขณะโหลด
                    : const Text('Upload Image', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class RewardManagementPage extends StatefulWidget {
  const RewardManagementPage({super.key});

  @override
  _RewardManagementPageState createState() => _RewardManagementPageState();
}

class _RewardManagementPageState extends State<RewardManagementPage> {
  final _rewardNameController = TextEditingController();
  final _pointsRequiredController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  File? _image;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    setState(() {
      _image = pickedFile != null ? File(pickedFile.path) : null;
    });
  }

  Future<void> _showConfirmationDialog() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการเพิ่มของรางวัล'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ชื่อรางวัล: ${_rewardNameController.text}'),
              const SizedBox(height: 10),
              Text('จำนวนแต้มที่ใช้แลก: ${_pointsRequiredController.text}'),
              const SizedBox(height: 10),
              Text('จำนวนของรางวัล: ${_quantityController.text}'),
              const SizedBox(height: 10),
              Text('คำอธิบาย: ${_descriptionController.text}'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('ยกเลิก', style: TextStyle(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _submitReward();
              },
              child: const Text('ยืนยัน', style: TextStyle(color: Colors.green)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitReward() async {
    if (_rewardNameController.text.isEmpty ||
        _pointsRequiredController.text.isEmpty ||
        _quantityController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('กรุณากรอกข้อมูลให้ครบทุกช่องและเลือกรูปภาพ'),
        backgroundColor: Colors.red,
      ));
      return;
    }

    String rewardName = _rewardNameController.text;
    String pointsRequired = _pointsRequiredController.text;
    String quantity = _quantityController.text;
    String description = _descriptionController.text;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.1.19:3000/rewards'),
    );

    request.fields['reward_name'] = rewardName;
    request.fields['points_required'] = pointsRequired;
    request.fields['quantity'] = quantity;
    request.fields['description'] = description;

    if (_image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', _image!.path));
    }

    try {
      var response = await request.send();

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('ตั้งค่าของรางวัลสำเร็จ!'),
          backgroundColor: Colors.green,
        ));
        _rewardNameController.clear();
        _pointsRequiredController.clear();
        _quantityController.clear();
        _descriptionController.clear();
        setState(() {
          _image = null;
        });
      } else {
        final responseBody = await response.stream.bytesToString();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('ไม่สามารถเพิ่มของรางวัลได้: $responseBody'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('เกิดข้อผิดพลาด: $e'),
        backgroundColor: Colors.red,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('เพิ่มของรางวัล'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              GestureDetector(
                onTap: _pickImage,
                child: _image == null
                    ? Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey, width: 2),
                        ),
                        child: const Center(
                          child: Icon(Icons.image, size: 50, color: Colors.blueGrey),
                        ),
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          _image!,
                          height: 150,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _rewardNameController,
                decoration: const InputDecoration(
                  labelText: 'ชื่อรางวัล',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.card_giftcard),
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _pointsRequiredController,
                decoration: const InputDecoration(
                  labelText: 'จำนวนแต้มที่ใช้แลก',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.stars),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'จำนวนของรางวัล',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.production_quantity_limits),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'คำอธิบาย',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _showConfirmationDialog,
                icon: const Icon(Icons.check),
                label: const Text('Submit Reward'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[800],
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

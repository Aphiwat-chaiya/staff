import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class OfficerLogin extends StatefulWidget {
  const OfficerLogin({super.key});

  @override
  _OfficerLoginState createState() => _OfficerLoginState();
}

class _OfficerLoginState extends State<OfficerLogin> {
  final _officerIdController = TextEditingController();
  final _passwordController = TextEditingController();
  String errorMessage = '';
  bool _isLoading = false; // Track loading state

  Future<void> _loginOfficer() async {
    setState(() {
      _isLoading = true; // Show loading indicator
    });

    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.42:3000/officers/login'), // Update this URL
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'officer_id': _officerIdController.text,
          'password': _passwordController.text,
        }),
      );

      setState(() {
        _isLoading = false; // Hide loading indicator
      });

      if (response.statusCode == 200) {
        Navigator.pushNamed(
          context,
          '/officer_home',
          arguments: {'officer_id': _officerIdController.text}, // Pass officer_id to home screen
        );
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'รหัสหรือรหัสผ่านไม่ถูกต้อง';
        });
        _showSnackBar(errorMessage, Colors.red);
      } else {
        setState(() {
          errorMessage = 'เกิดข้อผิดพลาดในการล็อกอิน';
        });
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      setState(() {
        _isLoading = false; // Hide loading indicator
        errorMessage = 'การเชื่อมต่อผิดพลาด';
      });
      _showSnackBar(errorMessage, Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Login'),
        backgroundColor: Colors.blue[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // เพิ่ม Icon แทนรูปภาพ
            Icon(
              Icons.security, // เลือกไอคอนที่เหมาะสม
              size: 80,
              color: Colors.blue[800],
            ),
            const SizedBox(height: 30),
            TextField(
              controller: _officerIdController,
              decoration: const InputDecoration(
                labelText: 'ID เจ้าหน้าที่ฯ',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: 'รหัสผ่าน',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loginOfficer,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
                backgroundColor: Colors.blue[700],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isLoading 
                ? const CircularProgressIndicator() // Show loading indicator
                : const Text(
                    'Login',
                    style: TextStyle(fontSize: 18),
                  ),
            ),
            const SizedBox(height: 20),
            if (errorMessage.isNotEmpty)
              Text(
                errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
          ],
        ),
      ),
    );
  }
}

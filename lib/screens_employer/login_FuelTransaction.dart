import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginScreen createState() => _LoginScreen();
}

class _LoginScreen extends State<Login> {
  final _idController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String errorMessage = '';

  Future<void> _login() async {
    try {
      var response = await http.post(
        Uri.parse('http://10.0.2.2:3000/staff/login'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'staff_id': _idController.text,
          'password': _phoneNumberController.text,
        }),
      );

      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        Navigator.pushNamed(
          context,
          '/sales',
          arguments: {'staff_id': _idController.text},
        );
      } else if (response.statusCode == 404) {
        setState(() {
          errorMessage = 'ไอดีพนักงานหรือรหัสไม่ถูกต้อง';
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
        errorMessage = 'การเชื่อมต่อผิดพลาด';
      });
      print('Error: $e');
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
        title: Row(
          children: [
            Icon(Icons.login),
            const SizedBox(width: 10),
            const Text('เข้าสู่ระบบ'),
          ],
        ),
        backgroundColor: Colors.green[800],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 50),
              Icon(
                Icons.account_circle,         
                size: 150, // ไอคอนขนาดใหญ่ตรงกลางหน้าจอ
                color: Colors.green[700],
              ),
              const SizedBox(height: 30),
              TextField(
                controller: _idController,
                decoration: InputDecoration(
                  labelText: 'ชื่อผู้ใช้',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  filled: true,
                  fillColor: Colors.green[50],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _phoneNumberController,
                decoration: InputDecoration(
                  labelText: 'รหัสผ่าน',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.lock),
                  filled: true,
                  fillColor: Colors.green[50],
                ),
                obscureText: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _login,
                icon: const Icon(Icons.login),
                label: const Text('เข้าสู่ระบบ'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  padding:
                      const EdgeInsets.symmetric(vertical: 15, horizontal: 100),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                icon: const Icon(Icons.person_add),
                label: const Text('ลงชื่อเข้าใช้ในฐานะเจ้าหน้าที่'),
                onPressed: () {
                  Navigator.pushNamed(context, '/login_officer');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

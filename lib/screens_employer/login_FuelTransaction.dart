import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  _LoginScreen createState() => _LoginScreen();
}

class _LoginScreen extends State<Login> {
  final _idController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  String errorMessage = '';
  bool _isPasswordVisible = false; // ตัวแปรเพื่อเก็บสถานะการแสดงรหัสผ่าน
  bool _rememberMe = false; // ตัวแปรเพื่อเก็บสถานะการจดจำรหัสผ่าน

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials(); // โหลดข้อมูลที่บันทึกไว้เมื่อเริ่มต้น
  }

  Future<void> _loadSavedCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString('staff_id');
    String? savedPassword = prefs.getString('password');

    if (savedId != null) {
      _idController.text = savedId;
    }
    if (savedPassword != null) {
      _phoneNumberController.text = savedPassword;
      _rememberMe = true; // ถ้ารหัสผ่านมีการบันทึกไว้ ให้ตั้งค่าสถานะ
    }
  }

  Future<void> _login() async {
    try {
      var response = await http.post(
        Uri.parse('http://192.168.1.30:3000/staff/login'),
        headers: {
          "Content-Type": "application/json",
          "Accept": "application/json",
        },
        body: jsonEncode({
          'staff_id': _idController.text,
          'password': _phoneNumberController.text,
        }),
      );

      if (response.statusCode == 200) {
        // ถ้าผลลัพธ์ถูกต้อง บันทึกรหัสผ่านถ้าเลือกจดจำ
        if (_rememberMe) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('staff_id', _idController.text);
          await prefs.setString('password', _phoneNumberController.text);
        }

        Navigator.pushNamed(
          context,
          '/sales',
          arguments: {'staff_id': _idController.text},
        );
      } else {
        setState(() {
          errorMessage = response.statusCode == 404
              ? 'ไอดีพนักงานหรือรหัสไม่ถูกต้อง'
              : 'เกิดข้อผิดพลาดในการล็อกอิน';
        });
        _showSnackBar(errorMessage, Colors.red);
      }
    } catch (e) {
      setState(() {
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
        title: const Text('เข้าสู่ระบบ (พนักงานปั๊มน้ำมัน)'),
        backgroundColor: Colors.green[900],
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.account_circle,
                  size: 120,
                  color: Colors.green[700],
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _idController,
                  decoration: InputDecoration(
                    labelText: 'ชื่อผู้ใช้',
                    labelStyle: TextStyle(color: Colors.green[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[500]!),
                    ),
                    prefixIcon: Icon(Icons.person, color: Colors.green[700]),
                    filled: true,
                    fillColor: Colors.green[50],
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _phoneNumberController,
                  obscureText: !_isPasswordVisible, // แสดงหรือซ่อนรหัสผ่าน
                  decoration: InputDecoration(
                    labelText: 'รหัสผ่าน',
                    labelStyle: TextStyle(color: Colors.green[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.green[500]!),
                    ),
                    prefixIcon: Icon(Icons.lock, color: Colors.green[700]),
                    filled: true,
                    fillColor: Colors.green[50],
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: Colors.green[700],
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible; // สลับสถานะ
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value ?? false; // ปรับปรุงสถานะ
                        });
                      },
                    ),
                    const Text('จดจำรหัสผ่าน'),
                  ],
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: _login,
                  icon: const Icon(Icons.login),
                  label: const Text('เข้าสู่ระบบ'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    padding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 100,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
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
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

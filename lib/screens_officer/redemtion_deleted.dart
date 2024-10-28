import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // เพิ่มการนำเข้า

class Search_deleteRedemptionsScreen extends StatefulWidget {
  const Search_deleteRedemptionsScreen({super.key});

  @override
  SearchRedemptionsScreenState createState() => SearchRedemptionsScreenState();
}

class SearchRedemptionsScreenState extends State<Search_deleteRedemptionsScreen> {
  List<dynamic> redemptions = [];
  bool isLoading = true;
  String selectedStatus = 'all'; // เลือกสถานะเริ่มต้นเป็น all (แสดงทั้งหมด)
  String searchQuery = ''; // สำหรับค้นหาชื่อรางวัล

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('th_TH', null).then((_) {  // เรียกใช้งาน locale สำหรับภาษาไทย
      fetchRedemptions(); // ดึงข้อมูลเมื่อเริ่มต้น
    });
  }

  Future<void> fetchRedemptions() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.42:3000/redemptions/search_redemptions'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': selectedStatus != 'all' ? selectedStatus : null,
          'reward_name': searchQuery.isNotEmpty ? searchQuery : null,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          redemptions = jsonDecode(response.body)['redemptions'];
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load redemptions');
      }
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการดึงข้อมูล')),
      );
    }
  }

  void onSearch() {
    setState(() {
      isLoading = true;
    });
    fetchRedemptions(); // ค้นหาทุกครั้งที่มีการเปลี่ยนแปลงสถานะหรือชื่อรางวัล
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหารายการแลกสินค้า'),
        backgroundColor: Colors.blue[800], // เพิ่มสีแถบด้านบน
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'ค้นหาด้วยชื่อรางวัล',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.search), // เพิ่มไอคอนค้นหา
              ),
              onChanged: (value) {
                searchQuery = value; // อัปเดตค่าการค้นหา
              },
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(
                labelText: 'เลือกสถานะ', // เพิ่ม label ให้กับ dropdown
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  selectedStatus = value!;
                });
                onSearch(); // ค้นหาใหม่เมื่อเปลี่ยนสถานะ
              },
              items: const [
                DropdownMenuItem(value: 'all', child: Text('ทั้งหมด')),
                DropdownMenuItem(value: 'pending', child: Text('รอดำเนินการ')),
                DropdownMenuItem(value: 'completed', child: Text('เสร็จสมบูรณ์')),
              ],
            ),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              onPressed: onSearch,
              icon: const Icon(Icons.search), // เพิ่มไอคอนค้นหาในปุ่ม
              label: const Text('ค้นหา'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[800],
                minimumSize: const Size(double.infinity, 50), // ขนาดปุ่มเต็มความกว้าง
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // ขอบปุ่มมน
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator()) // แสดงตัวโหลดข้อมูล
                  : ListView.builder(
                      itemCount: redemptions.length,
                      itemBuilder: (context, index) {
                        final redemption = redemptions[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10), // ขอบการ์ดมน
                          ),
                          elevation: 4, // เพิ่มเงาให้การ์ด
                          child: ListTile(
                            leading: const Icon(Icons.card_giftcard, color: Colors.blue), // เพิ่มไอคอนแสดงรายการ
                            title: Text('รหัสแลกสินค้า: ${redemption['redemption_id']}'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('รางวัล: ${redemption['reward_name']}'),
                                Text('รหัสลูกค้า: ${redemption['customer_id']}'),
                                // แสดงวันที่แลกในรูปแบบไทย
                                Text('วันที่แลก: ${formatDate(redemption['redemption_date'])}'),
                                Text('แต้มที่ใช้: ${redemption['points_used']}'),
                                Text('สถานะ: ${redemption['status']}'),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red), // เพิ่มไอคอนลบ
                              onPressed: () {
                                // ฟังก์ชันแสดง popup ยืนยันก่อนลบ
                                showDeleteConfirmationDialog(redemption['redemption_id']);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String formatDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('d MMMM y', 'th_TH').format(parsedDate); // แสดงวันที่ในรูปแบบไทย
  }

  // ฟังก์ชันแสดง popup ยืนยันก่อนลบ
  void showDeleteConfirmationDialog(String redemptionId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ยืนยันการลบ'),
          content: Text('คุณแน่ใจหรือไม่ว่าต้องการลบรายการ $redemptionId?'),
          actions: <Widget>[
            TextButton(
              child: const Text('ยกเลิก'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด popup โดยไม่ลบ
              },
            ),
            TextButton(
              child: const Text('ลบ'),
              onPressed: () {
                Navigator.of(context).pop(); // ปิด popup ก่อนลบ
                deleteRedemption(redemptionId); // เรียกฟังก์ชันลบข้อมูล
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> deleteRedemption(String redemptionId) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.42:3000/redemptions/delete_redemption'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'redemption_id': redemptionId}),
      );

      if (response.statusCode == 200) {
        setState(() {
          redemptions.removeWhere((item) => item['redemption_id'] == redemptionId);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('ลบรายการ $redemptionId สำเร็จ!')),
        );
      } else {
        throw Exception('Failed to delete redemption');
      }
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('เกิดข้อผิดพลาดในการลบรายการ')),
      );
    }
  }
}

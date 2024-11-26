import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // สำหรับการจัดรูปแบบวันที่

class TransactionHistoryScreen extends StatefulWidget {
  final String staffId;

  const TransactionHistoryScreen({super.key, required this.staffId});

  @override
  TransactionHistoryScreenState createState() =>
      TransactionHistoryScreenState();
}

class TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> transactions = [];
  String baseUrl = 'http://192.168.1.19:3000'; // ที่อยู่ API ของคุณ

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      // เรียกใช้ API ของคุณโดยใช้ staffId
      final response = await http.get(
          Uri.parse('$baseUrl/staff_record/transactions/${widget.staffId}'));

      if (response.statusCode == 200) {
        setState(() {
          transactions = json.decode(response.body);
          // เรียงลำดับข้อมูลจากล่าสุดไปเก่า
          transactions.sort((a, b) => DateTime.parse(b['transaction_date'])
              .compareTo(DateTime.parse(a['transaction_date'])));
        });
      } else {
        _showSnackBar(
            'ไม่สามารถดึงข้อมูลประวัติการทำรายการได้: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการดึงข้อมูล: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(String dateString) {
    // แปลงเป็น DateTime
    DateTime dateTime = DateTime.parse(dateString);

    // ปรับเวลาเป็นเวลาไทย (UTC+7)
    dateTime = dateTime.add(Duration(hours: 7));

    // สร้างวันที่ในรูปแบบที่ต้องการ
    final monthNames = [
      'ม.ค.',
      'ก.พ.',
      'มี.ค.',
      'เม.ย.',
      'พ.ค.',
      'มิ.ย.',
      'ก.ค.',
      'ส.ค.',
      'ก.ย.',
      'ต.ค.',
      'พ.ย.',
      'ธ.ค.'
    ];

    String day = DateFormat('dd').format(dateTime);
    String month = monthNames[dateTime.month - 1];
    String year = (dateTime.year + 543).toString(); // แปลงปีเป็นพุทธศักราช

    return '$day $month $year เวลา ${DateFormat('HH:mm น.').format(dateTime)}'; // จัดรูปแบบวันที่ตามที่ต้องการ
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติการทำรายการ'),
        backgroundColor: Colors.deepOrange,
      ),
      body: transactions.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: fetchTransactions, // ฟังก์ชันดึงข้อมูลใหม่
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  return Card(
                    margin: const EdgeInsets.all(10.0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${transaction['customer_name']}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                // ย้ายวันที่ไปไว้หลังรหัสธุรกรรม
                                // _formatDate(transaction['transaction_date']),
                                '', // ลบออกชั่วคราว
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8.0),
                          Row(
                            children: [
                              Icon(Icons.local_gas_station,
                                  color: Colors.deepOrange),
                              const SizedBox(width: 5),
                              Text(
                                'ประเภทน้ำมัน: ${transaction['fuel_type_name']}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.attach_money, color: Colors.green),
                              const SizedBox(width: 5),
                              Text(
                                'จำนวนเงิน: ${transaction['points_earned']} บาท',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.confirmation_number,
                                  color: Colors.blue),
                              const SizedBox(width: 5),
                              Text(
                                'รหัสธุรกรรม: ${transaction['transaction_id']}',
                                style: TextStyle(
                                    fontSize: 14, color: Colors.black87),
                              ),
                            ],
                          ),
                          // เพิ่ม Text สำหรับวันที่ด้านล่างรหัสธุรกรรม
                          const SizedBox(height: 5),
                          Text(
                            _formatDate(transaction['transaction_date']),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart'; // นำเข้าสำหรับการจัดรูปแบบวันที่

class TransactionHistoryScreen extends StatefulWidget {
  final String staffId;

  const TransactionHistoryScreen({super.key, required this.staffId});

  @override
  TransactionHistoryScreenState createState() => TransactionHistoryScreenState();
}

class TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<dynamic> transactions = [];
  String baseUrl = 'http://10.0.2.2:3000';

  @override
  void initState() {
    super.initState();
    fetchTransactions();
  }

  Future<void> fetchTransactions() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/transactions?staff_id=${widget.staffId}'));

      if (response.statusCode == 200) {
        setState(() {
          transactions = json.decode(response.body);
        });
      } else {
        _showSnackBar('ไม่สามารถดึงข้อมูลประวัติการทำรายการได้: ${response.reasonPhrase}');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาดในการดึงข้อมูล: $e');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  String _formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy เวลา HH:mm น.').format(dateTime); // จัดรูปแบบวันที่ตามที่ต้องการ
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
                    margin: const EdgeInsets.all(8.0),
                    elevation: 4, // เพิ่มการยกสำหรับเงา
                    child: ListTile(
                      title: Text('ประเภทน้ำมัน: ${transaction['fuel_type_name']}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('วันที่-เวลา ${_formatDate(transaction['transaction_date'])}'),
                          Text('จำนวนเงิน: ${transaction['points_earned']} บาท'),
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

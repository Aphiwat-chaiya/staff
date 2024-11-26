import 'package:flutter/material.dart';
import 'package:flutter_application_12/screens_officer/search_transaction.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart'; // เพิ่มการนำเข้า

class OfficerHomeScreen extends StatefulWidget {
  final String officer_id;

  const OfficerHomeScreen({super.key, required this.officer_id});

  @override
  OfficerHomeScreenState createState() => OfficerHomeScreenState();
}

class OfficerHomeScreenState extends State<OfficerHomeScreen> {
  late Future<List<dynamic>> _latestTransactions;
  late Future<List<dynamic>> _fuelTypes; // เพิ่มตัวแปรสำหรับประเภทเชื้อเพลิง

  @override
  void initState() {
    super.initState();
    _latestTransactions = Future.value(
        []); // กำหนดค่าเริ่มต้นให้เป็น List ว่าง เพื่อหลีกเลี่ยง LateInitializationError
    initializeDateFormatting('th_TH', null).then((_) {
      setState(() {
        _latestTransactions =
            _fetchTransactions(); // ดึงข้อมูลหลังจาก locale พร้อมใช้งาน
        _fuelTypes = _fetchFuelTypes(); // เรียกใช้ API สำหรับประเภทเชื้อเพลิง
      });
    });
  }

  Future<List<dynamic>> _fetchTransactions() async {
    final response =
        await http.get(Uri.parse('http://192.168.1.19:3000/transactions_lastest'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  Future<List<dynamic>> _fetchFuelTypes() async {
    // ฟังก์ชันใหม่สำหรับดึงประเภทเชื้อเพลิง
    final response =
        await http.get(Uri.parse('http://192.168.1.19:3000/fuel_types'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load fuel types');
    }
  }

  String formatTransactionDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('d MMMM y', 'th_TH')
        .format(parsedDate); // แสดงวันที่ในรูปแบบไทย
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หน้ารายการ'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              // นำทางไปยังหน้า SearchTransactionScreen พร้อมกับส่ง officer_id
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      SearchTransactionScreen(officer_id: 'officer_id'),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.teal,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.description, color: Colors.teal),
              title: const Text('การทำธุรกรรม'),
              onTap: () {
                setState(() {
                  _latestTransactions =
                      _fetchTransactions(); // รีเฟรชข้อมูลการทำธุรกรรม
                });
                Navigator.pop(context); // ปิด Drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.newspaper, color: Colors.teal),
              title: const Text('ข่าวสาร'),
              onTap: () {
                Navigator.pushNamed(context, '/news',
                    arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.teal),
              title: const Text('ตั่งค่าของรางวัล'),
              onTap: () {
                Navigator.pushNamed(context, '/search_edit_reward',
                    arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.teal),
              title: const Text('Deleted Redemption'),
              onTap: () {
                Navigator.pushNamed(context, '/redemption_deleted',
                    arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.teal),
              title: const Text('ปันผลประจำปี'),
              onTap: () {
                Navigator.pushNamed(context, '/history_of_year',
                    arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.teal),
              title: const Text('FuelType Stats'),
              onTap: () {
                Navigator.pushNamed(context, '/FuelTypeStats',
                    arguments: widget.officer_id);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout'),
              onTap: _logout,
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Text(
                'การทำรายการล่าสุด',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              FutureBuilder<List<dynamic>>(
                future: _latestTransactions,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No transactions found.'));
                  } else {
                    final transactions = snapshot.data!;
                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4.0,
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.monetization_on,
                                color: Colors.green),
                            title: Text(
                              'Transaction ID: ${transaction['transaction_id']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                            subtitle: Text(
                              'เลขสมาชิก: ${transaction['customer_id']}\n'
                              'ชื่อ: ${transaction['customer_first_name']} ${transaction['customer_last_name']}\n'
                              'ประเภทเชื้อเพลิง: ${transaction['fuel_type_name']}\n'
                              'หมายเลขพนักงานทำรายการ: ${transaction['staff_id']}\n'
                              'จำนวนเงิน  ${transaction['points_earned']} บาท\n'
                              'วันที่: ${formatTransactionDate(transaction['transaction_date'])}\n'
                              'หมายเลขพนักงาน: ${transaction['staff_id']}\n',
                              style: const TextStyle(color: Colors.black54),
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

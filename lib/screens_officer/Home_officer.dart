import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; 
import 'package:intl/date_symbol_data_local.dart'; // เพิ่มการนำเข้า

class OfficerHomeScreen extends StatefulWidget {
  final String officer_id;

  const OfficerHomeScreen({super.key, required this.officer_id});

  @override
  _OfficerHomeScreenState createState() => _OfficerHomeScreenState();
}

class _OfficerHomeScreenState extends State<OfficerHomeScreen> {
  late Future<List<dynamic>> _latestTransactions;

  @override
  void initState() {
    super.initState();
    _latestTransactions = Future.value([]); // กำหนดค่าเริ่มต้นให้เป็น List ว่าง เพื่อหลีกเลี่ยง LateInitializationError
    initializeDateFormatting('th_TH', null).then((_) {
      setState(() {
        _latestTransactions = _fetchTransactions(); // ดึงข้อมูลหลังจาก locale พร้อมใช้งาน
      });
    });
  }

  Future<List<dynamic>> _fetchTransactions() async {
    final response = await http.get(Uri.parse('http://10.0.2.2:3000/transactions'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load transactions');
    }
  }

  String formatTransactionDate(String date) {
    DateTime parsedDate = DateTime.parse(date);
    return DateFormat('d MMMM y', 'th_TH').format(parsedDate); // แสดงวันที่ในรูปแบบไทย
  }

  void _logout() {
    Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Home'),
        backgroundColor: Colors.teal,
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
              leading: const Icon(Icons.search, color: Colors.teal),
              title: const Text('Transactions'),
              onTap: () {
                Navigator.pushNamed(context, '/search_transaction', arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.redeem, color: Colors.teal),
              title: const Text('Rewards'),
              onTap: () {
                Navigator.pushNamed(context, '/redeem_items', arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.teal),
              title: const Text('Edit Reward'),
              onTap: () {
                Navigator.pushNamed(context, '/search_edit_reward', arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.teal),
              title: const Text('Deleted Redemption'),
              onTap: () {
                Navigator.pushNamed(context, '/redemption_deleted', arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart, color: Colors.teal),
              title: const Text('Yearly History'),
              onTap: () {
                Navigator.pushNamed(context, '/history_of_year', arguments: widget.officer_id);
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.teal),
              title: const Text('FuelType Stats'),
              onTap: () {
                Navigator.pushNamed(context, '/FuelTypeStats', arguments: widget.officer_id);
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
                'Latest Transactions:',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.teal, fontWeight: FontWeight.bold),
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
                            leading: const Icon(Icons.monetization_on, color: Colors.green),
                            title: Text(
                              'Transaction ID: ${transaction['transaction_id']}',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                            ),
                            subtitle: Text(
                              'Customer ID: ${transaction['customer_id']}\n'
                              'Fuel Type ID: ${transaction['fuel_type_id']}\n'
                              'Amount: ${transaction['points_earned']}\n'
                              'Date: ${formatTransactionDate(transaction['transaction_date'])}', // แปลงวันที่เป็นรูปแบบไทย
                              style: const TextStyle(color: Colors.black54),
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, color: Colors.teal),
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

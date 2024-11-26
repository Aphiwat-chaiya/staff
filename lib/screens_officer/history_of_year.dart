import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class AnnualProcessingScreen extends StatefulWidget {
  const AnnualProcessingScreen({super.key});

  @override
  _AnnualProcessingScreenState createState() => _AnnualProcessingScreenState();
}

class _AnnualProcessingScreenState extends State<AnnualProcessingScreen> {
  String? selectedYear;
  String? selectedCustomerId;

  List<String> years = []; // รายการปีสำหรับ Dropdown
  List<Map<String, dynamic>> customers = []; // รายชื่อลูกค้า

  late Future<List<dynamic>> _annualDividends;

  @override
  void initState() {
    super.initState();
    _fetchYears(); // ดึงรายการปี
    _fetchCustomers(); // ดึงรายชื่อลูกค้า
    _annualDividends = _fetchAnnualDividends(); // ดึงข้อมูลปันผลครั้งแรก
  }

  Future<void> _fetchYears() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.19:3000/annual_dividends/years'),
    );

    if (response.statusCode == 200) {
      setState(() {
        years = List<String>.from(jsonDecode(response.body));
      });
    } else {
      throw Exception('Failed to load years');
    }
  }

  Future<void> _fetchCustomers() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.19:3000/customers'),
    );

    if (response.statusCode == 200) {
      setState(() {
        customers = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      throw Exception('Failed to load customers');
    }
  }

  Future<List<dynamic>> _fetchAnnualDividends() async {
    String url = 'http://192.168.1.19:3000/annual_dividends';

    Map<String, String> queryParams = {};
    if (selectedYear != null && selectedYear!.isNotEmpty) {
      queryParams['year'] = selectedYear!;
    }
    if (selectedCustomerId != null && selectedCustomerId!.isNotEmpty) {
      queryParams['customer_id'] = selectedCustomerId!;
    }

    if (queryParams.isNotEmpty) {
      url += '?${Uri(queryParameters: queryParams).query}';
    }

    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load annual dividends');
    }
  }

  void _refreshData() {
    setState(() {
      _annualDividends = _fetchAnnualDividends();
    });
  }

  String _getCustomerName(String customerId) {
    final customer = customers.firstWhere(
      (c) => c['customer_id'].toString() == customerId,
      orElse: () => {'first_name': 'ไม่ทราบชื่อ', 'last_name': ''},
    );
    return '${customer['first_name']} ${customer['last_name']}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ประมวลผลรายปี'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Dropdown สำหรับเลือกปี
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blueAccent),
                const SizedBox(width: 10),
                const Text('เลือกปี:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedYear,
                    hint: const Text('ทั้งหมด'),
                    isExpanded: true,
                    items: years.map((year) {
                      return DropdownMenuItem<String>(
                        value: year,
                        child: Text(year),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedYear = value;
                      });
                      _refreshData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Dropdown สำหรับเลือกลูกค้า
            Row(
              children: [
                const Icon(Icons.person, color: Colors.blueAccent),
                const SizedBox(width: 10),
                const Text('เลือกลูกค้า:', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButton<String>(
                    value: selectedCustomerId,
                    hint: const Text('ทั้งหมด'),
                    isExpanded: true,
                    items: [
                      DropdownMenuItem<String>(
                        value: '',
                        child: Text('ทั้งหมด'),
                      ),
                      ...customers.map((customer) {
                        return DropdownMenuItem<String>(
                          value: customer['customer_id'].toString(),
                          child: Text(
                              '${customer['customer_id']}: ${customer['first_name']} ${customer['last_name']}'),
                        );
                      }).toList(),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedCustomerId = value!.isEmpty ? null : value;
                      });
                      _refreshData();
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: _annualDividends,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('ไม่พบข้อมูลปันผลรายปี.'));
                  } else {
                    final annualDividends = snapshot.data!;
                    return ListView.builder(
                      itemCount: annualDividends.length,
                      itemBuilder: (context, index) {
                        final dividend = annualDividends[index];
                        final customerName = _getCustomerName(
                            dividend['customer_id'].toString());
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            leading: const Icon(Icons.monetization_on,
                                color: Colors.green),
                            title: Text(
                              'เลขสมาชิก  ${dividend['customer_id']} | ปี: ${dividend['year']}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'ชื่อ: $customerName\n'
                              'คะแนนที่ใช้: ${dividend['points_used']}\n'
                              'ปันผลที่ได้: ${dividend['dividend_amount']} บาท\n',
                            ),
                          ),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

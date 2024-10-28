import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_12/screens_employer/get_rewarded.dart';
import 'package:flutter_application_12/screens_employer/history_page.dart';
import 'package:flutter_application_12/screens_employer/login_FuelTransaction.dart';
import 'package:flutter_application_12/screens_employer/slip.dart';
import 'package:auto_size_text/auto_size_text.dart';

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class FuelTransactionScreen extends StatefulWidget {
  final String staff_id;

  const FuelTransactionScreen({super.key, required this.staff_id});

  @override
  _FuelTransactionScreenState createState() => _FuelTransactionScreenState();
}

class _FuelTransactionScreenState extends State<FuelTransactionScreen> {
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  String selectedFuelType = '';
  String baseUrl = 'http://10.0.2.2:3000';
  final BlueThermalPrinter bluetooth = BlueThermalPrinter.instance;
  List<BluetoothDevice> _devices = [];
  BluetoothDevice? _selectedDevice;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;

  @override
  void initState() {
    super.initState();
    requestBluetoothPermissions();
    getPairedDevices();
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  Future<void> requestBluetoothPermissions() async {
    if (await Permission.bluetoothConnect.request().isGranted &&
        await Permission.bluetoothScan.request().isGranted &&
        await Permission.location.request().isGranted) {
      print('All permissions granted');
    } else {
      print('Permissions not granted');
    }
  }

  Future<void> getPairedDevices() async {
    try {
      _devices = await bluetooth.getBondedDevices();
      setState(() {});
    } catch (e) {
      print("Error fetching paired devices: $e");
    }
  }

  Future<void> connectToBluetooth() async {
    if (_selectedDevice == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณาเลือกอุปกรณ์บลูทูธ.')),
      );
      return;
    }

    bool isConnected = await bluetooth.isConnected ?? false;
    if (isConnected) {
      print("Already connected.");
      _showDialog('ผลการเชื่อมต่อ', 'เชื่อมต่อสำเร็จ');
      return;
    }

    try {
      await bluetooth.connect(_selectedDevice!);
      _showDialog('ผลการเชื่อมต่อ', 'เชื่อมต่อสำเร็จ');
    } catch (e) {
      print("Failed to connect to Bluetooth device: $e");
      _showDialog('ผลการเชื่อมต่อ', 'เชื่อมต่อล้มเหลว');
    }
  }

  void resetFields() {
    phoneController.clear(); // รีเซ็ตค่าใน TextField ของหมายเลขโทรศัพท์
    priceController.clear(); // รีเซ็ตค่าใน TextField ของราคา
    selectedFuelType = ''; // รีเซ็ตประเภทน้ำมันที่เลือก
    setState(() {}); // อัปเดต UI
  }

  Future<void> scanQRCode(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QRView(
          key: qrKey,
          onQRViewCreated: _onQRViewCreated,
        ),
      ),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        result = scanData;
        controller.pauseCamera();
        if (result != null) {
          String scannedPhoneNumber = result!.code ?? '';
          phoneController.text = scannedPhoneNumber;
        }
        Navigator.pop(context); // ปิดหน้าสแกน QR
      });
    });
  }

  Future<void> submitTransaction() async {
    final phone = phoneController.text.replaceAll('-', '').trim();
    final price = double.tryParse(priceController.text);
    print('staff_id: ${widget.staff_id}');

    if (price == null || price <= 0) {
      _showSnackBar('กรุณากรอกราคาที่ถูกต้อง');
      return;
    }

    try {
      final transactionResponse = await http.post(
        Uri.parse('$baseUrl/transactions'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'phone_number': phone,
          'fuel_type': selectedFuelType,
          'points_earned': price,
          'staff_id': widget.staff_id,
        }),
      );

      if (transactionResponse.statusCode == 200) {
        final Map<String, dynamic> transaction =
            json.decode(transactionResponse.body);
        final String? transactionId = transaction['transactionId']?.toString();

        if (transactionId == null || transactionId.isEmpty) {
          _showSnackBar('ไม่สามารถรับหมายเลขรายการจากเซิร์ฟเวอร์ได้.');
          return;
        }

        final pointsEarned = transaction['pointsEarned'] ?? 0;

        final memberResponse =
            await http.get(Uri.parse('$baseUrl/customers/$phone'));
        final staffResponse =
            await http.get(Uri.parse('$baseUrl/staff/${widget.staff_id}'));

        if (memberResponse.statusCode == 200 &&
            staffResponse.statusCode == 200) {
          final memberData = json.decode(memberResponse.body);
          final staffData = json.decode(staffResponse.body);

          const dividendPercentage = 0.01;
          final dividend = price * dividendPercentage;

          // รับค่าจากหน้า ReceiptScreen
          final resetNeeded = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ReceiptScreen(
                transactionId: transactionId,
                phoneNumber: phone,
                fuelType: selectedFuelType,
                price: price,
                pointsEarned: pointsEarned,
                dividend: dividend,
                staffFirstName: staffData['first_name'],
                staffLastName: staffData['last_name'],
                memberId: memberData['customer_id'].toString(),
                memberFirstName: memberData['first_name'],
                memberLastName: memberData['last_name'],
                staffId: widget.staff_id,
                selectedDevice: _selectedDevice,
              ),
            ),
          );

          if (resetNeeded == true) {
            resetFields();
          }
        } else {
          _showSnackBar('ไม่สามารถดึงข้อมูลสมาชิกหรือพนักงานได้.');
        }
      } else {
        _showSnackBar('บันทึกการขายล้มเหลว!');
      }
    } catch (e) {
      _showSnackBar('เกิดข้อผิดพลาด. กรุณาลองใหม่อีกครั้ง.');
    }
  }

  Future<void> confirmTransaction() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(15), // มุมโค้งของกล่อง AlertDialog
          ),
          title: const Text(
            'ตรวจสอบข้อมูลก่อนบันทึก',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueAccent, // เปลี่ยนสีหัวข้อ
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 5), // เพิ่มช่องว่างระหว่างข้อความ
                child: Text(
                  'เบอร์โทรลูกค้าสหกรณ์ : ${phoneController.text}',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  'ประเภทน้ำมัน : $selectedFuelType',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Text(
                  'ราคา : ${priceController.text} บาท',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text(
                'ยกเลิก',
                style: TextStyle(
                    color: Color.fromARGB(
                        255, 31, 152, 53)), // เปลี่ยนสีปุ่มยกเลิก
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green, // เปลี่ยนสีปุ่มยืนยัน
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(10), // มุมโค้งของปุ่มยืนยัน
                ),
              ),
              child: const Text(
                'ยืนยัน',
                style: TextStyle(color: Colors.white), // สีข้อความปุ่มยืนยัน
              ),
              onPressed: () {
                Navigator.of(context).pop();
                submitTransaction(); // เรียกใช้ฟังก์ชันบันทึกข้อมูลเมื่อยืนยัน
              },
            ),
          ],
        );
      },
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showDialog(String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildFuelButton(String fuelType, IconData icon) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () {
          setState(() {
            selectedFuelType = fuelType;
          });
        },
        child: Container(
          padding: const EdgeInsets.all(10.0),
          decoration: BoxDecoration(
            color: selectedFuelType == fuelType
                ? const Color.fromARGB(255, 44, 144, 49)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selectedFuelType == fuelType
                  ? const Color.fromARGB(255, 43, 161, 49)
                  : Colors.grey,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 30,
                  color: selectedFuelType == fuelType
                      ? Colors.white
                      : Colors.blue),
              const SizedBox(height: 10),
              AutoSizeText(
                fuelType,
                style: TextStyle(
                  color:
                      selectedFuelType == fuelType ? Colors.white : Colors.blue,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2, // ข้อความจะแสดงได้ไม่เกิน 2 บรรทัด
                minFontSize: 10, // ขนาดฟอนต์ต่ำสุดที่จะปรับลดได้
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _logout() {
    // คุณอาจต้องทำความสะอาดข้อมูลที่เก็บไว้ เช่น Token หรือสถานะผู้ใช้ที่เข้าสู่ระบบ
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
          builder: (context) => Login()), // เปลี่ยนเป็นหน้าจอเข้าสู่ระบบของคุณ
      (Route<dynamic> route) => false, // ลบทุกหน้าจอที่อยู่ใน Stack
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกการขายน้ำมัน'),
        backgroundColor: const Color.fromARGB(255, 67, 176, 31),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 67, 176, 31),
              ),
              child: Text(
                'เมนู',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.article),
              title: Text('บันทึกข้อมูลลูกค้า'),
              onTap: () {
                // TODO: Add navigation to the home screen
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.redeem),
              title: Text('แลกของรางวัลลูกค้า'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GetRewardedScreen(
                        staff_id: widget.staff_id), // ส่ง staff_id
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.history),
              title: Text('ประวัติการทำรายการ'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        TransactionHistoryScreen(staffId: widget.staff_id),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('ออกจากระบบ'),
              onTap: () {
                _logout(); // เรียกใช้ฟังก์ชันออกจากระบบ
              },
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'เบอร์โทรลูกค้า',
                        labelStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                        prefixIcon: Icon(
                          Icons.phone,
                          color: Colors.green,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.green,
                            width: 1.5,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide(
                            color: Colors.greenAccent,
                            width: 2.0,
                          ),
                        ),
                      ),
                      style: TextStyle(color: Colors.green.shade800),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.qr_code_scanner),
                    onPressed: () => scanQRCode(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text('ประเภทน้ำมัน',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 1,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
                children: [
                  _buildFuelButton('ดีเซล B7', Icons.local_gas_station),
                  _buildFuelButton('ดีเซล B10', Icons.local_gas_station),
                  _buildFuelButton('แก๊สโซฮอล์ E20', Icons.local_gas_station),
                  _buildFuelButton('แก๊สโซฮอล์ 91', Icons.local_gas_station),
                  _buildFuelButton('แก๊สโซฮอล์ E95', Icons.local_gas_station),
                  _buildFuelButton(
                      'ซูเปอร์พาวเวอร์ดีเซล B7', Icons.local_gas_station),
                  _buildFuelButton(
                      'ซูเปอร์พาวเวอร์แก๊สโซฮอล์ 95', Icons.local_gas_station),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                style: TextStyle(
                  fontSize: 20, // ขนาดตัวอักษรใหญ่ขึ้น
                  fontWeight: FontWeight.bold, // ตัวอักษรหนาขึ้น
                  color: Colors.black, // สีตัวอักษร
                ),
                decoration: InputDecoration(
                  labelText: 'จำนวนเงิน (บาท)',
                  labelStyle: TextStyle(
                    fontSize: 18,
                    color: Colors.green, // สีของ label
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.green, // สีกรอบเมื่อไม่ได้เลือกฟิลด์
                      width: 2.0,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide(
                      color: Colors.blue, // สีกรอบเมื่อเลือกฟิลด์
                      width: 2.5,
                    ),
                  ),
                  filled: true,
                  fillColor: Color.fromARGB(255, 240, 255, 240), // สีพื้นหลัง
                  contentPadding: EdgeInsets.symmetric(
                      vertical: 20, horizontal: 15), // ระยะห่างด้านใน
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green, // เปลี่ยนสีปุ่มบันทึกการขาย
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // มุมโค้งของปุ่ม
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15), // ขนาดปุ่ม
                ),
                onPressed: confirmTransaction,
                child: Text(
                  'บันทึกการขาย',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              _devices.isNotEmpty
                  ? DropdownButton<BluetoothDevice>(
                      value: _selectedDevice,
                      hint: const Text('เลือกอุปกรณ์ Bluetooth'),
                      onChanged: (BluetoothDevice? device) {
                        setState(() {
                          _selectedDevice = device;
                        });
                      },
                      items: _devices
                          .map((device) => DropdownMenuItem(
                                value: device,
                                child: Text(device.name ?? ""),
                              ))
                          .toList(),
                    )
                  : const Text('ไม่มีอุปกรณ์ Bluetooth'),
              const SizedBox(height: 10),
              ///////////////////////////////
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side:
                      BorderSide(color: Colors.blueAccent, width: 2), // เส้นขอบ
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8), // มุมโค้งของปุ่ม
                  ),
                  padding: EdgeInsets.symmetric(
                      horizontal: 20, vertical: 15), // ขนาดปุ่ม
                ),
                onPressed: connectToBluetooth,
                icon: Icon(
                  Icons.bluetooth,
                  color: Colors.blueAccent,
                ),
                label: Text(
                  'เชื่อมต่อ Bluetooth',
                  style: TextStyle(
                    color: Colors.blueAccent,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_12/screens_employer/get_rewarded.dart';
import 'package:flutter_application_12/screens_employer/history_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
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

          Navigator.push(
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
          padding: const EdgeInsets.all(10.0), // ปรับขนาด padding ที่นี่
          decoration: BoxDecoration(
            color: selectedFuelType == fuelType
                ? const Color.fromARGB(255, 243, 33, 33)
                : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selectedFuelType == fuelType
                  ? const Color.fromARGB(255, 243, 33, 33)
                  : Colors.grey,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 30, // ปรับขนาดไอคอนที่นี่
                  color: selectedFuelType == fuelType
                      ? Colors.white
                      : Colors.blue),
              const SizedBox(height: 15), // ปรับขนาดที่นี่
              Text(
                fuelType,
                style: TextStyle(
                  color:
                      selectedFuelType == fuelType ? Colors.white : Colors.blue,
                  fontSize: 12, // ปรับขนาดตัวอักษรที่นี่
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกการขายน้ำมัน'),
        backgroundColor: Colors.deepOrange,
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepOrange,
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
              title: Text('หน้าบันทึกข้อมูล'),
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
                        TransactionHistoryScreen(
                          staffId: widget.staff_id),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('ออกจากระบบ'),
              onTap: () {
                // TODO: Handle logout
                Navigator.pop(context);
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
                      decoration: InputDecoration(
                        labelText: 'เบอร์โทร',
                        prefixIcon: const Icon(Icons.phone),
                      ),
                      keyboardType: TextInputType.phone,
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
                  _buildFuelButton('แก๊สโซฮอล์ 95', Icons.local_gas_station),
                  _buildFuelButton(
                      'ซูเปอร์พาวเวอร์ดีเซล B7', Icons.local_gas_station),
                  _buildFuelButton(
                      'ซูเปอร์พาวเวอร์แก๊สโซฮอล์ 95', Icons.local_gas_station),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'จำนวนเงิน',
                  prefixIcon: const Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
              ElevatedButton(
                onPressed: connectToBluetooth,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.bluetooth_connected),
                    SizedBox(width: 8),
                    Text('เชื่อมต่อ Bluetooth'),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: submitTransaction,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.save),
                    SizedBox(width: 8),
                    Text('บันทึกการขาย'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ReceiptScreen extends StatelessWidget {
  final String transactionId;
  final String phoneNumber;
  final String fuelType;
  final double price;
  final int pointsEarned;
  final double dividend;
  final String staffFirstName;
  final String staffLastName;
  final String memberId;
  final String memberFirstName;
  final String memberLastName;
  final String staffId;
  final BluetoothDevice? selectedDevice;

  const ReceiptScreen({
    super.key,
    required this.transactionId,
    required this.phoneNumber,
    required this.fuelType,
    required this.price,
    required this.pointsEarned,
    required this.dividend,
    required this.staffFirstName,
    required this.staffLastName,
    required this.memberId,
    required this.memberFirstName,
    required this.memberLastName,
    required this.staffId,
    this.selectedDevice,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบเสร็จ'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('หมายเลขรายการ: $transactionId'),
            Text('เบอร์โทร: $phoneNumber'),
            Text('ประเภทน้ำมัน: $fuelType'),
            Text('ราคา: ฿${price.toStringAsFixed(2)}'),
            Text('แต้มสะสม: $pointsEarned'),
            Text('ปันผลประจำปี: ฿${dividend.toStringAsFixed(2)}'),
            Text('ผู้บันทึก: $staffFirstName $staffLastName (ID: $staffId)'),
            Text('สมาชิก: $memberFirstName $memberLastName (ID: $memberId)'),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => printReceipt(),
                child: const Text('พิมพ์ใบเสร็จ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> printReceipt() async {
    final bluetooth = BlueThermalPrinter.instance;

    if (selectedDevice == null) {
      print("ยังไม่ได้เลือกอุปกรณ์ Bluetooth.");
      return;
    }

    try {
      bool? isConnected = await bluetooth.isConnected;
      if (!isConnected!) {
        await bluetooth.connect(selectedDevice!);
      }

      // พิมพ์ข้อความภาษาไทย
      bluetooth.printCustom('ใบเสร็จรับเงิน', 3, 1);
      bluetooth.printNewLine();
      bluetooth.printCustom('หมายเลขรายการ: $transactionId', 1, 0);
      bluetooth.printCustom('เบอร์โทร: $phoneNumber', 1, 0);
      bluetooth.printCustom('ID member: $memberId', 1, 0);
      bluetooth.printCustom(
          'ชื่อนามสกุล: $memberFirstName $memberLastName', 1, 0);
      bluetooth.printCustom('ประเภทน้ำมัน: $fuelType', 1, 0);
      bluetooth.printCustom('ราคา: ฿${price.toStringAsFixed(2)}', 1, 0);
      bluetooth.printCustom('แต้มสะสม: $pointsEarned', 1, 0);
      bluetooth.printCustom(
          'ปันผลประจำปี: ฿${dividend.toStringAsFixed(2)}', 1, 0);
      bluetooth.printCustom(
          'วันที่ทำรายการ: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          1,
          0);
      bluetooth.printCustom('ID ผู้บันทึก: $staffId', 1, 0);
      bluetooth.printNewLine();
      bluetooth.printCustom('ขอบคุณที่ใช้บริการ!', 2, 1);
      bluetooth.printNewLine();
      bluetooth.paperCut();

      print("พิมพ์ใบเสร็จสำเร็จ.");
    } catch (e) {
      print("ข้อผิดพลาดในการพิมพ์ใบเสร็จ: $e");
    }
  }
}

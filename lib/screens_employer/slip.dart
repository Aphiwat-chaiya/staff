import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

class ReceiptScreen extends StatefulWidget {
  // ข้อมูลที่ส่งเข้ามาใน Widget นี้
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
  _ReceiptScreenState createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  bool _isPrinting = false; // สถานะการพิมพ์
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('ใบเสร็จ'),
        ),
        body: Screenshot(
          controller: screenshotController,
          child: Container(
            color: Colors.white, // ตั้งค่าสีพื้นหลังเป็นสีขาว
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'ใบเสร็จรับเงิน',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Divider(thickness: 2),
                  SizedBox(height: 10),
                  _buildReceiptRow('หมายเลขรายการ', widget.transactionId),
                  _buildReceiptRow('เบอร์โทร', widget.phoneNumber),
                  _buildReceiptRow('ID สมาชิก', widget.memberId),
                  _buildReceiptRow('ชื่อนามสกุล',
                      '${widget.memberFirstName} ${widget.memberLastName}'),
                  _buildReceiptRow('ประเภทน้ำมัน', widget.fuelType),
                  _buildReceiptRow(
                      'ราคา', '฿${widget.price.toStringAsFixed(2)}'),
                  _buildReceiptRow('แต้มสะสม', widget.pointsEarned.toString()),
                  _buildReceiptRow(
                      'ปันผลประจำปี', '฿${widget.dividend.toStringAsFixed(2)}'),
                  _buildReceiptRow(
                    'วันที่ทำรายการ',
                    DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now()),
                  ),
                  _buildReceiptRow('ผู้บันทึก',
                      '${widget.staffFirstName} ${widget.staffLastName}'),
                  Divider(thickness: 2),
                  const SizedBox(height: 10),
                  if (_isPrinting)
                    Center(
                        child:
                            CircularProgressIndicator()), // แสดงวงกลมหมุนเมื่อพิมพ์
                  Center(
                    child: ElevatedButton.icon(
                      onPressed: () => printReceipt(),
                      icon: const Icon(Icons.print), // ไอคอนพิมพ์
                      label: const Text(
                        'พิมพ์ใบเสร็จ',
                        style: TextStyle(fontSize: 18), // ปรับขนาดฟอนต์ที่นี่
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.blue, // สีของข้อความ
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 10), // ขนาดปุ่ม
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30), // รูปร่างมุมมน
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                      child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(
                          context, true); // ส่งค่า true กลับไปหน้าบันทึก
                    },
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 30, vertical: 20),
                    ),
                    child: const Text(
                      'กลับไปหน้าบันทึก',
                      style: TextStyle(fontSize: 18),
                    ),
                  )),
                ],
              ),
            ),
          ),
        ));
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Future<void> printReceipt() async {
    setState(() {
      _isPrinting = true; // เปลี่ยนสถานะเป็นกำลังพิมพ์
    });

    final bluetooth = BlueThermalPrinter.instance;

    if (widget.selectedDevice == null) {
      print("ยังไม่ได้เลือกอุปกรณ์ Bluetooth.");
      setState(() {
        _isPrinting = false; // รีเซ็ตสถานะ
      });
      return;
    }

    try {
      bool? isConnected = await bluetooth.isConnected;
      if (!isConnected!) {
        await bluetooth.connect(widget.selectedDevice!);
      }

      final image = await screenshotController.capture();
      if (image != null) {
        bluetooth.printImageBytes(image);
      }

      print("พิมพ์ใบเสร็จสำเร็จ.");
    } catch (e) {
      print("ข้อผิดพลาดในการพิมพ์ใบเสร็จ: $e");
    } finally {
      setState(() {
        _isPrinting = false; // รีเซ็ตสถานะหลังจากพิมพ์เสร็จ
      });
    }
  }
}

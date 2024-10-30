import 'package:flutter/material.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:intl/intl.dart';
import 'package:screenshot/screenshot.dart';

class ReceiptScreen extends StatefulWidget {
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
  bool _isPrinting = false;
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบเสร็จ'),
        centerTitle: true, // จัดข้อความให้อยู่กลาง
        backgroundColor: const Color.fromARGB(
            255, 36, 213, 74), // เปลี่ยนสีพื้นหลังของ AppBar
        elevation: 4.0, // ความสูงของเงา
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Center(
            // ใช้ Center เพื่อให้คอนเทนเนอร์อยู่ตรงกลางจอ
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                width: MediaQuery.of(context).size.width *
                    0.4, // ปรับความกว้างให้เหมาะสม
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildReceiptContent(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildButtons(),
        ],
      ),
    );
  }

  String _convertToBuddhistYear(DateTime dateTime) {
    return (dateTime.year + 543).toString(); // เพิ่ม 543 เพื่อแปลงปี
  }

  Widget _buildReceiptContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment
          .start, // ใช้ mainAxisAlignment.start เพื่อให้เนื้อหาอยู่บนสุด
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'ใบเสร็จสะสมแต้ม',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Divider(thickness: 2, color: Colors.black),
        _buildLeftAlignedRow('หมายเลขทำรายการ', widget.transactionId),
        _buildLeftAlignedRow('เลขสมาชิก', widget.memberId),
        _buildLeftAlignedRow(
            'ชื่อ', '${widget.memberFirstName} ${widget.memberLastName}'),
        _buildLeftAlignedRow('น้ำมัน', widget.fuelType),
        _buildLeftAlignedRow('จำนวน', '${widget.price.toStringAsFixed(2)} บาท'),
        _buildLeftAlignedRow('รับแต้มสะสม', widget.pointsEarned.toString()),
        _buildLeftAlignedRow(
            'ปันผล', '${widget.dividend.toStringAsFixed(2)} บาท'),
        _buildLeftAlignedRow(
            'วันทำรายการ',
            DateFormat('dd/MM/yyyy').format(DateTime.now()).replaceFirst(
                RegExp(r'(\d{4})'), _convertToBuddhistYear(DateTime.now()))),
        _buildLeftAlignedRow(
            'เวลา', DateFormat('HH:mm น').format(DateTime.now())),
        _buildLeftAlignedRow(
            'ผู้บันทึก', '${widget.staffFirstName} ${widget.staffLastName}'),
        Divider(thickness: 2, color: Colors.black),
      ],
    );
  }

  Widget _buildButtons() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          if (_isPrinting)
            Center(
              child: CircularProgressIndicator(),
            ),
          const SizedBox(height: 100),
          ElevatedButton(
            onPressed: () => printReceipt(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 113, 187, 199),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 4,
            ),
            child: const Text(
              'พิมพ์ใบเสร็จ',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 23, 145, 74),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
            child: const Text(
              'กลับไปหน้าบันทึก',
              style: TextStyle(fontSize: 16, color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftAlignedRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Text(
        '$label: $value',
        style: TextStyle(
          color: Colors.black,
          fontSize: 12,
        ),
      ),
    );
  }

  Future<void> printReceipt() async {
    setState(() {
      _isPrinting = true;
    });

    final bluetooth = BlueThermalPrinter.instance;

    if (widget.selectedDevice == null) {
      print("ยังไม่ได้เลือกอุปกรณ์ Bluetooth.");
      setState(() {
        _isPrinting = false;
      });
      return;
    }

    try {
      bool? isConnected = await bluetooth.isConnected;
      if (!isConnected!) {
        await bluetooth.connect(widget.selectedDevice!);
      }

      // จับภาพเฉพาะส่วนที่มีข้อมูลตัวอักษร
      final image = await screenshotController.capture();
      if (image != null) {
        bluetooth.printNewLine();
        bluetooth.printImageBytes(image);
        bluetooth.printNewLine();
      }
      print("พิมพ์ใบเสร็จสำเร็จ.");
    } catch (e) {
      print("ข้อผิดพลาดในการพิมพ์ใบเสร็จ: $e");
    } finally {
      setState(() {
        _isPrinting = false;
      });
    }
  }
}

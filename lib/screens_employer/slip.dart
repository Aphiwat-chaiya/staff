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
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start, // ย้ายเนื้อหาไปด้านบนสุด
        children: [
          Screenshot(
            controller: screenshotController,
            child: Container(
              width: 150,
              color: Colors.white,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: _buildReceiptContent(),
              ),
            ),
          ),
          const SizedBox(height: 0.1),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start, // ใช้ mainAxisAlignment.start เพื่อให้เนื้อหาอยู่บนสุด
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
        _buildLeftAlignedRow('หมายเลขรายการ', widget.transactionId),
        _buildLeftAlignedRow('ID สมาชิก', widget.memberId),
        _buildLeftAlignedRow('ชื่อนามสกุล', '${widget.memberFirstName} ${widget.memberLastName}'),
        _buildLeftAlignedRow('ประเภทน้ำมัน', widget.fuelType),
        _buildLeftAlignedRow('ราคา', '฿${widget.price.toStringAsFixed(2)}'),
        _buildLeftAlignedRow('แต้มสะสม', widget.pointsEarned.toString()),
        _buildLeftAlignedRow('ปันผลประจำปี', '฿${widget.dividend.toStringAsFixed(2)}'),
        _buildLeftAlignedRow('วันที่ทำรายการ', DateFormat('dd/MM/yyyy').format(DateTime.now())),
        _buildLeftAlignedRow('เวลา', DateFormat('HH:mm').format(DateTime.now())),
        _buildLeftAlignedRow('ผู้บันทึก', '${widget.staffFirstName} ${widget.staffLastName}'),
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
          ElevatedButton(
            onPressed: () => printReceipt(),
            child: const Text('พิมพ์ใบเสร็จ'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true);
            },
            child: const Text('กลับไปหน้าบันทึก'),
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

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
  bool _isPrinting = false; // สถานะการพิมพ์
  ScreenshotController screenshotController = ScreenshotController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบเสร็จ'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Screenshot(
              controller: screenshotController,
              child: Container(
                width: 384, // ขนาดกว้าง 58mm ที่ 203 DPI
                color: Colors.white, // ตั้งพื้นหลังเป็นสีขาว
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildReceiptContent(),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          _buildButtons(),
        ],
      ),
    );
  }

  Widget _buildReceiptContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Text(
            'ใบเสร็จรับเงิน',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ),
        Divider(thickness: 2, color: Colors.black),
        SizedBox(height: 10),
        _buildReceiptRow('หมายเลขรายการ', widget.transactionId),
        _buildReceiptRow('เบอร์โทร', widget.phoneNumber),
        _buildReceiptRow('ID สมาชิก', widget.memberId),
        _buildReceiptRow('ชื่อนามสกุล',
            '${widget.memberFirstName} ${widget.memberLastName}'),
        _buildReceiptRow('ประเภทน้ำมัน', widget.fuelType),
        _buildReceiptRow('ราคา', '฿${widget.price.toStringAsFixed(2)}'),
        _buildReceiptRow('แต้มสะสม', widget.pointsEarned.toString()),
        _buildReceiptRow(
            'ปันผลประจำปี', '฿${widget.dividend.toStringAsFixed(2)}'),
        _buildReceiptRow('วันที่ทำรายการ',
            DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())),
        _buildReceiptRow(
            'ผู้บันทึก', '${widget.staffFirstName} ${widget.staffLastName}'),
        Divider(thickness: 2, color: Colors.black),
        const SizedBox(height: 10),
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
              child: CircularProgressIndicator(), // แสดงวงกลมหมุนเมื่อพิมพ์
            ),
          ElevatedButton(
            onPressed: () => printReceipt(),
            child: const Text('พิมพ์ใบเสร็จ'),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context, true); // ส่งค่า true กลับไปหน้าบันทึก
            },
            child: const Text('กลับไปหน้าบันทึก'),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0), // ปรับระยะเว้น
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, // ชิดซ้ายทั้งหมด
        children: [
          Text(
            label,
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
          ),
          Text(
            value,
            style: TextStyle(color: Colors.black),
          ),
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

      // ใช้ screenshotController แคปภาพหน้าจอ
      final image = await screenshotController.capture();
      if (image != null) {
        bluetooth.printNewLine();
        bluetooth.printImageBytes(image); // พิมพ์ภาพที่แคปเจอร์ได้
        bluetooth.printNewLine();
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

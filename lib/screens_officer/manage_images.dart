import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ImageManagementPage extends StatefulWidget {
  final String officer_id;

  const ImageManagementPage({super.key, required this.officer_id});

  @override
  _ImageManagementPageState createState() => _ImageManagementPageState();
}

class _ImageManagementPageState extends State<ImageManagementPage> {
  List<Map<String, dynamic>> _activeImages = [];
  List<Map<String, dynamic>> _allImages = [];
  bool _isLoading = false;
  late String officerId;

  @override
  void initState() {
    super.initState();
    officerId = widget.officer_id;
    _fetchImages();
  }

  Future<void> _fetchImages() async {
    setState(() {
      _isLoading = true;
    });

    var response = await http.get(Uri.parse('http://192.168.1.30:3000/get_images'));

    if (response.statusCode == 200) {
      var images = (jsonDecode(response.body) as List).cast<Map<String, dynamic>>();
      setState(() {
        _activeImages = images
            .where((img) => img['status'] == 'true')
            .map((img) => {
                  ...img,
                  'image_url': 'http://192.168.1.30:3000/uploadnews/${img['image_url']}',
                })
            .toList();
        _allImages = images
            .where((img) => img['status'] == 'false')
            .map((img) => {
                  ...img,
                  'image_url': 'http://192.168.1.30:3000/uploadnews/${img['image_url']}',
                })
            .toList();

        if (_activeImages.length > 6) {
          _activeImages = _activeImages.take(6).toList();
        }
      });
    } else {
      _showErrorDialog('Failed to fetch images');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _updateImageStatus(int imageId, String newStatus) async {
    var response = await http.post(
      Uri.parse('http://192.168.1.30:3000/update_image_status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'image_id': imageId,
        'officer_id': officerId,
        'status': newStatus,
      }),
    );

    print('Update response: ${response.statusCode} - ${response.body}');

    if (response.statusCode == 200) {
      await _fetchImages();
    } else {
      _showErrorDialog('Failed to update image status');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImageList(List<Map<String, dynamic>> images, bool isActive) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: images.length,
      itemBuilder: (context, index) {
        return Draggable<Map<String, dynamic>>(
          data: images[index],
          child: GestureDetector(
            onTap: () {
              _showDescriptionDialog(images[index]['description']);
            },
            child: _buildImageContainer(images[index]['image_url']),
          ),
          feedback: Material(
            child: _buildImageContainer(images[index]['image_url'], isFeedback: true),
          ),
          childWhenDragging: Container(),
        );
      },
    );
  }

  Widget _buildImageContainer(String imageUrl, {bool isFeedback = false}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          loadingBuilder: (BuildContext context, Widget child, ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) {
              return child;
            } else {
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded / (loadingProgress.expectedTotalBytes ?? 1)
                      : null,
                ),
              );
            }
          },
          errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
            return const Center(child: Text('Failed to load image'));
          },
        ),
      ),
    );
  }

  void _showDescriptionDialog(String description) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Description'),
          content: Text(description),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDropZone() {
    return DragTarget<Map<String, dynamic>>(
      onAcceptWithDetails: (details) {
        // เปลี่ยนสถานะจาก "true" เป็น "false" และจาก "false" เป็น "true"
        String newStatus = details.data['status'] == 'true' ? 'false' : 'true';
        _updateImageStatus(details.data['image_id'], newStatus);
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          height: 100,
          color: candidateData.isNotEmpty ? Colors.green : Colors.red,
          child: const Center(child: Text('Drag Here to Change Status')),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Management'),
        backgroundColor: Colors.blueAccent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('Active Images', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    _buildImageList(_activeImages, true),
                    _buildDropZone(), // เพิ่ม DragTarget
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16.0),
                      child: Text('All Images', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    ),
                    _buildImageList(_allImages, false),
                  ],
                ),
              ),
            ),
    );
  }
}

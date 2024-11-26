import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_application_12/screens_officer/add_new.dart';

class NewsPage extends StatefulWidget {
  @override
  _NewsPageState createState() => _NewsPageState();
}

class _NewsPageState extends State<NewsPage> {
  List<dynamic> newsList = [];

  @override
  void initState() {
    super.initState();
    _fetchNews();
  }

  Future<void> _fetchNews() async {
    final url = 'http://192.168.1.19:3000/news'; // URL ของ API

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          newsList = json.decode(response.body);
        });
      } else {
        print('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news data: $e');
    }
  }

  Future<void> _deleteNewsItem(int id) async {
    final url = 'http://localhost:3000/delete_news/$id'; // URL ของ API สำหรับลบข่าว

    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          newsList.removeWhere((item) => item['image_id'] == id);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ลบข่าวสำเร็จ')),
        );
      } else {
        print('Failed to delete news');
      }
    } catch (e) {
      print('Error deleting news: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final String officerId =
        ModalRoute.of(context)!.settings.arguments as String;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ข่าวสาร'),
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ImageUploadPage()),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: ListView.builder(
            itemCount: newsList.length,
            itemBuilder: (context, index) {
              final newsItem = newsList[index];
              return Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            'http://192.168.1.19:3000/uploadnews/${newsItem['image_url']}',
                            width: double.infinity,
                            height: 200,
                            fit: BoxFit.cover,
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _deleteNewsItem(newsItem['image_id']);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      newsItem['description'] ?? 'ไม่มีคำอธิบาย',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const Divider(
                      height: 20,
                      thickness: 1,
                      color: Colors.grey,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

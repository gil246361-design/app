import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

class Movie {
  final String title;
  final String director;
  final String releaseDate;
  final String openingCrawl;

  Movie({
    required this.title,
    required this.director,
    required this.releaseDate,
    required this.openingCrawl,
  });

  factory Movie.fromJson(Map<String, dynamic> json) {
    return Movie(
      title: json['title'] as String? ?? 'ไม่ทราบชื่อ',
      director: json['director'] as String? ?? 'ไม่ทราบข้อมูล',
      releaseDate: json['release_date'] as String? ?? '-',
      openingCrawl: json['opening_crawl'] as String? ?? '',
    );
  }
}

class ApiService {
  // รหัสนักศึกษาของเจ้าของแอป
  static const String studentId = '67011212099';

  // URL กล่องข้อมูลของนักศึกษาคนนี้
  static const String baseUrl =
      'https://thipwimon.comsciproject.net/mydiary/api.php/$studentId';

  // CREATE - เพิ่มข้อมูลด้วย POST
  static Future<void> createDiary(
    String title,
    String content,
    String mood,
    String date,
  ) async {
    final url = Uri.parse(baseUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'mood': mood,
        'date': date,
      }),
    );
    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception('เพิ่มไม่สำเร็จ (${response.statusCode})');
    }
  }

  // READ - อ่านข้อมูลทั้งหมดด้วย GET
  static Future<List<dynamic>> getDiaries() async {
    final url = Uri.parse(baseUrl);
    final response = await http.get(url);
    if (response.statusCode != 200) {
      throw Exception('โหลดไม่สำเร็จ (${response.statusCode})');
    }
    final data = jsonDecode(response.body);
    if (data is! List) {
      throw Exception('รูปแบบข้อมูลจาก server ไม่ถูกต้อง');
    }
    return data;
  }

  // UPDATE - แก้ไขข้อมูลด้วย PUT
  static Future<void> updateDiary(
    String id,
    String title,
    String content,
    String mood,
    String date,
  ) async {
    final url = Uri.parse('$baseUrl/$id');
    final response = await http.put(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'title': title,
        'content': content,
        'mood': mood,
        'date': date,
      }),
    );
    if (response.statusCode != 200) {
      throw Exception('แก้ไขไม่สำเร็จ (${response.statusCode})');
    }
  }

  // DELETE - ลบข้อมูลด้วย DELETE
  static Future<void> deleteDiary(String id) async {
    final url = Uri.parse('$baseUrl/$id');
    final response = await http.delete(url);
    if (response.statusCode != 200) {
      throw Exception('ลบไม่สำเร็จ (${response.statusCode})');
    }
  }

  // API เดิม - สุ่มหนังจาก Star Wars API
  static Future<Movie> fetchMovie() async {
    try {
      final url = Uri.parse('https://swapi.dev/api/films/');
      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        throw Exception('เซิร์ฟเวอร์ตอบผิดพลาด (${response.statusCode})');
      }
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results = data['results'] as List<dynamic>;
      if (results.isEmpty) {
        throw Exception('ไม่พบข้อมูลหนัง');
      }
      final random = Random();
      final selected =
          results[random.nextInt(results.length)] as Map<String, dynamic>;
      return Movie.fromJson(selected);
    } catch (e) {
      throw Exception('เชื่อมต่อไม่ได้ ตรวจสอบอินเทอร์เน็ต');
    }
  }
}

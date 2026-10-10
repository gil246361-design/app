import 'package:flutter/material.dart';
import 'firestore_diary.dart';
import 'database_helper.dart';
import 'api_service.dart';
import 'online_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'login_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

// =====================================================
// MODEL : Diary
// =====================================================

class Diary {
  final int? id;
  final String title;
  final String content;
  final String quote;
  final String date;
  final String point;
  final String mood;
  final bool isImportant;
  final bool isPinned;
  final String type;

  Diary({
    this.id,
    required this.title,
    required this.content,
    this.quote = '',
    required this.date,
    required this.point,
    required this.mood,
    required this.isImportant,
    required this.isPinned,
    required this.type,
  });

  // ===================================================
  // Diary -> Map
  // ===================================================

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'quote': quote,
      'date': date,
      'point': point,
      'mood': mood,

      // SQLite ใช้ 0 / 1 แทน false / true
      'isImportant': isImportant ? 1 : 0,
      'isPinned': isPinned ? 1 : 0,

      'type': type,
    };
  }

  // ===================================================
  // Map -> Diary
  // ===================================================

  factory Diary.fromMap(Map<String, dynamic> map) {
    return Diary(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      content: map['content'] as String? ?? '',
      quote: map['quote'] as String? ?? '',
      date: map['date'] as String? ?? '',
      point: map['point'] as String? ?? '0',

      // รองรับกรณีข้อมูลเก่าไม่มี mood
      mood: map['mood'] as String? ?? 'เฉยๆ',

      isImportant: map['isImportant'] == 1,
      isPinned: map['isPinned'] == 1,

      type: map['type'] as String? ?? movieGenres.first.name,
    );
  }
}

// =====================================================
// MOVIE GENRE (ใช้แทนฟิลด์ "ประเภท" เดิม ให้เหมาะกับธีมหนัง)
// =====================================================

class MovieGenre {
  final String name;
  final IconData icon;
  final Color color;

  const MovieGenre(this.name, this.icon, this.color);
}

const List<MovieGenre> movieGenres = [
  MovieGenre('แอ็คชัน', Icons.local_fire_department, Color(0xFFE53935)),
  MovieGenre('ดราม่า', Icons.theater_comedy, Color(0xFF8E24AA)),
  MovieGenre('สยองขวัญ', Icons.nightlight_round, Color(0xFF5E35B1)),
  MovieGenre('ตลก', Icons.sentiment_very_satisfied, Color(0xFFFFB300)),
  MovieGenre('โรแมนติก', Icons.favorite, Color(0xFFD81B60)),
  MovieGenre('ไซไฟ', Icons.rocket_launch, Color(0xFF1E88E5)),
  MovieGenre('แอนิเมชัน', Icons.brush, Color(0xFF43A047)),
];

MovieGenre genreOf(String name) {
  return movieGenres.firstWhere(
    (g) => g.name == name,
    orElse: () => movieGenres.first,
  );
}

// =====================================================
// MY APP
// =====================================================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyMovie',
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const AuthGate(),
    );
  }
}

// =====================================================
// MAIN PAGE
// =====================================================

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DiaryListPage(), // แท็บ SQLite + คำคม (ของเดิม)
    const ApiDiaryPage(), // แท็บ REST API (สัปดาห์ 4)
    const FirestoreDiaryPage(), // แท็บ Cloud (สัปดาห์นี้)
    const AboutPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // ต้องมีเมื่อ 4 แท็บขึ้นไป
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.movie), label: 'บันทึก'),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud_queue),
            label: 'ออนไลน์',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.cloud),
            label: 'Cloud',
          ), // แท็บที่ต้องเพิ่ม
          BottomNavigationBarItem(icon: Icon(Icons.info), label: 'เกี่ยวกับ'),
        ],
      ),
    );
  }
}

class ApiMoviePage extends StatelessWidget {
  const ApiMoviePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('หนังจาก Internet')),
      body: const Center(
        child: Text('หน้า API หนัง', style: TextStyle(fontSize: 24)),
      ),
    );
  }
}

// =====================================================
// DIARY LIST PAGE
// =====================================================

class DiaryListPage extends StatefulWidget {
  const DiaryListPage({super.key});

  @override
  State<DiaryListPage> createState() => _DiaryListPageState();
}

class _DiaryListPageState extends State<DiaryListPage> {
  List<Diary> diaries = [];

  @override
  void initState() {
    super.initState();

    _loadDiaries();
  }

  // ===================================================
  // โหลดข้อมูลจาก SQLite
  // ===================================================

  Future<void> _loadDiaries() async {
    final data = await DatabaseHelper.getAll();

    if (!mounted) return;

    setState(() {
      diaries = data;
    });
  }

  // ===================================================
  // เพิ่มบันทึก
  // ===================================================

  Future<void> _addDiary(Diary diary) async {
    await DatabaseHelper.insert(diary);

    await _loadDiaries();
  }

  // ===================================================
  // แก้ไขบันทึก
  // ===================================================

  Future<void> _updateDiary(Diary diary) async {
    await DatabaseHelper.update(diary);

    await _loadDiaries();
  }

  // ===================================================
  // ลบบันทึก
  // ===================================================

  Future<void> _deleteDiary(int id) async {
    await DatabaseHelper.delete(id);

    await _loadDiaries();
  }

  // ===================================================
  // ยืนยันก่อนลบ
  // ===================================================

  Future<void> _confirmDelete(Diary diary) async {
    final confirm = await showDialog<bool>(
      context: context,

      builder: (ctx) {
        return AlertDialog(
          title: const Text('ลบบันทึก?'),

          content: Text('ต้องการลบ "${diary.title}" ใช่ไหม'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx, false);
              },

              child: const Text('ยกเลิก'),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(ctx, true);
              },

              child: const Text('ลบ', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirm == true && diary.id != null) {
      await _deleteDiary(diary.id!);
    }
  }

  // ===================================================
  // เปิดหน้าเพิ่ม
  // ===================================================

  Future<void> _openAddPage() async {
    final result = await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) {
          return const AddDiaryPage();
        },
      ),
    );

    if (result != null && result is Diary) {
      await _addDiary(result);
    }
  }

  // ===================================================
  // เปิดหน้าแก้ไข
  // ===================================================

  Future<void> _openEditPage(Diary diary) async {
    final result = await Navigator.push(
      context,

      MaterialPageRoute(
        builder: (context) {
          return AddDiaryPage(existing: diary);
        },
      ),
    );

    if (result != null && result is Diary) {
      await _updateDiary(result);
    }
  }

  // ===================================================
  // สีธีมโรงหนัง (ใช้เฉพาะหน้านี้เท่านั้น)
  // ===================================================
  static const Color _cinemaBg = Color(0xFF0E0E12);
  static const Color _cinemaCard = Color(0xFF1B1B22);
  static const Color _cinemaGold = Color(0xFFE8B84B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cinemaBg,

      // =================================================
      // APP BAR — ธีมโรงภาพยนตร์ / ม่านโรงหนัง
      // =================================================
      appBar: AppBar(
        centerTitle: true,
        backgroundColor: const Color(0xFF191016),
        elevation: 4,
        iconTheme: const IconThemeData(color: _cinemaGold),

        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.theaters, color: _cinemaGold),
            const SizedBox(width: 8),
            Text(
              'คลังหนังของฉัน (${diaries.length})',
              style: const TextStyle(
                color: _cinemaGold,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),

        actions: [
          IconButton(
            tooltip: 'คำคมจากอินเทอร์เน็ต',
            icon: const Icon(Icons.format_quote, color: _cinemaGold),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const QuotePage()),
              );
            },
          ),
        ],
      ),

      // =================================================
      // BODY
      // =================================================
      body: diaries.isEmpty
          // -----------------------------
          // ไม่มีข้อมูล — จอฉายว่าง
          // -----------------------------
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,

                children: [
                  Icon(Icons.local_movies, size: 90, color: _cinemaGold),

                  SizedBox(height: 16),

                  Text(
                    'โรงหนังของคุณยังว่างอยู่',
                    style: TextStyle(
                      fontSize: 19,
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8),

                  Text(
                    'กดปุ่ม 🎬 เพื่อบันทึกหนังเรื่องแรกของคุณ',
                    style: TextStyle(color: Colors.white38),
                  ),
                ],
              ),
            )
          // -----------------------------
          // มีข้อมูล — โปสเตอร์รายเรื่อง
          // -----------------------------
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: diaries.length,

              itemBuilder: (context, i) {
                final diary = diaries[i];
                final genre = genreOf(diary.type);

                return Card(
                  color: _cinemaCard,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: genre.color, width: 1.2),
                  ),

                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),

                    // ===================================
                    // ไอคอนแนวหนัง ตามประเภท
                    // ===================================
                    leading: CircleAvatar(
                      radius: 24,
                      backgroundColor: genre.color.withOpacity(0.25),
                      child: Icon(genre.icon, color: genre.color, size: 26),
                    ),

                    // ===================================
                    // ชื่อหนัง + คะแนน
                    // ===================================
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(
                            diary.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: _cinemaGold,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${diary.point}/10',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _cinemaGold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    // ===================================
                    // แนวหนัง + อารมณ์ + วันที่
                    // ===================================
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: genre.color.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              genre.name,
                              style: TextStyle(
                                fontSize: 12,
                                color: genre.color,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            '${diary.mood} • ${diary.date}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ],
                      ),
                    ),

                    // ===================================
                    // แก้ไข + ลบ
                    // ===================================
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,

                      children: [
                        // แก้ไข
                        IconButton(
                          icon: const Icon(Icons.edit, color: _cinemaGold),

                          onPressed: () {
                            _openEditPage(diary);
                          },
                        ),

                        // ลบ
                        IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: Color(0xFFE05353),
                          ),

                          onPressed: () {
                            _confirmDelete(diary);
                          },
                        ),
                      ],
                    ),

                    // ===================================
                    // ดูรายละเอียด
                    // ===================================
                    onTap: () {
                      Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (context) {
                            return DiaryDetailPage(diary: diary);
                          },
                        ),
                      );
                    },
                  ),
                );
              },
            ),

      // =================================================
      // ปุ่มเพิ่มหนัง — สไตล์กระดานสเลทถ่ายหนัง
      // =================================================
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddPage,
        backgroundColor: _cinemaGold,
        foregroundColor: const Color(0xFF191016),
        icon: const Icon(Icons.movie_creation),
        label: const Text(
          'เพิ่มหนัง',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// =====================================================
// ADD / EDIT DIARY PAGE
// =====================================================

class AddDiaryPage extends StatefulWidget {
  // ถ้า null = เพิ่ม
  // ถ้ามีค่า = แก้ไข
  final Diary? existing;

  const AddDiaryPage({super.key, this.existing});

  @override
  State<AddDiaryPage> createState() => _AddDiaryPageState();
}

class _AddDiaryPageState extends State<AddDiaryPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();

  final TextEditingController _contentController = TextEditingController();

  bool _isImportant = false;

  bool _isPinned = false;

  String _type = movieGenres.first.name;

  String _selectedMood = 'มีความสุข';

  final List<String> _moods = [
    'มีความสุข',
    'เฉยๆ',
    'เศร้า',
    'เหนื่อย',
    'ตื่นเต้น',
  ];

  // วันที่เริ่มต้น = วันนี้
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    // =================================================
    // ถ้าเป็นโหมดแก้ไข ให้เอาข้อมูลเดิมมาใส่
    // =================================================

    if (widget.existing != null) {
      final diary = widget.existing!;

      _titleController.text = diary.title;

      _contentController.text = diary.content;

      _selectedMood = diary.mood;

      _selectedDate = DateTime.parse(diary.date);

      _isImportant = diary.isImportant;

      _isPinned = diary.isPinned;

      _type = diary.type;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();

    _contentController.dispose();

    super.dispose();
  }

  // ===================================================
  // เลือกวันที่
  // ===================================================

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,

      initialDate: _selectedDate,

      firstDate: DateTime(2000),

      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  // ===================================================
  // SAVE
  // ===================================================

  void _saveDiary() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final diary = Diary(
      // ถ้าแก้ไข ให้ใช้ id เดิม
      id: widget.existing?.id,

      title: _titleController.text.trim(),

      content: _contentController.text.trim(),

      quote: widget.existing?.quote ?? '',

      date: _selectedDate.toString().substring(0, 10),

      // ตอนนี้ยังเริ่มที่ 0
      point: widget.existing?.point ?? '0',

      mood: _selectedMood,

      isImportant: _isImportant,

      isPinned: _isPinned,

      type: _type,
    );

    Navigator.pop(context, diary);
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.existing != null;

    return Scaffold(
      // =================================================
      // APP BAR
      // =================================================
      appBar: AppBar(title: Text(isEdit ? 'แก้ไขบันทึก' : 'เพิ่มบันทึกหนัง')),

      // =================================================
      // BODY
      // =================================================
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                // ========================================
                // TITLE
                // ========================================
                TextFormField(
                  controller: _titleController,

                  decoration: const InputDecoration(
                    labelText: 'ชื่อหนัง',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.movie),
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกชื่อหนัง';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ========================================
                // CONTENT
                // ========================================
                TextFormField(
                  controller: _contentController,

                  maxLines: 5,

                  decoration: const InputDecoration(
                    labelText: 'รายละเอียด',

                    border: OutlineInputBorder(),

                    prefixIcon: Icon(Icons.notes),

                    alignLabelWithHint: true,
                  ),

                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'กรุณากรอกรายละเอียด';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                // ========================================
                // DATE
                // ========================================
                const Text(
                  'วันที่ดูหนัง',

                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                SizedBox(
                  width: double.infinity,

                  child: OutlinedButton.icon(
                    onPressed: _selectDate,

                    icon: const Icon(Icons.calendar_month),

                    label: Text(
                      '${_selectedDate.year}-'
                      '${_selectedDate.month.toString().padLeft(2, '0')}-'
                      '${_selectedDate.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ========================================
                // MOOD
                // ========================================
                DropdownButtonFormField<String>(
                  initialValue: _selectedMood,

                  decoration: const InputDecoration(
                    labelText: 'อารมณ์วันนี้',

                    border: OutlineInputBorder(),
                  ),

                  items: _moods.map((mood) {
                    return DropdownMenuItem<String>(
                      value: mood,

                      child: Text(mood),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _selectedMood = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 10),

                // ========================================
                // IMPORTANT
                // ========================================
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,

                  title: const Text('บันทึกสำคัญ'),

                  value: _isImportant,

                  onChanged: (value) {
                    setState(() {
                      _isImportant = value ?? false;
                    });
                  },
                ),

                // ========================================
                // PINNED
                // ========================================
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,

                  title: const Text('ปักหมุด'),

                  value: _isPinned,

                  onChanged: (value) {
                    setState(() {
                      _isPinned = value;
                    });
                  },
                ),

                const SizedBox(height: 10),

                // ========================================
                // TYPE (แนวหนัง)
                // ========================================
                const Text(
                  'แนวหนัง (ประเภท)',

                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 8),

                DropdownButtonFormField<String>(
                  initialValue: _type,

                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.local_movies),
                  ),

                  items: movieGenres.map((genre) {
                    return DropdownMenuItem<String>(
                      value: genre.name,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(genre.icon, color: genre.color, size: 20),
                          const SizedBox(width: 8),
                          Text(genre.name),
                        ],
                      ),
                    );
                  }).toList(),

                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _type = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 20),

                // ========================================
                // SAVE BUTTON
                // ========================================
                SizedBox(
                  width: double.infinity,

                  height: 50,

                  child: ElevatedButton.icon(
                    onPressed: _saveDiary,

                    icon: Icon(isEdit ? Icons.edit : Icons.save),

                    label: Text(
                      isEdit ? 'บันทึกการแก้ไข' : 'บันทึก',

                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =====================================================
// DETAIL PAGE
// =====================================================

class DiaryDetailPage extends StatelessWidget {
  final Diary diary;

  const DiaryDetailPage({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('รายละเอียด')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==========================================
            // ICON
            // ==========================================
            Center(
              child: CircleAvatar(
                radius: 50,

                backgroundColor: Colors.indigo,

                child: const Icon(Icons.movie, size: 55, color: Colors.white),
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // TITLE
            // ==========================================
            Text(
              diary.title,

              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            // ==========================================
            // DATE
            // ==========================================
            Row(
              children: [
                const Icon(Icons.calendar_month, size: 20),

                const SizedBox(width: 8),

                Text(
                  diary.date,

                  style: const TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==========================================
            // MOOD
            // ==========================================
            Row(
              children: [
                const Icon(Icons.mood, size: 20),

                const SizedBox(width: 8),

                Text(
                  'อารมณ์: ${diary.mood}',

                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ==========================================
            // TYPE
            // ==========================================
            Row(
              children: [
                const Icon(Icons.category, size: 20),

                const SizedBox(width: 8),

                Text(
                  'ประเภท: ${diary.type}',

                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 15),

            // ==========================================
            // IMPORTANT
            // ==========================================
            if (diary.isImportant)
              const Row(
                children: [
                  Icon(Icons.star, color: Colors.orange),

                  SizedBox(width: 8),

                  Text(
                    'บันทึกสำคัญ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

            const SizedBox(height: 10),

            // ==========================================
            // PINNED
            // ==========================================
            if (diary.isPinned)
              const Row(
                children: [
                  Icon(Icons.push_pin, color: Colors.red),

                  SizedBox(width: 8),

                  Text(
                    'ปักหมุดแล้ว',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),

            const SizedBox(height: 20),

            const Divider(),

            const SizedBox(height: 15),

            // ==========================================
            // POINT
            // ==========================================
            Align(
              alignment: Alignment.centerRight,

              child: Text(
                'คะแนน: ${diary.point} / 10',

                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ==========================================
            // QUOTE
            // ==========================================
            if (diary.quote.isNotEmpty) ...[
              const Text(
                'คำคม',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Text(
                  '“${diary.quote}”',
                  style: const TextStyle(fontSize: 17, height: 1.6),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // ==========================================
            // CONTENT TITLE
            // ==========================================
            const Text(
              'รายละเอียด',

              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 10),

            // ==========================================
            // CONTENT
            // ==========================================
            Container(
              width: double.infinity,

              padding: const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.grey.shade100,

                borderRadius: BorderRadius.circular(15),
              ),

              child: Text(
                diary.content,

                style: const TextStyle(fontSize: 17, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// ABOUT PAGE
// =====================================================

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('เกี่ยวกับ'), centerTitle: true),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              // =========================================
              // ICON
              // =========================================
              const CircleAvatar(
                radius: 55,

                backgroundColor: Colors.indigo,

                child: Icon(
                  Icons.movie_creation,
                  size: 65,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 20),

              // =========================================
              // APP NAME
              // =========================================
              const Text(
                'My Movie',

                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 10),

              const Text(
                'favorite Movie',

                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),

              const SizedBox(height: 30),

              const Text(
                'แอปสำหรับบันทึกข้อมูลภาพยนตร์ที่ชื่นชอบ',

                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              const Text('สร้างโดยนักศึกษา', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

// =====================================================
// MOVIE API PAGE — FutureBuilder + Error + Refresh + SQLite
// =====================================================

class QuotePage extends StatefulWidget {
  const QuotePage({super.key});

  @override
  State<QuotePage> createState() => _QuotePageState();
}

class _QuotePageState extends State<QuotePage> {
  late Future<Movie> _movieFuture;

  @override
  void initState() {
    super.initState();
    _movieFuture = ApiService.fetchMovie();
  }

  void _refreshMovie() {
    setState(() {
      _movieFuture = ApiService.fetchMovie();
    });
  }

  Future<void> _saveMovie(Movie movie) async {
    final diary = Diary(
      title: movie.title,
      content: movie.openingCrawl.isEmpty
          ? 'ภาพยนตร์จาก Star Wars API'
          : movie.openingCrawl,
      quote: movie.openingCrawl,
      date: DateTime.now().toString().substring(0, 10),
      point: '0',
      mood: 'ตื่นเต้น',
      isImportant: true,
      isPinned: false,
      type: 'ไซไฟ',
    );

    try {
      await DatabaseHelper.insert(diary);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('บันทึกหนังลง SQLite แล้ว')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('บันทึกไม่สำเร็จ: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('หนังจากอินเทอร์เน็ต'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'สุ่มหนังใหม่',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshMovie,
          ),
        ],
      ),
      body: FutureBuilder<Movie>(
        future: _movieFuture,
        builder: (context, snapshot) {
          // ================================
          // LOADING
          // ================================
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'กำลังโหลดข้อมูลหนัง...',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // ================================
          // ERROR
          // ================================
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 70, color: Colors.grey),
                    const SizedBox(height: 12),
                    const Text(
                      'โหลดข้อมูลหนังไม่ได้',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snapshot.error.toString().replaceFirst('Exception: ', ''),
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: _refreshMovie,
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: Text('ไม่พบข้อมูลหนัง'));
          }

          final movie = snapshot.data!;

          // ================================
          // MOVIE DATA
          // ================================
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 90,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.indigo,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.movie_creation,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Text(
                        movie.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _movieInfo(Icons.person, 'ผู้กำกับ', movie.director),
                    const SizedBox(height: 10),
                    _movieInfo(
                      Icons.calendar_month,
                      'วันที่ออกฉาย',
                      movie.releaseDate,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'เรื่องย่อ',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        movie.openingCrawl.isEmpty
                            ? 'ไม่มีเรื่องย่อจาก API'
                            : movie.openingCrawl,
                        style: const TextStyle(fontSize: 16, height: 1.5),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () => _saveMovie(movie),
                        icon: const Icon(Icons.bookmark_add),
                        label: const Text('บันทึกหนังลง MyDiary'),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _refreshMovie,
                        icon: const Icon(Icons.shuffle),
                        label: const Text('สุ่มหนังเรื่องใหม่'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _movieInfo(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Colors.indigo),
        const SizedBox(width: 10),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

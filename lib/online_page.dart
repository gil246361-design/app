import 'package:flutter/material.dart';

import 'api_service.dart';

// =====================================================
// REST API CRUD PAGE - WEEK 4
// =====================================================

class ApiDiaryPage extends StatefulWidget {
  const ApiDiaryPage({super.key});

  @override
  State<ApiDiaryPage> createState() => _ApiDiaryPageState();
}

class _ApiDiaryPageState extends State<ApiDiaryPage> {
  late Future<List<dynamic>> _diariesFuture;

  @override
  void initState() {
    super.initState();
    _loadDiaries();
  }

  void _loadDiaries() {
    _diariesFuture = ApiService.getDiaries();
  }

  Future<void> _addDiary(String title, String content, String mood, String date) async {
    try {
      await ApiService.createDiary(title, content, mood, date);
      if (!mounted) return;
      setState(_loadDiaries);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('เพิ่มบันทึกสำเร็จ')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _updateDiary(String id, String title, String content, String mood, String date) async {
    try {
      await ApiService.updateDiary(id, title, content, mood, date);
      if (!mounted) return;
      setState(_loadDiaries);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('แก้ไขบันทึกสำเร็จ')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  Future<void> _deleteDiary(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบบันทึก?'),
        content: const Text('ต้องการลบบันทึกนี้จาก server ใช่ไหม'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ยกเลิก')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('ลบ')),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.deleteDiary(id);
      if (!mounted) return;
      setState(_loadDiaries);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ลบบันทึกสำเร็จ')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
    }
  }

  String _getId(dynamic value) => value.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('บันทึกออนไลน์ - REST API'),
        actions: [
          IconButton(
            tooltip: 'โหลดใหม่',
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(_loadDiaries),
          ),
        ],
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _diariesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.cloud_off, size: 70),
                    const SizedBox(height: 12),
                    const Text('โหลดข้อมูลไม่ได้', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(snapshot.error.toString().replaceFirst('Exception: ', ''), textAlign: TextAlign.center),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: () => setState(_loadDiaries),
                      icon: const Icon(Icons.refresh),
                      label: const Text('ลองใหม่'),
                    ),
                  ],
                ),
              ),
            );
          }

          final diaries = snapshot.data ?? [];
          if (diaries.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.cloud_queue, size: 80),
                  SizedBox(height: 16),
                  Text('ยังไม่มีบันทึกออนไลน์', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('กดปุ่ม + เพื่อเพิ่มข้อมูลด้วย POST'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(_loadDiaries);
              await _diariesFuture;
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: diaries.length,
              itemBuilder: (context, index) {
                final obj = Map<String, dynamic>.from(diaries[index] as Map);
                final id = obj['id'] ?? obj['_id'];
                final title = obj['title']?.toString() ?? '';
                final content = obj['content']?.toString() ?? '';
                final mood = obj['mood']?.toString() ?? '';
                final date = obj['date']?.toString() ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: const CircleAvatar(child: Icon(Icons.cloud)),
                    title: Text(title.isEmpty ? 'ไม่มีชื่อเรื่อง' : title, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('$mood • $date\n$content', maxLines: 3, overflow: TextOverflow.ellipsis),
                    isThreeLine: true,
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'แก้ไข',
                          icon: const Icon(Icons.edit),
                          onPressed: id == null ? null : () async {
                            final result = await Navigator.push<Map<String, dynamic>>(
                              context,
                              MaterialPageRoute(builder: (_) => ApiFormPage(existing: obj)),
                            );
                            if (result != null) {
                              await _updateDiary(_getId(id), result['title'], result['content'], result['mood'], result['date']);
                            }
                          },
                        ),
                        IconButton(
                          tooltip: 'ลบ',
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: id == null ? null : () => _deleteDiary(_getId(id)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push<Map<String, dynamic>>(
            context,
            MaterialPageRoute(builder: (_) => const ApiFormPage()),
          );
          if (result != null) {
            await _addDiary(result['title'], result['content'], result['mood'], result['date']);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มออนไลน์'),
      ),
    );
  }
}

// =====================================================
// REST API FORM PAGE
// =====================================================

class ApiFormPage extends StatefulWidget {
  final Map<String, dynamic>? existing;

  const ApiFormPage({super.key, this.existing});

  @override
  State<ApiFormPage> createState() => _ApiFormPageState();
}

class _ApiFormPageState extends State<ApiFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();

  String _mood = 'มีความสุข';
  final List<String> _moods = ['มีความสุข', 'เฉยๆ', 'เศร้า', 'เหนื่อย', 'ตื่นเต้น'];
  DateTime _date = DateTime.now();

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _titleController.text = existing['title']?.toString() ?? '';
      _contentController.text = existing['content']?.toString() ?? '';
      final mood = existing['mood']?.toString();
      if (mood != null && _moods.contains(mood)) _mood = mood;
      _date = DateTime.tryParse(existing['date']?.toString() ?? '') ?? DateTime.now();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String get _dateText => '${_date.year.toString().padLeft(4, '0')}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}';

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _date = picked);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, <String, dynamic>{
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'mood': _mood,
      'date': _dateText,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'แก้ไขบันทึกออนไลน์' : 'เพิ่มบันทึกออนไลน์')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'ชื่อเรื่อง', border: OutlineInputBorder(), prefixIcon: Icon(Icons.title)),
              validator: (value) => value == null || value.trim().isEmpty ? 'กรุณากรอกชื่อเรื่อง' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _contentController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'เนื้อหา', border: OutlineInputBorder(), prefixIcon: Icon(Icons.notes)),
              validator: (value) => value == null || value.trim().isEmpty ? 'กรุณากรอกเนื้อหา' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _mood,
              decoration: const InputDecoration(labelText: 'อารมณ์', border: OutlineInputBorder(), prefixIcon: Icon(Icons.mood)),
              items: _moods.map((mood) => DropdownMenuItem(value: mood, child: Text(mood))).toList(),
              onChanged: (value) { if (value != null) setState(() => _mood = value); },
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('วันที่'),
                subtitle: Text(_dateText),
                trailing: const Icon(Icons.edit_calendar),
                onTap: _selectDate,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _save,
                icon: Icon(_isEdit ? Icons.save : Icons.cloud_upload),
                label: Text(_isEdit ? 'บันทึกการแก้ไข' : 'เพิ่มข้อมูล'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

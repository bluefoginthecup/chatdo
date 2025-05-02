import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../widgets/routine_edit_form.dart';
import '../services/routine_service.dart';
import '../models/routine_model.dart';

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({Key? key}) : super(key: key);

  @override
  _RoutineListScreenState createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  String? _editingRoutineId; // 지금 수정중인 루틴 ID

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('루틴 관리'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('daily_routines')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
    print('✅ 루틴 스냅샷 상태: hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, connectionState=${snapshot.connectionState}');
    if (snapshot.hasError) {
    print('❌ 루틴 Stream 에러 발생: ${snapshot.error}');
    return Center(child: Text('에러 발생: ${snapshot.error}'));
    }
    if (!snapshot.hasData) {
    return const Center(child: CircularProgressIndicator());
    }

    final docs = snapshot.data!.docs;

    if (docs.isEmpty) {
    return const Center(child: Text('등록된 루틴이 없습니다.'));
    }
    return ListView.builder(
    itemCount: docs.length,
    itemBuilder: (context, index) {
    final data = docs[index].data();
    final docId = docs[index].id;
    final title = data['title'] ?? '';
    final days = data['days'] ?? {};

    return Column(
    children: [
    ListTile(
    title: Text(title),
    subtitle: Text(days.keys.join(', ')),
    trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
    IconButton(
    icon: const Icon(Icons.edit),
    onPressed: () {
    setState(() {
    if (_editingRoutineId == docId) {
    _editingRoutineId = null;
    } else {
    _editingRoutineId = docId;
    }
    });
    },
    ),
    IconButton(
    icon: const Icon(Icons.delete),
    onPressed: () async {
    final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
    title: const Text('삭제 확인'),
    content: const Text('정말 이 루틴을 삭제할까요?'),
    actions: [
    TextButton(
    onPressed: () => Navigator.pop(context, false),
    child: const Text('취소'),
    ),
    TextButton(
    onPressed: () => Navigator.pop(context, true),
    child: const Text('삭제'),
    ),
    ],
    ),
    );
    if (confirm == true) {
    await FirebaseFirestore.instance
        .collection('daily_routines')
        .doc(docId)
        .delete();
    }
    },
    ),
    ],
    ),
    ),
    if (_editingRoutineId == docId)
    Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: RoutineEditForm(
    initialDays: Map<String, String>.from(days),
    onSave: (newDays) async {
    final updatedRoutine = Routine(
    docId: docId,
    title: title,
    days: newDays,
    userId: uid,
    createdAt: DateTime.now(),
    );
    await RoutineService.updateRoutine(updatedRoutine);
    setState(() {
    _editingRoutineId = null;
    });
    },
    ),
    ),
    ],
    );
    }, // ← 요기!! itemBuilder의 닫는 중괄호
    );
    },),);}}
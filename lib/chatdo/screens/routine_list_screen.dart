import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; //
import '../data/firestore/repos/routine_repo.dart'; // ✅ RoutineRepo
import '../models/routine_model.dart';
import '../widgets/routine_edit_form.dart';

class RoutineListScreen extends StatefulWidget {
  const RoutineListScreen({Key? key}) : super(key: key);

  @override
  _RoutineListScreenState createState() => _RoutineListScreenState();
}

class _RoutineListScreenState extends State<RoutineListScreen> {
  String? _editingRoutineId;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('로그인이 필요합니다')),
      );
    }

    // ✅ 변수 선언은 return 전에
    final routineRepo = context.watch<RoutineRepo>();

    return Scaffold(
      appBar: AppBar(title: const Text('루틴 관리')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: routineRepo.watch(uid), // ✅ repo 스트림 사용
        builder: (context, snapshot) {
          // 디버깅 로그
          // print('✅ 루틴 스냅샷 상태: hasData=${snapshot.hasData}, hasError=${snapshot.hasError}, connectionState=${snapshot.connectionState}');
          if (snapshot.hasError) {
            // print('❌ 루틴 Stream 에러 발생: ${snapshot.error}');
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
              final doc = docs[index];
              final data = doc.data();
              final docId = doc.id;
              final title = (data['title'] ?? '').toString();
              final days = Map<String, String>.from(data['days'] ?? <String, String>{});

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
                              _editingRoutineId = (_editingRoutineId == docId) ? null : docId;
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
                              await context.read<RoutineRepo>().remove(uid, docId); // ✅ repo 삭제
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
                        initialDays: days,
                        onSave: (newDays) async {
                          // ✅ RoutineService 말고 repo로 업데이트
                          final updated = Routine(
                            docId: docId,
                            title: title,
                            days: Map<String, String>.from(newDays),
                            userId: uid,
                            createdAt: DateTime.now(),
                          );
                          await context.read<RoutineRepo>().addOrUpdate(uid, updated);
                          setState(() {
                            _editingRoutineId = null;
                          });
                        },
                      ),
                    ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/user_tag.dart';
import '../../data/firestore/paths.dart';
import 'package:provider/provider.dart';

class TagSelector extends StatefulWidget {
  final List<String>? initialSelectedTags;
  final void Function(List<String> selectedTags)? onTagChanged;

  const TagSelector({super.key, required this.initialSelectedTags, this.onTagChanged});

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;

  final List<UserTag> _tags = [
    UserTag(name: '운동'),
    UserTag(name: '건강'),
    UserTag(name: '스페인어'),
    UserTag(name: '베이킹'),
    UserTag(name: '방석재고'),
    UserTag(name: '세금'),
    UserTag(name: '영수증'),
    UserTag(name: '매장관리'),
    UserTag(name: '재고채우기'),
    UserTag(name: '자수'),
    UserTag(name: '챗두'),
    UserTag(name: '언젠가'),
    UserTag(name: '기타'),
  ];
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _opacityAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _selectedTags = List.from(widget.initialSelectedTags ?? []);
    _loadCustomTagsFromFirestore();
  }

  Future<void> _loadCustomTagsFromFirestore() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // ✅ 직접 경로 생성 금지. Provider로 주입된 paths 사용.
        final store = context.read<UserStorePaths>();
        final snapshot = await store.customTags(uid).get();


    setState(() {
      for (final doc in snapshot.docs) {
              final tag = UserTag.fromFirestore(doc.id, doc.data());
              final exists = _tags.any(
                (t) => t.name.toLowerCase() == tag.name.toLowerCase(),
              );
              if (!exists) _tags.add(tag);
            }
    });
  }

  void _toggleMenu() {
    if (_isMenuOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final Offset position = button.localToGlobal(Offset.zero);

    final chunks = List.generate(3, (_) => <UserTag>[]);
    for (var i = 0; i < _tags.length; i++) {
      chunks[i % 3].add(_tags[i]);
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
        child: Stack(
          children: [
            Positioned(
              left: MediaQuery.of(context).size.width / 2 - 120,
              bottom: MediaQuery.of(context).size.height - position.dy + 8,
              child: Material(
                color: Colors.transparent,
                child: FadeTransition(
                  opacity: _opacityAnimation,
                  child: SlideTransition(
                    position: _offsetAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...chunks.map((row) => Row(
                            children: row.map((tag) {
                              final isSelected = _selectedTags.contains(tag.name);
                              return Padding(
                                padding: const EdgeInsets.all(2),
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (isSelected) {
                                        _selectedTags.remove(tag.name);
                                      } else {
                                        _selectedTags.add(tag.name);
                                      }
                                      widget.onTagChanged?.call(List.from(_selectedTags));
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isSelected ? Colors.orangeAccent : Colors.grey[200],
                                    foregroundColor: Colors.black,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    minimumSize: Size.zero,
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    textStyle: const TextStyle(fontSize: 12),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  child: Text(tag.name),
                                ),
                              );
                            }).toList(),
                          )),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: _removeOverlay,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              textStyle: const TextStyle(fontSize: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('완료'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

    Overlay.of(context, debugRequiredFor: widget).insert(_overlayEntry!);
    _controller.forward();
    _isMenuOpen = true;
  }

  void _removeOverlay() async {
    if (_isMenuOpen) {
      await _controller.reverse();
      _overlayEntry?.remove();
      _overlayEntry = null;
      _isMenuOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: _toggleMenu,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        minimumSize: const Size(80, 40),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 14),
      ),
      child: const Text('+태그'),
    );
  }
}

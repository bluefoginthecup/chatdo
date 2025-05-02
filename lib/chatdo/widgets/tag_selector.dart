import 'package:flutter/material.dart';

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

  final List<String> _tags = [
    '운동', '건강', '스페인어', '베이킹', '방석재고', '세금',
    '영수증', '매장관리', '재고채우기', '자수', '챗두', '언젠가', '기타'
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
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    _opacityAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _selectedTags = List.from(widget.initialSelectedTags ?? []);
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
  }

  List<List<String>> _splitTags(List<String> tags, int chunkCount) {
    final chunks = List.generate(chunkCount, (_) => <String>[]);
    for (var i = 0; i < tags.length; i++) {
      chunks[i % chunkCount].add(tags[i]);
    }
    return chunks;
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

    final List<List<String>> tagRows = _splitTags(_tags, 3);

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
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),

                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          ...tagRows.map((row) => Row(

                            children: row.map((tag) => Padding(

                              padding: const EdgeInsets.symmetric(horizontal: 1, vertical: 1),
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    if (_selectedTags.contains(tag)) {
                                      _selectedTags.remove(tag);
                                    } else {
                                      _selectedTags.add(tag);
                                    }
                                    widget.onTagChanged?.call(List.from(_selectedTags));
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                 backgroundColor: Colors.amber[100],
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
                                child: Text(tag),
                              ),
                            )).toList(),
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
      ),
      child: const Text('+태그'),
    );
  }
}

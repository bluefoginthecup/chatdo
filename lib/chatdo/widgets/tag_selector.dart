import 'package:flutter/material.dart';

class TagSelector extends StatefulWidget {
  final void Function(String tag) onTagSelected;

  const TagSelector({super.key, required this.onTagSelected});

  @override
  State<TagSelector> createState() => _TagSelectorState();
}

class _TagSelectorState extends State<TagSelector> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;

  final List<String> _tags = ['운동', '공부', '일', '건강', '기타'];

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
  }

  @override
  void dispose() {
    _controller.dispose();
    _removeOverlay();
    super.dispose();
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
    final Size size = button.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay, // 바깥 터치하면 닫힘
        child: Stack(
          children: [
            Positioned(
              left: position.dx,
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 8,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: _tags.map((tag) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Colors.teal),
                            ),
                            onPressed: () {
                              widget.onTagSelected(tag);
                              _removeOverlay();
                            },
                            child: Text(tag),
                          ),
                        )).toList(),
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
    return GestureDetector(
      onTap: _toggleMenu,
      onDoubleTap: _removeOverlay,
      child: OutlinedButton(
        onPressed: _toggleMenu,
        child: const Text('태그'),
      ),
    );
  }
}

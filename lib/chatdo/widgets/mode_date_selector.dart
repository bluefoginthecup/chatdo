// updated ModeDateSelector with inline weekday expansion (cleaned)
import 'package:flutter/material.dart';
import '../models/enums.dart';

class ModeDateSelector extends StatefulWidget {
  final Mode selectedMode;
  final DateTime selectedDate;
  final void Function(Mode mode)? onModeChanged;
  final void Function(DateTime date)? onDateSelected;

  const ModeDateSelector({
    super.key,
    required this.selectedMode,
    required this.selectedDate,
    this.onModeChanged,
    this.onDateSelected,
  });

  @override
  State<ModeDateSelector> createState() => _ModeDateSelectorState();
}

class _ModeDateSelectorState extends State<ModeDateSelector> with SingleTickerProviderStateMixin {
  OverlayEntry? _overlayEntry;
  bool _isMenuOpen = false;
  bool _showWeekdays = false;
  late final AnimationController _controller;
  late final Animation<Offset> _offsetAnimation;
  late final Animation<double> _opacityAnimation;

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

    final now = DateTime.now();
    final List<MapEntry<String, DateTime?>> options = [
      MapEntry('오늘', DateTime(now.year, now.month, now.day)),
      MapEntry(widget.selectedMode == Mode.todo ? '내일' : '어제',
          widget.selectedMode == Mode.todo
              ? DateTime(now.year, now.month, now.day + 1)
              : DateTime(now.year, now.month, now.day - 1)),
      MapEntry('언젠가', null),
      MapEntry('이번주', null),
      MapEntry('날짜선택', DateTime(9999)),
    ];

    _overlayEntry = OverlayEntry(
      builder: (context) => GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _removeOverlay,
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
                  padding: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),

                  ),
                  child: StatefulBuilder(
                    builder: (context, setOverlayState) => Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 4,
                          runSpacing: 2,
                          children: options.map((entry) {
                            if (entry.key == '이번주') {
                              return ChoiceChip(
                                padding: EdgeInsets.zero,
                                labelPadding: EdgeInsets.symmetric(horizontal: 6),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                label: const Text('이번주'),
                                selected: _showWeekdays,
                                labelStyle: TextStyle(
                                  color: _showWeekdays ? Colors.black : Colors.black,
                                ),
                                onSelected: (_) {
                                  setOverlayState(() => _showWeekdays = !_showWeekdays);
                                },
                              );
                            } else {
                              return _buildDateChip(entry.key, entry.value);
                            }
                          }).toList(),
                        ),
                        if (_showWeekdays)
                          Padding(
                            padding: const EdgeInsets.only(top: 1),
                            child: Wrap(
                              spacing: 8,
                              children: List.generate(7, (i) {
                                final label = ['월', '화', '수', '목', '금', '토', '일'][i];
                                final now = DateTime.now();
                                final target = now.subtract(Duration(days: now.weekday - (i + 1)));
                                return ChoiceChip(
                                  padding: EdgeInsets.zero,
                                  labelPadding: EdgeInsets.symmetric(horizontal: 6),
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  visualDensity: VisualDensity.compact,
                                  label: Text(label),
                                  selected: widget.selectedDate.year == target.year &&
                                      widget.selectedDate.month == target.month &&
                                      widget.selectedDate.day == target.day,
                                  onSelected: (_) {
                                    print('[LOG] 요일 선택: $label → $target');
                                    widget.onDateSelected?.call(target);
                                    _removeOverlay();
                                  },
                                );
                              }),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          )
          ),],
        ),
      ),
    );

    Overlay.of(context, debugRequiredFor: widget).insert(_overlayEntry!);
    _controller.forward();
    _isMenuOpen = true;
  }

  void _removeOverlay() async {
    print('[LOG] _removeOverlay called');
    if (_isMenuOpen) {
      await _controller.reverse();
      _overlayEntry?.remove();
      _overlayEntry = null;
      setState(() {
        _isMenuOpen = false;
        _showWeekdays = false;
      });
    }
  }

  Widget _buildDateChip(String label, DateTime? date) {
    return ChoiceChip(
      padding: EdgeInsets.zero,
      labelPadding: EdgeInsets.symmetric(horizontal: 6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
      label: Text(label),
      selected: date != null &&
          widget.selectedDate.year == date.year &&
          widget.selectedDate.month == date.month &&
          widget.selectedDate.day == date.day,
      onSelected: (_) async {
        print('[LOG] _buildDateChip selected: $label');

        if (label == '날짜선택') {
          print('[LOG] 날짜 선택 진입');
          final picked = await showDatePicker(
            context: context,
            initialDate: DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2100),
          );
          if (picked != null) {
            print('[LOG] 날짜 선택됨: $picked');
            widget.onDateSelected?.call(picked);
          }
        } else if (date != null) {
          print('[LOG] 날짜 직접 지정: $date');
          widget.onDateSelected?.call(date);
        } else {
          print('[LOG] 특별 태그 선택됨 (예: 언젠가)');
          widget.onDateSelected?.call(DateTime(9999));
        }

        _removeOverlay();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: () {
            final newMode = widget.selectedMode == Mode.todo ? Mode.done : Mode.todo;
            widget.onModeChanged?.call(newMode);
          },
          child: Text(
            widget.selectedMode == Mode.todo ? '할일' : '한일',
            style: TextStyle(
              color: widget.selectedMode == Mode.todo ? Colors.teal : Colors.orange,
            ),
          ),
        ),
        const SizedBox(width: 12),
        OutlinedButton(
          onPressed: _toggleMenu,
          child: Text('${widget.selectedDate.year}-${widget.selectedDate.month.toString().padLeft(2, '0')}-${widget.selectedDate.day.toString().padLeft(2, '0')}'),
        ),

      ],
    );
  }
}

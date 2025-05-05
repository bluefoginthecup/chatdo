// schedule_entry_tile.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import '../models/schedule_entry.dart';
import '../screens/schedule_detail_screen.dart';
import '../../game/core/game_controller.dart';
import '../utils/schedule_actions.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ScheduleEntryTile extends StatefulWidget {
  final ScheduleEntry entry;
  final GameController gameController;
  final Future<void> Function() onRefresh;


  const ScheduleEntryTile({
    Key? key,
    required this.entry,
    required this.gameController,
    required this.onRefresh,
  }) : super(key: key);

  @override
  State<ScheduleEntryTile> createState() => _ScheduleEntryTileState();
}

class _ScheduleEntryTileState extends State<ScheduleEntryTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  bool _isTapped = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.9,
      upperBound: 1.0,
    );
    _scaleAnim = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _onIconTap() async {
    HapticFeedback.lightImpact();
    setState(() => _isTapped = true);
    await _controller.reverse();
    await Future.delayed(const Duration(milliseconds: 80));

    if (!mounted) return;

    await markAsOtherType(
      docId: widget.entry.docId!,
      currentMode: widget.entry.type.name,
      gameController: widget.gameController,
      currentDate: widget.entry.date,
      onRefresh: widget.onRefresh,
      context: context,
    );

    if (!mounted) return;

    await widget.onRefresh();
    setState(() => _isTapped = true);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final isDone = entry.type == ScheduleType.done;
    final dateStr = DateFormat('yyyy-MM-dd').format(entry.date);

    return ListTile(
      leading: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ScaleTransition(
            scale: _scaleAnim,
            child: GestureDetector(
              onTap: _onIconTap,
              child: Icon(
                _isTapped
                    ? Icons.check_circle
                    : (isDone ? Icons.check_circle_outline : Icons.circle_outlined),
                color: _isTapped
                    ? Colors.greenAccent
                    : (isDone ? Colors.grey : Colors.red),
                size: 28,
              )

            ),
          ),
          const SizedBox(width: 8),
          if (entry.imageUrls != null && entry.imageUrls!.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedNetworkImage(
                imageUrl: entry.imageUrls!.first,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                placeholder: (context, url) => const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),

        ],
      ),
      title: Row(
        children: [
          ...entry.tags.map((tag) => Padding(
            padding: const EdgeInsets.only(right: 4.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.orange[100],
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                tag,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          )),
          Expanded(
            child: Text(
              entry.content,
              style: TextStyle(
                color: isDone ? Colors.grey : Colors.red,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          )
        ],
      ),
      subtitle: Text(
        dateStr,
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
      onTap: () {
        Navigator.of(context)
            .push(
          MaterialPageRoute(
            builder: (_) => ScheduleDetailScreen(
              entry: entry,
              gameController: widget.gameController,
              onUpdate: widget.onRefresh,
            ),
          ),
        )
            .then((_) => widget.onRefresh());
      },
    );
  }
}

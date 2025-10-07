// lib/features/stock/stock_gate.dart
import 'package:chatdo/chatdo/features/stock/screens/stock_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:chatdo/chatdo/features/stock/stock.dart';

class StockGate extends StatefulWidget {
  const StockGate({required this.uid, this.child, super.key});
  final String uid;
  final Widget? child;

  @override
  State<StockGate> createState() => _StockGateState();
}

class _StockGateState extends State<StockGate> {
  late final Future<StockLayer> _boot = StockLayer.init(uid: widget.uid);
  bool _syncStarted = false;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<StockLayer>(
      future: _boot,
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(body: Center(child: Text('Stock init error: ${snap.error}')));
        }
        if (!snap.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final stock = snap.data!;
        // 자동 동기화 시작은 빌드 직후 "1회만" 호출
                if (!_syncStarted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || _syncStarted) return;
                    stock.sync.start();
                    _syncStarted = true;
                  });
                }

        return widget.child ?? StockListScreen(repo: stock.repo, sync: stock.sync);

      },
    );
  }

  @override
  void dispose() {
    _boot.then((s) => s.sync.stop()).catchError((_) {});
    super.dispose();
  }
}

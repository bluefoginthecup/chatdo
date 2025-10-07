// lib/features/stock/stock_gate.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/tab_nav.dart';
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
        stock.sync.start(); // 자동 동기화 시작 (로그인 후 1회)

        return MultiProvider(
          providers: [
            Provider<StockRepo>.value(value: stock.repo),
            Provider<StockSyncService>.value(value: stock.sync),
          ],
          child: widget.child ?? const TabNav(),
        );
      },
    );
  }

  @override
  void dispose() {
    _boot.then((s) => s.sync.stop()).catchError((_) {});
    super.dispose();
  }
}

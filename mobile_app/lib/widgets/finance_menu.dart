import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../screens/earnings_screen.dart';
import '../screens/wallet_screen.dart';

class FinanceMenu extends StatelessWidget {
  const FinanceMenu({super.key, required this.api, this.worker = false});
  final ApiService api;
  final bool worker;
  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    tooltip: 'Thu nhập & Ví',
    icon: const Icon(Icons.account_balance_wallet_outlined),
    onSelected: (value) => Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => value == 'income'
            ? EarningsScreen(api: api)
            : WalletScreen(api: api),
      ),
    ),
    itemBuilder: (_) => [
      if (worker)
        const PopupMenuItem(
          value: 'income',
          child: ListTile(
            leading: Icon(Icons.bar_chart_rounded),
            title: Text('Thu nhập'),
          ),
        ),
      const PopupMenuItem(
        value: 'wallet',
        child: ListTile(
          leading: Icon(Icons.account_balance_wallet_outlined),
          title: Text('Ví điện tử'),
        ),
      ),
    ],
  );
}

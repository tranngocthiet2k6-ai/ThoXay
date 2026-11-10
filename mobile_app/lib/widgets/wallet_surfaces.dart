import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/wallet.dart';
import '../theme/app_theme.dart';
import 'bouncing_button.dart';

class WalletCompartments extends StatelessWidget {
  const WalletCompartments({
    super.key,
    required this.balance,
    required this.hidden,
  });
  final WalletBalance balance;
  final bool hidden;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      for (final item in [
        (
          label: 'Khả dụng',
          value: balance.main,
          icon: Icons.account_balance_wallet_outlined,
        ),
        (label: 'Ký quỹ', value: balance.escrow, icon: Icons.shield_outlined),
        (
          label: 'Giữ chỗ',
          value: balance.held,
          icon: Icons.lock_clock_outlined,
        ),
      ])
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                children: [
                  Icon(item.icon, size: 18, color: Colors.white70),
                  const SizedBox(height: 6),
                  Text(
                    item.label,
                    style: const TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      hidden ? '••••••' : money(item.value.toDouble()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class WalletTransactionTile extends StatelessWidget {
  const WalletTransactionTile({super.key, required this.entry});
  final WalletEntry entry;
  String _time(BuildContext context) {
    final local = entry.createdAt.toLocal();
    return '${MaterialLocalizations.of(context).formatShortDate(local)} · ${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final sign = walletEntrySign(entry.kind);
    final locked =
        entry.kind.contains('ESCROW') ||
        entry.kind.contains('HOLD') ||
        entry.kind.contains('LOCK');
    final color = locked
        ? palette.warning
        : sign == '− '
        ? palette.errorStrong
        : sign == '+ '
        ? palette.successStrong
        : palette.warning;
    return BouncingButton(
      child: Card(
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          onTap: () => showDialog<void>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(walletKind(entry.kind)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$sign${money(entry.amount.toDouble())}',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(entry.description),
                  const SizedBox(height: 8),
                  Text(_time(context)),
                  const SizedBox(height: 8),
                  SelectableText('Mã tham chiếu: #${entry.id}'),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Đóng'),
                ),
              ],
            ),
          ),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: .10),
            child: Icon(
              locked
                  ? Icons.shield_outlined
                  : sign == '+ '
                  ? Icons.south_west
                  : Icons.north_east,
              color: color,
            ),
          ),
          title: Text(
            walletKind(entry.kind),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            '${entry.description}\n${_time(context)} · #${entry.id}',
            style: TextStyle(fontSize: 11, color: palette.muted),
          ),
          isThreeLine: true,
          trailing: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 110),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '$sign${money(entry.amount.toDouble())}',
                style: TextStyle(fontWeight: FontWeight.w800, color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

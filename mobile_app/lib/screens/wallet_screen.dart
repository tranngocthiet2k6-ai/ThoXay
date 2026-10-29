import '../widgets/content_skeleton.dart';
import '../widgets/app_snack_bar.dart';
import '../theme/app_theme.dart';

import 'package:flutter/material.dart';

import '../models/wallet.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../widgets/empty_state.dart';
import '../widgets/wallet_operation_dialog.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key, required this.api});
  final ApiService api;
  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  WalletBalance? _balance;
  final _entries = <WalletEntry>[];
  final _requests = <WalletRequest>[];
  bool _busy = false, _entryMore = false, _requestMore = false;
  bool _hideBalance = false;
  int _tab = 0;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!more) {
        final b = await widget.api.wallet();
        if (mounted) setState(() => _balance = b);
      }
      if (!more || _tab == 0) {
        final page = await widget.api.walletEntries(
          beforeId: more && _entries.isNotEmpty ? _entries.last.id : null,
        );
        if (mounted) {
          setState(() {
            if (!more) _entries.clear();
            _entries.addAll(page.items);
            _entryMore = page.hasMore;
          });
        }
      }
      if (!more || _tab == 1) {
        final page = await widget.api.walletRequests(
          beforeId: more && _requests.isNotEmpty ? _requests.last.id : null,
        );
        if (mounted) {
          setState(() {
            if (!more) _requests.clear();
            _requests.addAll(page.items);
            _requestMore = page.hasMore;
          });
        }
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _operate(String kind) async {
    if (_busy || _balance == null) return;
    final done = await showWalletOperation(
      context,
      widget.api,
      kind,
      kind == 'RELEASE' ? _balance!.escrow : _balance!.main,
    );
    if (!mounted) return;
    if (done == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppSnackBar(
          content: Text(
            kind == 'TOP_UP' || kind == 'WITHDRAW'
                ? 'Đã gửi yêu cầu chờ đối soát.'
                : 'Đã chuyển tiền ký quỹ.',
          ),
        ),
      );
    }
    await _load();
  }

  Widget _smallBalance(String title, int amount, IconData icon) => Expanded(
    child: Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 8),
            Text(title),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _hideBalance ? '••••••' : money(amount.toDouble()),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Ví điện tử'),
      actions: [
        IconButton(
          tooltip: 'Làm mới ví',
          onPressed: _busy ? null : () => _load(),
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: () => _load(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          if (_busy && _balance == null) const ContentSkeleton(compact: true),
          if (_error != null) ...[
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton(
              onPressed: _busy ? null : () => _load(),
              child: const Text('Thử lại'),
            ),
          ],
          if (_balance case final balance?) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: AppTheme.brandGradient(context),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'THOXAY · VÍ CỦA BẠN',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: _hideBalance ? 'Hiện số dư' : 'Ẩn số dư',
                        onPressed: () =>
                            setState(() => _hideBalance = !_hideBalance),
                        icon: Icon(
                          _hideBalance
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Số dư khả dụng',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _hideBalance ? '••••••' : money(balance.main.toDouble()),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _smallBalance('Ký quỹ', balance.escrow, Icons.shield_outlined),
                const SizedBox(width: 8),
                _smallBalance(
                  'Đang giữ rút',
                  balance.held,
                  Icons.hourglass_top,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Semantics(
                label: 'Mức ký quỹ so với ngưỡng cảnh báo',
                child: LinearProgressIndicator(
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  value: balance.minimum <= 0
                      ? 1
                      : (balance.escrow / balance.minimum).clamp(0.0, 1.0),
                  color: balance.lowEscrow
                      ? const Color(0xffb45309)
                      : const Color(0xff047857),
                ),
              ),
            ),
            if (balance.lowEscrow)
              Card(
                color: const Color(0xfffff1d8),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Ký quỹ thấp hơn ${money(balance.minimum.toDouble())}. Bạn có thể chuyển thêm từ số dư chính. Đây là cảnh báo, chưa chặn nhận việc.',
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy ? null : () => _operate('TOP_UP'),
                    icon: const Icon(Icons.add),
                    label: const Text('Nạp tiền'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _busy || balance.main < 1000
                        ? null
                        : () => _operate('WITHDRAW'),
                    icon: const Icon(Icons.north_east),
                    label: const Text('Rút nhanh'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                OutlinedButton.icon(
                  onPressed: _busy || balance.main < 1000
                      ? null
                      : () => _operate('LOCK'),
                  icon: const Icon(Icons.shield_outlined),
                  label: const Text('Nạp ký quỹ'),
                ),
                OutlinedButton.icon(
                  onPressed: _busy || balance.escrow < 1000
                      ? null
                      : () => _operate('RELEASE'),
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Hoàn ký quỹ'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nạp/rút được quản trị viên đối soát thủ công. Tiền đang giữ rút không nằm trong số dư khả dụng. Chưa tích hợp chuyển tiền ngân hàng tự động.',
              style: TextStyle(color: Colors.blueGrey, height: 1.5),
            ),
          ],
          const SizedBox(height: 24),
          SegmentedButton<int>(
            segments: const [
              ButtonSegment(value: 0, label: Text('Giao dịch')),
              ButtonSegment(value: 1, label: Text('Yêu cầu')),
            ],
            selected: {_tab},
            onSelectionChanged: (s) => setState(() => _tab = s.first),
          ),
          const SizedBox(height: 16),
          if (_tab == 0) ...[
            if (!_busy && _error == null && _entries.isEmpty)
              EmptyState(
                icon: Icons.receipt_long_outlined,
                action: OutlinedButton.icon(
                  onPressed: () => _load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra lại'),
                ),
                title: 'Chưa có giao dịch',
                message: 'Mọi biến động số dư sẽ được ghi lại tại đây.',
              ),
            for (final e in _entries)
              Card(
                child: ListTile(
                  isThreeLine: true,
                  leading: CircleAvatar(
                    backgroundColor: walletEntrySign(e.kind) == '− '
                        ? const Color(0xfffef2f2)
                        : walletEntrySign(e.kind) == '+ '
                        ? const Color(0xffecfdf5)
                        : const Color(0xfffffbeb),
                    child: Icon(
                      walletEntrySign(e.kind) == '− '
                          ? Icons.north_east
                          : walletEntrySign(e.kind) == '+ '
                          ? Icons.south_west
                          : Icons.swap_horiz,
                      color: walletEntrySign(e.kind) == '− '
                          ? const Color(0xffb91c1c)
                          : walletEntrySign(e.kind) == '+ '
                          ? const Color(0xff047857)
                          : const Color(0xffb45309),
                    ),
                  ),
                  title: Text(walletKind(e.kind)),
                  subtitle: Text(
                    '${e.description}\n${MaterialLocalizations.of(context).formatShortDate(e.createdAt.toLocal())}',
                  ),
                  trailing: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 125),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${walletEntrySign(e.kind)}${money(e.amount.toDouble())}',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: walletEntrySign(e.kind) == '− '
                              ? Colors.red.shade700
                              : walletEntrySign(e.kind) == '+ '
                              ? const Color(0xff047857)
                              : const Color(0xffb45309),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (_entryMore)
              TextButton(
                onPressed: _busy ? null : () => _load(more: true),
                child: const Text('Tải giao dịch cũ'),
              ),
          ] else ...[
            if (!_busy && _error == null && _requests.isEmpty)
              EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                action: OutlinedButton.icon(
                  onPressed: () => _load(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Kiểm tra lại'),
                ),
                title: 'Chưa có yêu cầu',
                message: 'Yêu cầu nạp và rút được theo dõi tại đây.',
              ),
            for (final r in _requests)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${walletKind(r.kind)} · ${money(r.amount.toDouble())}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        backgroundColor: r.status == 'APPROVED'
                            ? Colors.green.shade50
                            : r.status == 'REJECTED'
                            ? Colors.red.shade50
                            : Colors.amber.shade50,
                        label: Text(requestStatus(r.status)),
                      ),
                      if (r.note != null) Text(r.note!),
                      Text(
                        MaterialLocalizations.of(context)
                            .formatShortDate(r.createdAt.toLocal()),
                      ),
                    ],
                  ),
                ),
              ),
            if (_requestMore)
              TextButton(
                onPressed: _busy ? null : () => _load(more: true),
                child: const Text('Tải yêu cầu cũ'),
              ),
          ],
        ],
      ),
    ),
  );
}

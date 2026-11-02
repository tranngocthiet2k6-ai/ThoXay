import 'package:flutter/material.dart';

import '../models/models.dart';
import '../models/scheduling.dart';
import '../services/api_service.dart';
import '../widgets/commercial_hero.dart';
import '../widgets/content_skeleton.dart';
import '../widgets/design_motion.dart';
import '../widgets/figma_components.dart';

class CommitmentScreen extends StatefulWidget {
  const CommitmentScreen({
    super.key,
    required this.api,
    required this.applicationId,
  });
  final ApiService api;
  final int applicationId;
  @override
  State<CommitmentScreen> createState() => _CommitmentScreenState();
}

class _CommitmentScreenState extends State<CommitmentScreen> {
  late Future<CommitmentDocument> _future = widget.api.commitment(
    widget.applicationId,
  );
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Phiếu cam kết nhận việc')),
    body: ContentFrame(
      child: FutureBuilder<CommitmentDocument>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: TextButton.icon(
                onPressed: () => setState(
                  () => _future = widget.api.commitment(widget.applicationId),
                ),
                icon: const Icon(Icons.refresh),
                label: const Text('Chưa tải được cam kết. Thử lại'),
              ),
            );
          }
          if (!snapshot.hasData) return const ContentSkeleton();
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [CommitmentSummary(document: snapshot.data!)],
          );
        },
      ),
    ),
  );
}

class CommitmentSummary extends StatelessWidget {
  const CommitmentSummary({
    super.key,
    required this.document,
    this.compact = false,
  });
  final CommitmentDocument document;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final confirmed = document.bothConfirmed;
    Widget party(
      String role,
      String name,
      bool verified,
      DateTime? at,
    ) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          PresenceAvatar(name: name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xff64748b),
                  ),
                ),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w800)),
                if (at != null)
                  const Text(
                    'Đã xác nhận',
                    style: TextStyle(color: Color(0xff047857), fontSize: 11),
                  ),
              ],
            ),
          ),
          if (verified) const KycBadge(),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CommercialHero(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.description_outlined),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      document.applicationId == null
                          ? 'BẢN XEM TRƯỚC'
                          : 'CK-${document.applicationId.toString().padLeft(6, '0')}',
                      style: const TextStyle(
                        fontSize: 12,
                        letterSpacing: 1.4,
                        color: Colors.white70,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                '${money(document.selectedRate.toDouble())}/ngày',
                style: const TextStyle(
                  fontSize: 28,
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    confirmed ? Icons.verified_rounded : Icons.pending_outlined,
                    color: confirmed
                        ? const Color(0xff6ee7b7)
                        : const Color(0xfffcd34d),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      confirmed
                          ? 'Đã xác nhận bởi 2 bên'
                          : document.state == 'LEGACY'
                          ? 'Cam kết cũ chưa đủ dấu vết xác nhận'
                          : 'Đang chờ xác nhận đầy đủ',
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FigmaCard(
          child: Column(
            children: [
              party(
                'NGƯỜI THỢ',
                document.workerName,
                document.workerVerified,
                document.workerConfirmedAt,
              ),
              const Divider(),
              party(
                'CHỦ THẦU',
                document.contractorName,
                document.contractorVerified,
                document.contractorConfirmedAt,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FigmaCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.shield_outlined, color: Color(0xff059669)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Minh bạch tiền ký quỹ',
                      style: TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                '200.000đ là mức ký quỹ khuyến nghị của ví. Phiếu này chưa giữ hoặc bảo lãnh tiền cọc riêng cho công trình.',
                style: TextStyle(fontSize: 12, height: 1.6),
              ),
              const Divider(height: 24),
              const Row(
                children: [
                  Icon(Icons.info_outline, color: Color(0xffea580c)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Hủy việc đã nhận: −15 điểm uy tín',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Theo quy tắc server cho đơn ACCEPTED; không tự khấu trừ tiền phạt.',
                style: TextStyle(fontSize: 11, color: Color(0xff64748b)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ExpansionTile(
          title: Text('Toàn văn điều khoản · v${document.version}'),
          subtitle: const Text(
            'Đọc snapshot đã chốt và mã kiểm chứng',
            style: TextStyle(fontSize: 11),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                document.text,
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
            ),
            if (document.hash != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(
                  'SHA-256: ${document.hash}',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

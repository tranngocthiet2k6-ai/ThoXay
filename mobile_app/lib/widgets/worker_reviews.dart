import 'package:flutter/material.dart';

import '../models/reputation.dart';
import '../services/api_service.dart';

class WorkerReviews extends StatefulWidget {
  const WorkerReviews({super.key, required this.api, required this.workerId});
  final ApiService api;
  final int workerId;
  @override
  State<WorkerReviews> createState() => _WorkerReviewsState();
}

class _WorkerReviewsState extends State<WorkerReviews> {
  final _reviews = <WorkerReview>[];
  bool _loading = false, _more = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final page = await widget.api.workerReviews(
        widget.workerId,
        beforeId: more && _reviews.isNotEmpty ? _reviews.last.id : null,
      );
      if (mounted) {
        setState(() {
          if (!more) _reviews.clear();
          _reviews.addAll(page.items);
          _more = page.hasMore;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Đánh giá từ công trình',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) ...[
        Text(_error!),
        TextButton(
          onPressed: () => _load(),
          child: const Text('Thử lại đánh giá'),
        ),
      ],
      if (!_loading && _error == null && _reviews.isEmpty)
        const Text('Chưa có đánh giá.'),
      for (final review in _reviews)
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (var i = 1; i <= 5; i++)
                      Icon(
                        i <= review.stars ? Icons.star : Icons.star_outline,
                        size: 18,
                        color: const Color(0xffaa771c),
                      ),
                    const SizedBox(width: 8),
                    Text('${review.stars}/5'),
                  ],
                ),
                const SizedBox(height: 8),
                Text(review.jobTitle),
                Text('Chủ thầu: ${review.contractorName}'),
              ],
            ),
          ),
        ),
      if (_more)
        TextButton(
          onPressed: _loading ? null : () => _load(more: true),
          child: const Text('Xem đánh giá cũ'),
        ),
    ],
  );
}

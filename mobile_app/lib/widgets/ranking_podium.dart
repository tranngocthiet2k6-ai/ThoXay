import 'package:flutter/material.dart';

import '../models/reputation.dart';
import 'tier_badge.dart';

class RankingPodium extends StatelessWidget {
  const RankingPodium({super.key, required this.workers, required this.onTap});
  final List<WorkerRank> workers;
  final ValueChanged<WorkerRank> onTap;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (final index in [1, 0, 2])
          Expanded(
            child: index >= workers.length
                ? const SizedBox()
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Semantics(
                      label:
                          'Hạng ${workers[index].rank} ${workers[index].fullName}',
                      button: true,
                      child: InkWell(
                        onTap: () => onTap(workers[index]),
                        borderRadius: BorderRadius.circular(16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              index == 0
                                  ? Icons.emoji_events
                                  : Icons.workspace_premium_outlined,
                              color: index == 0
                                  ? const Color(0xffb45309)
                                  : const Color(0xff64748b),
                            ),
                            const SizedBox(height: 8),
                            CircleAvatar(
                              backgroundColor: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer,
                              child: Text(
                                '${workers[index].rank}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              workers[index].fullName,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: TierBadge(tier: workers[index].workerTier),
                            ),
                            Text(
                              '${workers[index].reputationScore}/100 uy tín',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 12),
                            ),
                            Text(
                              '★ ${workers[index].rating.toStringAsFixed(1)}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              key: ValueKey('podium-${workers[index].rank}'),
                              width: double.infinity,
                              height: index == 0
                                  ? 88
                                  : index == 1
                                  ? 64
                                  : 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? const Color(0xfffef3c7)
                                    : const Color(0xffe2e8f0),
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                              ),
                              child: Text(
                                '#${workers[index].rank}',
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
      ],
    ),
  );
}

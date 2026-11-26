import 'package:flutter/material.dart';

/// Gives job forms the phone's width and keeps actions outside the scroll area.
class JobFormDialog extends StatelessWidget {
  const JobFormDialog({
    super.key,
    required this.title,
    required this.content,
    required this.actions,
  });

  final Widget title;
  final Widget content;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Dialog(
    insetPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    constraints: const BoxConstraints(maxWidth: 640),
    clipBehavior: Clip.antiAlias,
    child: SizedBox(
      width: 640,
      child: LayoutBuilder(
        builder: (context, constraints) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Semantics(
                namesRoute: true,
                child: DefaultTextStyle(
                  style:
                      Theme.of(context).dialogTheme.titleTextStyle ??
                      Theme.of(context).textTheme.titleLarge!,
                  child: title,
                ),
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: content,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: constraints.maxWidth < 480 && constraints.maxHeight > 460
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (var i = actions.length - 1; i >= 0; i--) ...[
                          if (i < actions.length - 1) const SizedBox(height: 4),
                          actions[i],
                        ],
                      ],
                    )
                  : OverflowBar(
                      spacing: 12,
                      overflowSpacing: 4,
                      alignment: MainAxisAlignment.end,
                      children: actions,
                    ),
            ),
          ],
        ),
      ),
    ),
  );
}

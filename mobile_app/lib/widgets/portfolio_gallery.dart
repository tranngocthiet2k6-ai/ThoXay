import 'package:flutter/material.dart';

class PortfolioGallery extends StatelessWidget {
  const PortfolioGallery({super.key, required this.images});
  final List<String> images;
  Widget _image(String url, {BoxFit fit = BoxFit.cover}) => Image.network(
    url,
    fit: fit,
    loadingBuilder: (context, child, loading) => loading == null
        ? child
        : const Center(child: CircularProgressIndicator(strokeWidth: 2)),
    errorBuilder: (_, error, stack) =>
        const Center(child: Icon(Icons.broken_image_outlined)),
  );
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('Ảnh dự án cá nhân', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 12),
      if (images.isEmpty)
        const Text(
          'Chưa có ảnh dự án. Thêm ảnh để giới thiệu công việc bạn đã thực hiện.',
        ),
      if (images.isNotEmpty)
        LayoutBuilder(
          builder: (context, constraints) => Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (var i = 0; i < images.length; i++)
                SizedBox(
                  width: (constraints.maxWidth - 20) / 3,
                  height: 105,
                  child: Material(
                    color: const Color(0xffeaf2ed),
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (context) => Dialog(
                          child: SizedBox(
                            height: MediaQuery.sizeOf(context).height * .7,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.all(16),
                                        child: Text('Ảnh dự án ${i + 1}'),
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Đóng ảnh',
                                      onPressed: () => Navigator.pop(context),
                                      icon: const Icon(Icons.close),
                                    ),
                                  ],
                                ),
                                Expanded(
                                  child: InteractiveViewer(
                                    child: _image(
                                      images[i],
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      child: Semantics(
                        label: 'Xem ảnh dự án ${i + 1}',
                        button: true,
                        child: _image(images[i]),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
    ],
  );
}

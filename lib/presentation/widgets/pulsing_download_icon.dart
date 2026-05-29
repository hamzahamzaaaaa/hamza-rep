import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/download_provider.dart';

class PulsingDownloadIcon extends ConsumerStatefulWidget {
  final double? size;
  const PulsingDownloadIcon({super.key, this.size});

  @override
  ConsumerState<PulsingDownloadIcon> createState() => _PulsingDownloadIconState();
}

class _PulsingDownloadIconState extends ConsumerState<PulsingDownloadIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final downloadState = ref.watch(downloadProvider);
    final hasActiveDownloads = downloadState.items.values.any((item) => !item.isCompleted);

    if (!hasActiveDownloads) {
      return Icon(Icons.download_for_offline_outlined, size: widget.size);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Icon(
          Icons.file_download_outlined,
          color: const Color(0xFFFFE57F).withOpacity(0.5 + (_controller.value * 0.5)),
          size: widget.size ?? 24,
        );
      },
    );
  }
}

import 'package:flutter/material.dart';
import '../core/constants/colors.dart';

/// ============================================================================
/// ENHANCED DOWNLOAD STATUS WIDGET
/// ============================================================================
/// 
/// Shows download progress with:
/// - Cloud + Arrow merged icon
/// - Progress bar
/// - Download speed display
/// - Status indicators (Downloading, Completed, Paused)

class EnhancedDownloadStatus extends StatefulWidget {
  final double progress; // 0.0 to 1.0
  final String? speed; // e.g., "2.5 MB/s"
  final DownloadStatus status;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final String fileName;

  const EnhancedDownloadStatus({
    super.key,
    required this.progress,
    this.speed,
    required this.status,
    this.onTap,
    this.onCancel,
    required this.fileName,
  });

  @override
  State<EnhancedDownloadStatus> createState() => _EnhancedDownloadStatusState();
}

class _EnhancedDownloadStatusState extends State<EnhancedDownloadStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    if (widget.status == DownloadStatus.downloading) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EnhancedDownloadStatus oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.status != oldWidget.status) {
      if (widget.status == DownloadStatus.downloading) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _getStatusColor().withOpacity(0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _getStatusColor().withOpacity(0.1),
              blurRadius: 15,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // Cloud + Arrow Icon
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: _buildCloudArrowIcon(),
                );
              },
            ),
            const SizedBox(width: 12),

            // Progress Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // File name
                  Text(
                    widget.fileName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: widget.progress,
                      backgroundColor: Colors.white.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getStatusColor(),
                      ),
                      minHeight: 4,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Speed and percentage
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Status text
                      Text(
                        _getStatusText(),
                        style: TextStyle(
                          color: _getStatusColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),

                      // Speed display
                      if (widget.speed != null &&
                          widget.status == DownloadStatus.downloading)
                        Row(
                          children: [
                            Icon(
                              Icons.speed,
                              size: 12,
                              color: AppColors.gold.withOpacity(0.7),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.speed!,
                              style: TextStyle(
                                color: AppColors.gold.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                      // Percentage
                      Text(
                        '${(widget.progress * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Cancel button (only when downloading)
            if (widget.status == DownloadStatus.downloading &&
                widget.onCancel != null)
              IconButton(
                icon: const Icon(
                  Icons.close,
                  color: Colors.red,
                  size: 20,
                ),
                onPressed: widget.onCancel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudArrowIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cloud icon
        Icon(
          Icons.cloud_outlined,
          size: 32,
          color: _getStatusColor(),
        ),
        // Arrow overlay
        Transform.translate(
          offset: const Offset(0, 2),
          child: Icon(
            Icons.arrow_downward,
            size: 18,
            color: _getStatusColor().withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (widget.status) {
      case DownloadStatus.downloading:
        return AppColors.gold;
      case DownloadStatus.completed:
        return Colors.green;
      case DownloadStatus.paused:
        return Colors.orange;
      case DownloadStatus.error:
        return Colors.red;
    }
  }

  String _getStatusText() {
    switch (widget.status) {
      case DownloadStatus.downloading:
        return 'جاري التحميل...';
      case DownloadStatus.completed:
        return 'مكتمل ✓';
      case DownloadStatus.paused:
        return 'متوقف مؤقتاً';
      case DownloadStatus.error:
        return 'خطأ في التحميل';
    }
  }
}

enum DownloadStatus {
  downloading,
  completed,
  paused,
  error,
}

/// Download action menu item for 3-dot menu
class DownloadMenuItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final String? subtitle;

  const DownloadMenuItem({
    required this.icon,
    required this.label,
    this.color = Colors.white,
    required this.onTap,
    this.subtitle,
  });
}

/// Popup menu for completed downloads
class DownloadActionsMenu extends StatelessWidget {
  final List<DownloadMenuItem> actions;
  final String fileName;
  final bool isCompleted;

  const DownloadActionsMenu({
    super.key,
    required this.actions,
    required this.fileName,
    this.isCompleted = false,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DownloadMenuItem>(
      icon: Icon(
        Icons.more_vert,
        color: isCompleted ? Colors.green : AppColors.gold,
      ),
      onSelected: (item) => item.onTap(),
      itemBuilder: (context) => actions.map((action) {
        return PopupMenuItem<DownloadMenuItem>(
          value: action,
          child: Row(
            children: [
              Icon(action.icon, color: action.color, size: 20),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    action.label,
                    style: TextStyle(
                      color: action.color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (action.subtitle != null)
                    Text(
                      action.subtitle!,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

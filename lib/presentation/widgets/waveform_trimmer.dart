/// ============================================================================
/// WAVEFORM TRIMMING UI - Glassmorphism Audio Trimmer
/// ============================================================================
/// 
/// Features:
/// - Glassmorphism overlay background
/// - Audio waveform visualization
/// - Start/end time selection
/// - Real-time preview
/// - Precise trimming for verse clipping

import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';
import 'glassmorphism_theme.dart';

class WaveformTrimmer extends StatefulWidget {
  final Duration totalDuration;
  final Function(Duration start, Duration end) onTrimComplete;
  final String surahName;
  final int verseNumber;

  const WaveformTrimmer({
    super.key,
    required this.totalDuration,
    required this.onTrimComplete,
    required this.surahName,
    required this.verseNumber,
  });

  @override
  State<WaveformTrimmer> createState() => _WaveformTrimmerState();
}

class _WaveformTrimmerState extends State<WaveformTrimmer> {
  late double _startPosition;
  late double _endPosition;
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  Duration? _previewPosition;
  
  @override
  void initState() {
    super.initState();
    _startPosition = 0.0;
    _endPosition = 1.0;
  }

  Duration get _startTime => Duration(
    milliseconds: (widget.totalDuration.inMilliseconds * _startPosition).toInt(),
  );
  
  Duration get _endTime => Duration(
    milliseconds: (widget.totalDuration.inMilliseconds * _endPosition).toInt(),
  );
  
  Duration get _selectedDuration => _endTime - _startTime;

  @override
  Widget build(BuildContext context) {
    return GlassBottomSheet(
      child: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Title
            Text(
              '${widget.surahName} - الآية ${widget.verseNumber}',
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 24,
                color: AppColors.gold,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            const Text(
              'حدد بداية ونهاية الآية',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 30),
            
            // Waveform visualization
            _buildWaveform(),
            const SizedBox(height: 20),
            
            // Time indicators
            _buildTimeIndicators(),
            const SizedBox(height: 30),
            
            // Preview button
            _buildPreviewButton(),
            const SizedBox(height: 16),
            
            // Confirm button
            _buildConfirmButton(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveform() {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.2),
        ),
      ),
      child: Stack(
        children: [
          // Full waveform
          CustomPaint(
            size: Size.infinite,
            painter: WaveformPainter(
              startPosition: _startPosition,
              endPosition: _endPosition,
              totalDuration: widget.totalDuration,
            ),
          ),
          
          // Start marker
          Positioned(
            left: _startPosition * (MediaQuery.of(context).size.width - 40),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _startPosition = (_startPosition + details.delta.dx / (MediaQuery.of(context).size.width - 40))
                      .clamp(0.0, _endPosition - 0.05);
                });
              },
              child: Container(
                width: 20,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.drag_handle,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
            ),
          ),
          
          // End marker
          Positioned(
            left: _endPosition * (MediaQuery.of(context).size.width - 40),
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  _endPosition = (_endPosition + details.delta.dx / (MediaQuery.of(context).size.width - 40))
                      .clamp(_startPosition + 0.05, 1.0);
                });
              },
              child: Container(
                width: 20,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(
                  Icons.drag_handle,
                  color: AppColors.gold,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildTimeChip('بداية', _startTime),
        _buildTimeChip('المدة', _selectedDuration),
        _buildTimeChip('نهاية', _endTime),
      ],
    );
  }

  Widget _buildTimeChip(String label, Duration duration) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.gold.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _formatDuration(duration),
            style: const TextStyle(
              color: AppColors.gold,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewButton() {
    return ElevatedButton.icon(
      onPressed: () {
        // TODO: Preview selected range
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('معاينة من ${_formatDuration(_startTime)} إلى ${_formatDuration(_endTime)}'),
            backgroundColor: AppColors.gold.withOpacity(0.8),
          ),
        );
      },
      icon: const Icon(Icons.play_arrow),
      label: const Text('معاينة التحديد'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white.withOpacity(0.1),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: AppColors.gold.withOpacity(0.3)),
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          widget.onTrimComplete(_startTime, _endTime);
          Navigator.pop(context);
        },
        icon: const Icon(Icons.cut),
        label: const Text('قص الآية'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

/// Custom painter for audio waveform
class WaveformPainter extends CustomPainter {
  final double startPosition;
  final double endPosition;
  final Duration totalDuration;

  WaveformPainter({
    required this.startPosition,
    required this.endPosition,
    required this.totalDuration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = AppColors.gold.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.fill;

    // Generate waveform bars
    final barCount = 100;
    final barWidth = size.width / barCount;
    final random = _generateWaveformData(barCount);

    for (int i = 0; i < barCount; i++) {
      final position = i / barCount;
      final barHeight = random[i] * size.height * 0.8;
      final x = i * barWidth;
      final y = (size.height - barHeight) / 2;

      // Use selected paint if within range
      final currentPaint = (position >= startPosition && position <= endPosition)
          ? selectedPaint
          : paint;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth - 1, barHeight),
          const Radius.circular(2),
        ),
        currentPaint,
      );
    }
  }

  List<double> _generateWaveformData(int count) {
    // Simulate waveform data (replace with actual audio analysis)
    final data = <double>[];
    final random = count * 0.5;
    for (int i = 0; i < count; i++) {
      data.add(0.3 + (i % 7) / 10.0);
    }
    return data;
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.startPosition != startPosition ||
        oldDelegate.endPosition != endPosition;
  }
}

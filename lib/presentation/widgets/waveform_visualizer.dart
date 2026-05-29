import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

class WaveformVisualizer extends StatefulWidget {
  final bool isPlaying;
  final double height;
  final Color? color;

  const WaveformVisualizer({
    super.key,
    required this.isPlaying,
    this.height = 60,
    this.color,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final int _barCount = 32;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    if (widget.isPlaying) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(WaveformVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying != oldWidget.isPlaying) {
      if (widget.isPlaying) {
        _controller.repeat();
      } else {
        _controller.stop();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: List.generate(_barCount, (index) {
              // Procedural height calculation using sine waves
              double paintHeight = 0;
              
              if (widget.isPlaying) {
                // Combine two sine waves for more natural movement
                double base = sin((_controller.value * 2 * pi) + (index * 0.5));
                double wave = sin((_controller.value * 4 * pi) + (index * 0.2));
                
                // Envelope (bell curve) to taper edges
                double envelope = sin(pi * index / (_barCount - 1));
                
                paintHeight = (widget.height * 0.2) + 
                             (widget.height * 0.8 * ((base + wave + 2) / 4) * envelope);
              } else {
                // Static height when idle
                paintHeight = 4.0;
              }

              return Container(
                width: 3,
                height: paintHeight,
                margin: const EdgeInsets.symmetric(horizontal: 1.5),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      (widget.color ?? AppColors.gold).withValues(alpha: 0.7),
                      (widget.color ?? AppColors.gold),
                      (widget.color ?? AppColors.gold).withValues(alpha: 0.9),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(1.5),
                  boxShadow: [
                    if (widget.isPlaying)
                      BoxShadow(
                        color: (widget.color ?? AppColors.gold).withValues(alpha: 0.2),
                        blurRadius: 2,
                        spreadRadius: 0.5,
                      ),
                  ],
                ),
              );
            }),
          ),
        );
      },
    );
  }
}

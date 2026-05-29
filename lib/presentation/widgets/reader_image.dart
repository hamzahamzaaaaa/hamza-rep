import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ReaderImage extends StatelessWidget {
  final bool isCircle;
  final double? width;
  final double? height;

  const ReaderImage({
    super.key,
    this.isCircle = false,
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    const String imageUrl = 'https://raw.githubusercontent.com/hamzahamzaaaaa/hamza-rep/main/reciter.png';
    const String assetPath = 'assets/images/reciter.png';

    Widget image = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (context, url) => Container(
        color: Colors.grey[900],
        child: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.cyanAccent),
          ),
        ),
      ),
      errorWidget: (context, url, error) => Image.asset(
        assetPath,
        width: width,
        height: height,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[900],
          child: const Icon(Icons.person, color: Colors.white54, size: 40),
        ),
      ),
    );

    if (isCircle) {
      return ClipOval(child: image);
    }
    return image;
  }
}

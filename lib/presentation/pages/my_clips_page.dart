/// ============================================================================
/// MY CLIPS PAGE - Saved Clips in Downloads Section
/// ============================================================================
/// 
/// Displays all clipped verses with:
/// - Glassmorphism cards
/// - Cloud+arrow icon
/// - Play count and duration
/// - Bookmark support
/// - Delete functionality
library;

import 'package:flutter/material.dart';
import '../../core/services/verse_clips_database.dart';
import '../../core/models/verse_clip.dart';
import '../../core/constants/colors.dart';
import '../pages/clip_player_page.dart';
import '../widgets/glassmorphism_theme.dart';

class MyClipsPage extends StatefulWidget {
  const MyClipsPage({super.key});

  @override
  State<MyClipsPage> createState() => _MyClipsPageState();
}

class _MyClipsPageState extends State<MyClipsPage> {
  @override
  Widget build(BuildContext context) {
    final clips = VerseClipsDatabase.getAllClips();
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0A0E27),
              Color(0xFF15103D),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Clips list
              Expanded(
                child: clips.isEmpty
                    ? _buildEmptyState()
                    : _buildClipsList(clips),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final clipsCount = VerseClipsDatabase.clipsCount;
    
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'مقاطع محفوظة',
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 28,
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'مزامنة كاملة + تظليل ذهبي',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.gold.withOpacity(0.3)),
            ),
            child: Text(
              '$clipsCount مقطع',
              style: const TextStyle(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_awesome,
            size: 80,
            color: AppColors.gold.withOpacity(0.3),
          ),
          const SizedBox(height: 20),
          const Text(
            'لا توجد مقاطع بعد',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'قص آية من السورة لتبدأ',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClipsList(List<VerseClip> clips) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: clips.length,
      itemBuilder: (context, index) {
        final clip = clips[index];
        return _buildClipCard(clip);
      },
    );
  }

  Widget _buildClipCard(VerseClip clip) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ClipPlayer(clip: clip),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: GlassCard(
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              alignment: Alignment.center,
              children: [
                // Cloud+arrow icon
                Icon(
                  Icons.cloud_outlined,
                  size: 36,
                  color: AppColors.gold.withOpacity(0.7),
                ),
                Transform.translate(
                  offset: const Offset(0, 2),
                  child: Icon(
                    Icons.arrow_downward,
                    size: 18,
                    color: AppColors.gold.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            title: Text(
              clip.displayName,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 18,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(
                      Icons.timer,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _formatDuration(clip.clipDuration),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(
                      Icons.play_circle_outline,
                      size: 14,
                      color: Colors.white70,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${clip.playCount} تشغيل',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Bookmark button
                IconButton(
                  onPressed: () => _toggleBookmark(clip),
                  icon: Icon(
                    clip.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                    color: clip.isBookmarked ? AppColors.gold : Colors.white70,
                  ),
                ),
                // Delete button
                IconButton(
                  onPressed: () => _deleteClip(clip),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _toggleBookmark(VerseClip clip) {
    VerseClipsDatabase.toggleBookmark(clip.id);
    setState(() {});
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          clip.isBookmarked ? 'تم إزالة العلامة' : 'تم إضافة علامة',
        ),
        backgroundColor: AppColors.gold.withOpacity(0.8),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _deleteClip(VerseClip clip) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF15103D),
        title: const Text(
          'حذف المقطع',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'هل أنت متأكد من حذف "${clip.displayName}"؟',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              await VerseClipsDatabase.deleteClip(clip.id);
              Navigator.pop(context);
              setState(() {});
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('تم حذف المقطع'),
                  backgroundColor: Colors.redAccent.withOpacity(0.8),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/colors.dart';
import '../../core/providers/language_provider.dart';
import '../../main.dart';

class LanguageSelectionPage extends ConsumerWidget {
  const LanguageSelectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/reciter.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.4),
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.language, size: 80, color: AppColors.gold),
                  const SizedBox(height: 24),
                  Text(
                    'اختر اللغة / Select Language',
                    style: GoogleFonts.amiri(
                      fontSize: 24,
                      color: AppColors.gold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 40),
                  _buildLangButton(context, ref, 'العربية', 'ar'),
                  _buildLangButton(context, ref, 'English', 'en'),
                  _buildLangButton(context, ref, 'Português', 'pt'),
                  _buildLangButton(context, ref, 'Français', 'fr'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLangButton(BuildContext context, WidgetRef ref, String label, String code) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: ElevatedButton(
        onPressed: () async {
          await ref.read(languageProvider.notifier).setLanguage(code);
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (context) => MainScreen(key: mainScreenKey)),
            );
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.surface.withOpacity(0.8),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.gold, width: 0.5),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

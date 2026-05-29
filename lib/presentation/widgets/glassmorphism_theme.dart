import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// ============================================================================
/// GLOBAL GLASSMORPHISM THEME COMPONENTS
/// ============================================================================
/// 
/// Reusable glassmorphism widgets for consistent theme across the entire app
/// Features:
/// - Frosted glass effect with BackdropFilter
/// - Customizable blur intensity
/// - Gradient overlays
/// - Border highlights
/// - Shadow effects

/// Glass container with frosted background
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double blurX;
  final double blurY;
  final double opacity;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? borderColor;
  final double borderWidth;
  final List<BoxShadow>? boxShadow;
  final Gradient? gradient;

  const GlassContainer({
    super.key,
    required this.child,
    this.blurX = 10.0,
    this.blurY = 10.0,
    this.opacity = 0.15,
    this.borderRadius,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth = 1.0,
    this.boxShadow,
    this.gradient,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
          child: Container(
            padding: padding ?? EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: borderColor ?? AppColors.gold.withOpacity(0.2),
                width: borderWidth,
              ),
              gradient: gradient,
              boxShadow: boxShadow ??
                  [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.05),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Glass card for list items and content sections
class GlassCard extends StatelessWidget {
  final Widget child;
  final double blurIntensity;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  const GlassCard({
    super.key,
    required this.child,
    this.blurIntensity = 15.0,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        blurX: blurIntensity,
        blurY: blurIntensity,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// Glass overlay for full-screen backgrounds
class GlassOverlay extends StatelessWidget {
  final Widget? child;
  final double blurX;
  final double blurY;
  final double dimLevel;

  const GlassOverlay({
    super.key,
    this.child,
    this.blurX = 25.0,
    this.blurY = 25.0,
    this.dimLevel = 0.35,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurX, sigmaY: blurY),
            child: Container(
              color: Colors.black.withOpacity(dimLevel),
            ),
          ),
        ),
        if (child != null) child!,
      ],
    );
  }
}

/// Glass button with hover effects
class GlassButton extends StatelessWidget {
  final Widget child;
  final VoidCallback onPressed;
  final double blurIntensity;
  final EdgeInsets padding;

  const GlassButton({
    super.key,
    required this.child,
    required this.onPressed,
    this.blurIntensity = 8.0,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        child: GlassContainer(
          blurX: blurIntensity,
          blurY: blurIntensity,
          padding: padding,
          borderRadius: BorderRadius.circular(16),
          child: child,
        ),
      ),
    );
  }
}

/// Glass app bar
class GlassAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? title;
  final List<Widget>? actions;
  final Widget? leading;
  final double blurIntensity;

  const GlassAppBar({
    super.key,
    this.title,
    this.actions,
    this.leading,
    this.blurIntensity = 10.0,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
        child: AppBar(
          backgroundColor: Colors.black.withOpacity(0.3),
          elevation: 0,
          title: title,
          actions: actions,
          leading: leading,
        ),
      ),
    );
  }
}

/// Glass bottom sheet
class GlassBottomSheet extends StatelessWidget {
  final Widget child;
  final double blurIntensity;

  const GlassBottomSheet({
    super.key,
    required this.child,
    this.blurIntensity = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurIntensity, sigmaY: blurIntensity),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.4),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(
                color: AppColors.gold.withOpacity(0.3),
                width: 1.5,
              ),
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Glass divider
class GlassDivider extends StatelessWidget {
  final double height;
  final double thickness;

  const GlassDivider({
    super.key,
    this.height = 1.0,
    this.thickness = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Center(
        child: Container(
          height: thickness,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.transparent,
                AppColors.gold.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ============================================================================
/// ENHANCED GLASSMORPHISM COMPONENTS
/// ============================================================================

/// Glass list tile for menu items and navigation
class GlassListTile extends StatelessWidget {
  final IconData leadingIcon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? iconColor;
  final Widget? trailing;

  const GlassListTile({
    super.key,
    required this.leadingIcon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.iconColor,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            leadingIcon,
            color: iconColor ?? AppColors.gold,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          trailing ??
              Icon(
                Icons.chevron_right,
                color: Colors.white.withOpacity(0.5),
              ),
        ],
      ),
    );
  }
}

/// Glass settings tile with toggle/switch
class GlassSettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const GlassSettingsTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.gold,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.gold,
          ),
        ],
      ),
    );
  }
}

/// Gradient background with glass overlay
class GradientGlassBackground extends StatelessWidget {
  final Widget child;
  final List<Color> gradientColors;
  final double blurIntensity;

  const GradientGlassBackground({
    super.key,
    required this.child,
    this.gradientColors = const [
      Color(0xFF1A141F),
      Color(0xFF2D1B3D),
      Color(0xFF1A141F),
    ],
    this.blurIntensity = 15.0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
      ),
      child: GlassOverlay(
        blurX: blurIntensity,
        blurY: blurIntensity,
        dimLevel: 0.3,
        child: child,
      ),
    );
  }
}

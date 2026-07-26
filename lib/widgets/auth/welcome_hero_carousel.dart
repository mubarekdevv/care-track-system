import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../core/constants/auth_assets.dart';
import '../../core/constants/welcome_slides.dart';
import '../../core/theme/app_theme.dart';

/// Auto-advancing hero carousel for the welcome screen.
class WelcomeHeroCarousel extends StatefulWidget {
  final double height;
  final bool isDark;

  const WelcomeHeroCarousel({
    super.key,
    required this.height,
    required this.isDark,
  });

  @override
  State<WelcomeHeroCarousel> createState() => _WelcomeHeroCarouselState();
}

class _WelcomeHeroCarouselState extends State<WelcomeHeroCarousel> {
  static const _autoInterval = Duration(seconds: 5);

  final PageController _pageController = PageController();
  Timer? _autoTimer;
  int _currentPage = 0;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _autoTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoTimer?.cancel();
    _autoTimer = Timer.periodic(_autoInterval, (_) {
      if (!mounted || _userInteracting) return;
      final next = (_currentPage + 1) % WelcomeSlides.all.length;
      _pageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _onPageChanged(int index) {
    setState(() => _currentPage = index);
  }

  void _pauseAutoPlay() {
    _userInteracting = true;
    Future.delayed(const Duration(seconds: 8), () {
      if (mounted) _userInteracting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryBlue.withValues(alpha: widget.isDark ? 0.2 : 0.14),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: SizedBox(
              height: widget.height,
              child: PageView.builder(
                controller: _pageController,
                itemCount: WelcomeSlides.all.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return _WelcomeSlidePage(
                    slide: WelcomeSlides.all[index],
                    isDark: widget.isDark,
                    onInteraction: _pauseAutoPlay,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _PageIndicators(
          count: WelcomeSlides.all.length,
          index: _currentPage,
          accent: WelcomeSlides.all[_currentPage].accent,
        ),
      ],
    );
  }
}

class _WelcomeSlidePage extends StatelessWidget {
  final WelcomeSlide slide;
  final bool isDark;
  final VoidCallback onInteraction;

  const _WelcomeSlidePage({
    required this.slide,
    required this.isDark,
    required this.onInteraction,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanDown: (_) => onInteraction(),
      onTapDown: (_) => onInteraction(),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _SlideImage(slide: slide),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.05),
                  Colors.black.withValues(alpha: 0.15),
                  Colors.black.withValues(alpha: isDark ? 0.72 : 0.62),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: slide.accent.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(slide.icon, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        slide.headline.split(' ').first,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  slide.headline,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.15,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  slide.caption,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SlideImage extends StatelessWidget {
  final WelcomeSlide slide;

  const _SlideImage({required this.slide});

  @override
  Widget build(BuildContext context) {
    final jpegPath = AuthAssets.jpegPath(slide.assetPath);

    return Image.asset(
      jpegPath,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, __, ___) {
        final url = slide.networkUrl ?? AuthAssets.networkUrlFor(slide.assetPath);
        if (url != null && url.isNotEmpty) {
          return Image.network(
            url,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return _placeholder();
            },
            errorBuilder: (_, __, ___) => _buildSvg(),
          );
        }
        return _buildSvg();
      },
    );
  }

  Widget _buildSvg() {
    if (slide.assetPath.endsWith('.svg')) {
      return SvgPicture.asset(
        slide.assetPath,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholderBuilder: (_) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: slide.accent.withValues(alpha: 0.15),
      alignment: Alignment.center,
      child: Icon(slide.icon, size: 56, color: slide.accent.withValues(alpha: 0.5)),
    );
  }
}

class _PageIndicators extends StatelessWidget {
  final int count;
  final int index;
  final Color accent;

  const _PageIndicators({
    required this.count,
    required this.index,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(count, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? accent : accent.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

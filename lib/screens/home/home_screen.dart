import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/widgets/app_food_image.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/mini_app_item.dart';
import '../../core/widgets/skeleton_box.dart';
import '../../repositories/banner_repository.dart';
import '../splash/splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2;
  bool _loading = true;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSubscription;

  String _displayName = '';
  List<Map<String, dynamic>> _banners = [];
  bool _bannersLoading = true;

  PageController? _pageController;
  Timer? _timer;
  int _currentIndicatorIndex = 0;

  static const List<Map<String, dynamic>> _demoBanners = [
    {
      'title': 'Ăn ngon mỗi ngày',
      'subtitle': 'Ưu đãi đến 20%',
      'imageUrl':
          'https://images.unsplash.com/photo-1546069901-ba9599a7e63c?q=80&w=600&auto=format&fit=crop',
      'actionText': 'Khám phá ngay',
      'actionRoute': '/menu',
      'isActive': true,
      'sortOrder': 1,
    },
    {
      'title': 'Voucher đặc biệt',
      'subtitle': 'Giảm ngay 10k',
      'imageUrl':
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=600&auto=format&fit=crop',
      'actionText': 'Nhận ngay',
      'actionRoute': '/vouchers',
      'isActive': true,
      'sortOrder': 2,
    },
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 680), () {
      if (mounted) setState(() => _loading = false);
    });

    if (Firebase.apps.isNotEmpty) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _displayName = _getUserNameFromData(null, user);
        _userSubscription = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots()
            .listen((doc) {
              if (!mounted) return;
              setState(() {
                _displayName = _getUserNameFromData(doc.data(), user);
              });
            });
      }

      unawaited(_loadBanners());
    } else {
      // Offline fallback
      _banners = _demoBanners;
      _bannersLoading = false;
      _currentIndicatorIndex = 0;
      _setupPageControllerAndTimer();
    }
  }

  @override
  void dispose() {
    unawaited(_userSubscription?.cancel());
    _timer?.cancel();
    _pageController?.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await BannerRepository().loadActiveBanners();
      if (!mounted) return;
      setState(() {
        _banners = banners
            .map(
              (banner) => {
                'title': banner.title,
                'subtitle': banner.subtitle,
                'description': banner.description,
                'imageUrl': banner.imageUrl,
                'buttonText': banner.buttonText,
                'actionType': banner.actionType,
                'actionValue': banner.actionValue,
                'discountText': banner.discountText,
                'isActive': banner.isActive,
                'sortOrder': banner.sortOrder,
              },
            )
            .toList(growable: false);
        _bannersLoading = false;
        _currentIndicatorIndex = 0;
      });
      _setupPageControllerAndTimer();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _banners = _demoBanners;
        _bannersLoading = false;
      });
      _setupPageControllerAndTimer();
    }
  }

  void _setupPageControllerAndTimer() {
    if (_banners.isEmpty) return;
    final startPage = (1000 ~/ _banners.length) * _banners.length;
    if (_pageController != null) {
      if (_pageController!.hasClients) {
        _pageController!.jumpToPage(startPage);
      }
    } else {
      _pageController = PageController(initialPage: startPage);
    }
    _startTimer();
  }

  bool get _isTesting {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  void _startTimer() {
    _timer?.cancel();
    if (_banners.length <= 1) return;
    if (_isTesting) return;
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_pageController != null && _pageController!.hasClients) {
        _pageController!.nextPage(
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  String _getGreeting() {
    final now = DateTime.now();
    final hour = now.hour;
    if (hour >= 5 && hour < 11) {
      return 'Chào buổi sáng ☀️';
    } else if (hour >= 11 && hour < 14) {
      return 'Chào buổi trưa 🌤️';
    } else if (hour >= 14 && hour < 18) {
      return 'Chào buổi chiều 🌥️';
    } else if (hour >= 18 && hour < 22) {
      return 'Chào buổi tối 🌙';
    } else {
      return 'Chúc ngủ ngon 😴';
    }
  }

  String _getUserNameFromData(Map<String, dynamic>? data, User? currentUser) {
    if (data != null) {
      final fullName = data['fullName'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }
      final displayName = data['displayName'] as String?;
      if (displayName != null && displayName.trim().isNotEmpty) {
        return displayName.trim();
      }
    }
    if (currentUser != null) {
      final authDisplayName = currentUser.displayName;
      if (authDisplayName != null && authDisplayName.trim().isNotEmpty) {
        return authDisplayName.trim();
      }
      final email = currentUser.email;
      if (email != null && email.isNotEmpty) {
        final parts = email.split('@');
        if (parts.isNotEmpty && parts[0].isNotEmpty) {
          return parts[0];
        }
      }
    }
    return 'Nguyễn Hải Nam';
  }

  String _imageSource(Map<String, dynamic> data) {
    const keys = [
      'imageUrl',
      'image',
      'photoUrl',
      'thumbnail',
      'thumbnailUrl',
      'image_url',
      'photo_url',
    ];
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  void _onNavigationTap(int value) {
    setState(() => _currentIndex = value);
    if (value != 2) {
      showAppSnackBar(context, 'Tính năng demo. Vui lòng quay lại sau nhé!');
    }
  }

  void _openCanteen() {
    AppNavigator.push<void>(context, builder: (_) => const SplashScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _header()),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 108),
            sliver: SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 330),
                child: _loading ? const _DashboardSkeleton() : _content(),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomNavBar(
        selectedIndex: _currentIndex,
        onTap: _onNavigationTap,
        items: const [
          CustomNavItem(
            icon: Icons.calendar_today_outlined,
            activeIcon: Icons.calendar_today_rounded,
            label: 'Lịch học',
          ),
          CustomNavItem(
            icon: Icons.grid_view_outlined,
            activeIcon: Icons.grid_view_rounded,
            label: 'Danh mục',
          ),
          CustomNavItem(
            assetPath: 'assets/logos/huflit_logo.png',
            label: 'HUFLIT',
          ),
          CustomNavItem(
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            label: 'Thông báo',
          ),
          CustomNavItem(
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return GradientHeader(
      height: 222,
      subtitle: _getGreeting(),
      title: _displayName,
      trailing: Row(
        children: [
          _HeaderAction(
            icon: Icons.notifications_none_rounded,
            onTap: () =>
                showAppSnackBar(context, 'Bạn không có thông báo mới.'),
          ),
          const SizedBox(width: 9),
          const CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white,
            child: Icon(Icons.person_rounded, color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _content() {
    return Column(
      key: const ValueKey('dashboard_content'),
      children: [
        _overviewCard(),
        const SizedBox(height: 16),
        _miniApps(),
        const SizedBox(height: 16),
        _bannerSlider(),
      ],
    );
  }

  Widget _overviewCard() {
    return InfoCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final narrow = constraints.maxWidth < 330;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Kết quả học tập', style: AppTextStyles.title),
              const SizedBox(height: 4),
              const Text(
                'Học kỳ 2 • Năm học 2025 - 2026',
                style: AppTextStyles.subtitle,
              ),
              const SizedBox(height: 20),
              if (narrow) ...[
                const Center(child: _ScoreRing(score: 7.63)),
                const SizedBox(height: 20),
                const _StatLine(label: 'Tín chỉ tích lũy', value: '42 / 53'),
                const SizedBox(height: 12),
                const _StatLine(label: 'Môn đạt', value: '14 / 15'),
              ] else
                const Row(
                  children: [
                    _ScoreRing(score: 7.63),
                    SizedBox(width: 22),
                    Expanded(
                      child: Column(
                        children: [
                          _StatLine(
                            label: 'Tín chỉ tích lũy',
                            value: '42 / 53',
                          ),
                          SizedBox(height: 12),
                          _StatLine(label: 'Môn đạt', value: '14 / 15'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _miniApps() {
    return InfoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Tiện ích', style: AppTextStyles.title),
              const Spacer(),
              Text(
                'Tùy chỉnh',
                style: AppTextStyles.subtitle.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const MiniAppItem(
                label: 'Lịch thi',
                icon: Icons.event_note_rounded,
              ),
              const MiniAppItem(
                label: 'Học tập',
                icon: Icons.analytics_outlined,
                tint: Color(0xFF16A34A),
              ),
              const MiniAppItem(
                label: 'Hóa đơn',
                icon: Icons.receipt_long_outlined,
                tint: Color(0xFF8B5CF6),
              ),
              MiniAppItem(
                key: const ValueKey('open-smart-canteen'),
                label: 'Canteen',
                asset: 'assets/logos/smart_canteen.png',
                tint: AppColors.primary,
                onTap: _openCanteen,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bannerSlider() {
    if (_bannersLoading) {
      return const SkeletonBox(height: 160, radius: 22);
    }
    if (_banners.isEmpty) {
      return const SizedBox.shrink();
    }

    if (_pageController == null) {
      final startPage = (1000 ~/ _banners.length) * _banners.length;
      _pageController = PageController(initialPage: startPage);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startTimer();
      });
    }

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              if (_banners.isNotEmpty) {
                setState(() {
                  _currentIndicatorIndex = index % _banners.length;
                });
                _startTimer();
              }
            },
            itemBuilder: (context, index) {
              final bannerIndex = index % _banners.length;
              final banner = _banners[bannerIndex];
              final imageUrl = _imageSource(banner);
              final title = banner['title'] as String? ?? '';
              final subtitle = banner['subtitle'] as String? ?? '';
              final actionText = banner['actionText'] as String? ?? '';
              final actionRoute = banner['actionRoute'] as String? ?? '';

              return GestureDetector(
                onTap: () {
                  if (actionRoute.isNotEmpty) {
                    Navigator.pushNamed(context, actionRoute);
                  }
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      (imageUrl.isNotEmpty && !_isTesting)
                          ? AppFoodImage(source: imageUrl, fit: BoxFit.cover)
                          : Container(
                              color: AppColors.surfaceSoft,
                              child: const Center(
                                child: Icon(
                                  Icons.image_outlined,
                                  color: AppColors.textTertiary,
                                  size: 40,
                                ),
                              ),
                            ),
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.black.withValues(alpha: 0.2),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (subtitle.isNotEmpty)
                              Text(
                                subtitle,
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            const SizedBox(height: 4),
                            Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (actionText.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  actionText,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_banners.length, (index) {
            final isActive = index == _currentIndicatorIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              height: 8,
              width: isActive ? 18 : 8,
              decoration: BoxDecoration(
                color: isActive ? AppColors.primary : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          height: 43,
          width: 43,
          child: Icon(icon, color: Colors.white, size: 24),
        ),
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});

  final double score;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      width: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            height: 104,
            width: 104,
            child: CircularProgressIndicator(
              value: score / 10,
              strokeWidth: 9,
              strokeCap: StrokeCap.round,
              color: AppColors.primary,
              backgroundColor: AppColors.surfaceSoft,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(score.toStringAsFixed(2), style: AppTextStyles.value),
              const Text('GPA', style: AppTextStyles.label),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatLine extends StatelessWidget {
  const _StatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(label, style: AppTextStyles.subtitle)),
        Text(
          value,
          style: AppTextStyles.title.copyWith(color: AppColors.primary),
        ),
      ],
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      key: ValueKey('dashboard_skeleton'),
      children: [
        SkeletonBox(height: 208, radius: 24),
        SizedBox(height: 16),
        SkeletonBox(height: 144, radius: 24),
        SizedBox(height: 16),
        SkeletonBox(height: 160, radius: 22),
      ],
    );
  }
}

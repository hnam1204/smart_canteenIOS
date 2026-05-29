import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/navigation/app_navigator.dart';
import '../../core/theme/text_styles.dart';
import '../../core/utils/app_feedback.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import '../../core/widgets/gradient_header.dart';
import '../../core/widgets/info_card.dart';
import '../../core/widgets/mini_app_item.dart';
import '../../core/widgets/skeleton_box.dart';
import '../splash/splash_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 2;
  bool _loading = true;

  static const _grades = [
    _GradeData('Lập trình di động', 'MOB401', 3, 8.7),
    _GradeData('Cơ sở dữ liệu', 'DBS202', 3, 7.8),
    _GradeData('Xác suất thống kê', 'STA103', 2, 4.7),
  ];

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 680), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  void _onNavigationTap(int value) {
    setState(() => _currentIndex = value);
    if (value != 2) {
      showAppSnackBar(
        context,
        'Tính năng đang được hoàn thiện.',
        icon: Icons.auto_awesome_rounded,
        iconColor: AppColors.primaryLight,
      );
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
      subtitle: 'Chào buổi sáng,',
      title: 'Nguyễn Hải Nam',
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
        _resultsCard(),
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

  Widget _resultsCard() {
    return InfoCard(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Điểm gần đây', style: AppTextStyles.title),
              ),
              TextButton(
                onPressed: () =>
                    showAppSnackBar(context, 'Đã tải tất cả kết quả học tập.'),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          for (final item in _grades) _GradeRow(data: item),
        ],
      ),
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

class _GradeRow extends StatelessWidget {
  const _GradeRow({required this.data});

  final _GradeData data;

  @override
  Widget build(BuildContext context) {
    final passed = data.score >= 5;
    final status = passed ? AppColors.success : AppColors.error;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.name,
                  style: AppTextStyles.body.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${data.code}  •  ${data.credits} tín chỉ',
                  style: AppTextStyles.label,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                data.score.toStringAsFixed(1),
                style: AppTextStyles.heading.copyWith(color: status),
              ),
              Text(
                passed ? 'Đạt' : 'Chưa đạt',
                style: AppTextStyles.label.copyWith(color: status),
              ),
            ],
          ),
        ],
      ),
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
        SkeletonBox(height: 248, radius: 24),
      ],
    );
  }
}

class _GradeData {
  const _GradeData(this.name, this.code, this.credits, this.score);

  final String name;
  final String code;
  final int credits;
  final double score;
}

import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/navigation/app_navigator.dart';
import '../../../core/utils/app_feedback.dart';
import '../../../services/auth_service.dart';
import '../main_shell_screen.dart';
import '../widgets/canteen_bottom_nav_bar.dart';
import 'personal_info_controller.dart';
import 'user_profile_model.dart';
import 'widgets/account_security_card.dart';
import 'widgets/avatar_picker_section.dart';
import 'widgets/gender_picker_sheet.dart';
import 'widgets/personal_info_form.dart';
import 'widgets/profile_stats_card.dart';
import 'widgets/unsaved_changes_dialog.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({
    super.key,
    this.cartCount = 0,
    this.notificationCount = 0,
  });

  final int cartCount;
  final int notificationCount;

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  late final PersonalInfoController _controller;
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _genderController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _departmentController = TextEditingController();
  final _addressController = TextEditingController();
  final _noteController = TextEditingController();

  UserProfileModel? _boundProfile;
  late DateTime _birthDate;
  late Gender _gender;
  int _avatarVariant = 0;

  @override
  void initState() {
    super.initState();
    _controller = PersonalInfoController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _genderController.dispose();
    _studentIdController.dispose();
    _departmentController.dispose();
    _addressController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _bindProfile(UserProfileModel profile) {
    if (identical(_boundProfile, profile)) return;
    _boundProfile = profile;
    _birthDate = profile.dateOfBirth;
    _gender = profile.gender;
    _avatarVariant = profile.avatarVariant;
    _fullNameController.text = profile.fullName;
    _emailController.text = profile.email;
    _phoneController.text = profile.phone;
    _birthDateController.text = formatDate(profile.dateOfBirth);
    _genderController.text = genderLabel(profile.gender);
    _studentIdController.text = profile.studentId;
    _departmentController.text = profile.department;
    _addressController.text = profile.address;
    _noteController.text = profile.note;
  }

  UserProfileModel _editedProfile(UserProfileModel original) {
    return original.copyWith(
      fullName: _fullNameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      dateOfBirth: _birthDate,
      gender: _gender,
      studentId: _studentIdController.text.trim(),
      department: _departmentController.text.trim(),
      address: _addressController.text.trim(),
      note: _noteController.text.trim(),
      avatarVariant: _avatarVariant,
    );
  }

  bool get _hasUnsavedChanges {
    final original = _controller.profile;
    if (!_controller.editing || original == null) return false;
    final updated = _editedProfile(original);
    return updated.fullName != original.fullName ||
        updated.email != original.email ||
        updated.phone != original.phone ||
        updated.dateOfBirth != original.dateOfBirth ||
        updated.gender != original.gender ||
        updated.studentId != original.studentId ||
        updated.department != original.department ||
        updated.address != original.address ||
        updated.note != original.note ||
        updated.avatarVariant != original.avatarVariant ||
        updated.avatarUrl != original.avatarUrl;
  }

  void _startEditing() {
    _controller.beginEdit();
  }

  void _changeAvatar() {
    if (!_controller.editing) _controller.beginEdit();
    setState(() => _avatarVariant = (_avatarVariant + 1) % 3);
  }

  Future<void> _save() async {
    final profile = _controller.profile;
    if (profile == null || !_formKey.currentState!.validate()) return;
    await _controller.save(_editedProfile(profile));
    if (!mounted) return;
    _boundProfile = null;
    showAppSnackBar(context, 'Thông tin cá nhân đã được lưu.');
  }

  void _cancelEdit() {
    final profile = _controller.profile;
    if (profile == null) return;
    setState(() {
      _boundProfile = null;
      _bindProfile(profile);
    });
    _controller.cancelEdit();
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasUnsavedChanges) return true;
    return await showDialog<bool>(
          context: context,
          builder: (_) => const UnsavedChangesDialog(),
        ) ??
        false;
  }

  Future<void> _back() async {
    final discardingChanges = _hasUnsavedChanges;
    if (!await _confirmDiscard() || !mounted) return;
    if (discardingChanges) _cancelEdit();
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
      return;
    }
    _replaceWithTab(4);
  }

  Future<void> _onBottomNavTap(int index) async {
    final discardingChanges = _hasUnsavedChanges;
    if (!await _confirmDiscard() || !mounted) return;
    if (discardingChanges) _cancelEdit();
    _replaceWithTab(index);
  }

  void _replaceWithTab(int index) {
    AppNavigator.replace<void>(
      context,
      builder: (_) => MainShellScreen(initialIndex: index),
    );
  }

  Future<void> _selectBirthDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _birthDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      helpText: 'Chọn ngày sinh',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _birthDate = selected;
      _birthDateController.text = formatDate(selected);
    });
  }

  void _selectGender() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => GenderPickerSheet(
        selected: _gender,
        onSelected: (gender) {
          Navigator.pop(sheetContext);
          setState(() {
            _gender = gender;
            _genderController.text = genderLabel(gender);
          });
        },
      ),
    );
  }

  void _openSecurity(AccountSecurityModel item) {
    AppNavigator.push<void>(
      context,
      builder: (_) => _SecurityDestinationScreen(item: item),
    );
  }

  Future<void> _logout() async {
    final accepted = await _confirmAction(
      title: 'Đăng xuất?',
      message: 'Bạn sẽ cần đăng nhập lại để tiếp tục sử dụng Smart Canteen.',
      action: 'Đăng xuất',
    );
    if (accepted != true || !mounted) return;
    await AuthService().signOut();
    if (!mounted) return;
    AppNavigator.pushNamedAndRemoveUntil<void>(
      context,
      '/login',
      (route) => false,
    );
  }

  Future<void> _deleteAccount() async {
    final accepted = await _confirmAction(
      title: 'Xóa tài khoản?',
      message: 'Dữ liệu và điểm thưởng của bạn sẽ không thể khôi phục.',
      action: 'Xóa tài khoản',
    );
    if (accepted != true || !mounted) return;
    showAppSnackBar(
      context,
      'Yêu cầu xóa tài khoản đã được gửi.',
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.error,
    );
  }

  Future<bool?> _confirmAction({
    required String title,
    required String message,
    required String action,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(23)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(action),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          final profile = _controller.profile;
          if (profile != null) _bindProfile(profile);
          return Scaffold(
            backgroundColor: AppColors.background,
            resizeToAvoidBottomInset: true,
            body: SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _Header(
                    editing: _controller.editing,
                    saving: _controller.saving,
                    onBackTap: _back,
                    onActionTap: _controller.editing ? _save : _startEditing,
                  ),
                  Expanded(child: _buildContent(profile)),
                ],
              ),
            ),
            bottomNavigationBar: CanteenBottomNavBar(
              selectedIndex: 4,
              cartCount: widget.cartCount,
              notificationCount: widget.notificationCount,
              onTap: _onBottomNavTap,
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(UserProfileModel? profile) {
    if (_controller.loading) return const _PersonalInfoLoading();
    if (_controller.authRequired) return const _PersonalAuthRequired();
    if (_controller.hasError || profile == null) {
      return _PersonalInfoError(onRetry: _controller.retry);
    }
    return RefreshIndicator(
      onRefresh: _controller.refresh,
      color: AppColors.primary,
      child: ListView(
        key: const ValueKey('personal-info-list'),
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(
          18,
          5,
          18,
          118 + MediaQuery.viewInsetsOf(context).bottom,
        ),
        children: [
          AvatarPickerSection(
            fullName: _fullNameController.text,
            email: _emailController.text,
            avatarVariant: _avatarVariant,
            avatarUrl: profile.avatarUrl,
            editing: _controller.editing,
            onAvatarTap: _changeAvatar,
          ),
          if (_controller.editing) ...[
            const SizedBox(height: 11),
            OutlinedButton.icon(
              key: const ValueKey('cancel-personal-edit'),
              onPressed: _cancelEdit,
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text('Hủy chỉnh sửa'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 14),
          PersonalInfoForm(
            formKey: _formKey,
            editing: _controller.editing,
            fullNameController: _fullNameController,
            emailController: _emailController,
            phoneController: _phoneController,
            birthDateController: _birthDateController,
            genderController: _genderController,
            studentIdController: _studentIdController,
            departmentController: _departmentController,
            addressController: _addressController,
            noteController: _noteController,
            onBirthDateTap: _selectBirthDate,
            onGenderTap: _selectGender,
          ),
          const SizedBox(height: 14),
          ProfileStatsCard(stats: profile.stats),
          const SizedBox(height: 14),
          AccountSecurityCard(
            items: profile.securityItems,
            onTap: _openSecurity,
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            key: const ValueKey('personal-logout'),
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Đăng xuất'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              minimumSize: const Size.fromHeight(51),
              side: const BorderSide(color: Color(0xFFFFD7D5)),
            ),
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            key: const ValueKey('delete-account'),
            onPressed: _deleteAccount,
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Xóa tài khoản'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.editing,
    required this.saving,
    required this.onBackTap,
    required this.onActionTap,
  });

  final bool editing;
  final bool saving;
  final VoidCallback onBackTap;
  final VoidCallback onActionTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 104),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'Thông tin cá nhân',
                maxLines: 1,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              tooltip: 'Quay lại',
              onPressed: onBackTap,
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 21),
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              key: const ValueKey('personal-edit-save'),
              onPressed: saving ? null : onActionTap,
              icon: saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(editing ? Icons.save_outlined : Icons.edit_outlined),
              label: Text(editing ? 'Lưu' : 'Sửa'),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }
}

class _PersonalInfoLoading extends StatelessWidget {
  const _PersonalInfoLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 5, 18, 20),
      children: [
        for (final height in [218.0, 530.0, 105.0])
          Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.divider),
            ),
          ),
      ],
    );
  }
}

class _PersonalInfoError extends StatelessWidget {
  const _PersonalInfoError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 48,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 13),
          const Text('Không thể tải thông tin cá nhân.'),
          const SizedBox(height: 13),
          FilledButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

class _PersonalAuthRequired extends StatelessWidget {
  const _PersonalAuthRequired();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.lock_person_outlined,
              size: 52,
              color: AppColors.textTertiary,
            ),
            const SizedBox(height: 14),
            const Text(
              'Vui lòng đăng nhập',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn cần đăng nhập để xem và cập nhật thông tin cá nhân.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: () => AppNavigator.pushNamedAndRemoveUntil<void>(
                context,
                '/login',
                (route) => false,
              ),
              child: const Text('Đăng nhập'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityDestinationScreen extends StatelessWidget {
  const _SecurityDestinationScreen({required this.item});

  final AccountSecurityModel item;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        title: Text(item.title),
      ),
      body: SafeArea(
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              boxShadow: AppColors.cardShadow,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(item.icon, color: AppColors.primary, size: 38),
                const SizedBox(height: 15),
                Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  item.subtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

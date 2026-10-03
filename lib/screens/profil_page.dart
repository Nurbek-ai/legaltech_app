import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilPage extends StatefulWidget {
  const ProfilPage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  static const _serviceItems = <_ProfileServiceData>[
    _ProfileServiceData(
      icon: CupertinoIcons.folder_fill,
      title: 'Arizalarim',
      subtitle: '3 ta ariza ko‘rib chiqilmoqda',
      badge: '3 faol',
      color: Color(0xFF78A7FF),
      detail: 'Arizalaringizning holatini kuzating va kerakli hujjatlarni bir joydan boshqaring.',
    ),
    _ProfileServiceData(
      icon: CupertinoIcons.doc_text_fill,
      title: 'Shartnomalarim',
      subtitle: '8 ta saqlangan kelishuv',
      badge: '8 ta',
      color: Color(0xFFB89AFF),
      detail:
          'Tayyorlangan shartnomalar va kelishuvlaringiz shu yerda saqlanadi.',
    ),
    _ProfileServiceData(
      icon: CupertinoIcons.building_2_fill,
      title: 'Sud ishlari',
      subtitle: '1 ta ish bo‘yicha yangilanish bor',
      badge: 'Yangilik',
      color: Color(0xFFFFBC75),
      detail: 'Sud jarayonlari, keyingi qadamlar va muhim hujjatlarni kuzatib boring.',
    ),
  ];

  String _displayName = 'Nurbek Otamurodov';
  bool _notificationsEnabled = true;
  bool _biometricEnabled = true;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      key: const ValueKey('profile-page'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _ProfileBrandHeader(
              notificationsEnabled: _notificationsEnabled,
              onNotificationTap: _toggleNotifications,
              onSettingsTap: _showSecuritySheet,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _ProfileHero(
              name: _displayName,
              onEditTap: _showEditProfileSheet,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Faoliyat statistikasi',
              trailing: 'Joriy oy',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _ProfileStat(
                    value: '03',
                    label: 'Faol ariza',
                    accent: const Color(0xFF83AAFF),
                    icon: CupertinoIcons.folder,
                    onTap: () => _showStatSheet(
                      title: 'Faol arizalar',
                      value: '03',
                      description: 'Uchta arizangiz hozir mutaxassislar tomonidan ko‘rib chiqilmoqda.',
                      icon: CupertinoIcons.folder_fill,
                      color: const Color(0xFF83AAFF),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileStat(
                    value: '08',
                    label: 'Hujjatlar',
                    accent: const Color(0xFFD0B7FF),
                    icon: CupertinoIcons.doc,
                    onTap: () => _showStatSheet(
                      title: 'Saqlangan hujjatlar',
                      value: '08',
                      description: 'Muhim hujjatlaringiz xavfsiz profilda tartibli saqlanmoqda.',
                      icon: CupertinoIcons.doc_fill,
                      color: const Color(0xFFD0B7FF),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ProfileStat(
                    value: '86%',
                    label: 'Profil tayyor',
                    accent: const Color(0xFF75DAB2),
                    icon: CupertinoIcons.check_mark_circled,
                    onTap: _showEditProfileSheet,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Profil boshqaruvi',
              trailing: 'Himoyalangan',
              trailingIcon: CupertinoIcons.shield_lefthalf_fill,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _SecurityStatusCard(
              biometricEnabled: _biometricEnabled,
              onTap: _showSecuritySheet,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 12),
          sliver: SliverToBoxAdapter(
            child: _SectionHeader(
              title: 'Mening xizmatlarim',
              trailing: '${_serviceItems.length} bo‘lim',
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 122),
          sliver: SliverList.separated(
            itemCount: _serviceItems.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final item = _serviceItems[index];
              return _ProfileServiceTile(
                data: item,
                onTap: () => _showServiceSheet(item),
              );
            },
          ),
        ),
      ],
    );
  }

  void _toggleNotifications() {
    setState(() => _notificationsEnabled = !_notificationsEnabled);
    _showMessage(
      _notificationsEnabled
          ? 'Bildirishnomalar yoqildi'
          : 'Bildirishnomalar vaqtincha o‘chirildi',
    );
  }

  Future<void> _showEditProfileSheet() async {
    final nameController = TextEditingController(text: _displayName);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        final bottomInset = MediaQuery.viewInsetsOf(sheetContext).bottom;
        return Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: _ProfileBottomSheet(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _SheetHandle(),
                const SizedBox(height: 18),
                const _SheetBrandMark(),
                const SizedBox(height: 15),
                const Text(
                  'Profilni yangilash',
                  style: TextStyle(
                    color: Color(0xFFF5F8FF),
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Ismingiz profil kartasi va yuridik xizmatlarda aks etadi.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.56),
                    fontSize: 13,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: nameController,
                  textCapitalization: TextCapitalization.words,
                  cursorColor: const Color(0xFF9DBBFF),
                  style: const TextStyle(
                    color: Color(0xFFF4F7FC),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  decoration: InputDecoration(
                    labelText: 'To‘liq ism',
                    labelStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                    ),
                    prefixIcon: const Icon(
                      CupertinoIcons.person_fill,
                      color: Color(0xFF9DBBFF),
                      size: 19,
                    ),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.055),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 17,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.11),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(14)),
                      borderSide: BorderSide(color: Color(0xFF84A9FF)),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const _SheetInfoLine(
                  icon: CupertinoIcons.checkmark_seal_fill,
                  color: Color(0xFF6BD5AA),
                  text: 'Shaxsingiz tasdiqlangan',
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: () {
                      final newName = nameController.text.trim();
                      if (newName.isEmpty) return;
                      setState(() => _displayName = newName);
                      Navigator.of(sheetContext).pop();
                      _showMessage('Profil ma’lumotlari yangilandi');
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4A79E0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(CupertinoIcons.checkmark_alt),
                    label: const Text(
                      'O‘zgarishlarni saqlash',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );

    nameController.dispose();
  }

  Future<void> _showSecuritySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return _ProfileBottomSheet(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _SheetHandle(),
                  const SizedBox(height: 18),
                  const _SheetBrandMark(),
                  const SizedBox(height: 15),
                  const Text(
                    'Xavfsizlik markazi',
                    style: TextStyle(
                      color: Color(0xFFF5F8FF),
                      fontSize: 23,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Profilingiz va hujjatlaringiz bir necha qatlamli himoya bilan saqlanadi.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.56),
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _SecuritySetting(
                    icon: CupertinoIcons.lock_shield_fill,
                    title: 'Biometrik himoya',
                    subtitle: 'Ilovaga kirishda Face ID yoki barmoq izi',
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() => _biometricEnabled = value);
                      setSheetState(() {});
                    },
                  ),
                  const SizedBox(height: 10),
                  const _SecuritySetting(
                    icon: CupertinoIcons.checkmark_shield_fill,
                    title: 'Tasdiqlangan akkaunt',
                    subtitle: 'Shaxsiy ma’lumotlar tekshiruvdan o‘tgan',
                    value: true,
                    onChanged: null,
                  ),
                  const SizedBox(height: 18),
                  const _SheetInfoLine(
                    icon: CupertinoIcons.lock_fill,
                    color: Color(0xFF9DBBFF),
                    text: 'Ma’lumotlar uzatishda shifrlanadi',
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showStatSheet({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    _showInsightSheet(
      title: title,
      value: value,
      description: description,
      icon: icon,
      color: color,
      footer: 'Ma’lumotlar profilingizdagi faoliyat asosida yangilanadi.',
    );
  }

  void _showServiceSheet(_ProfileServiceData service) {
    _showInsightSheet(
      title: service.title,
      value: service.badge,
      description: service.detail,
      icon: service.icon,
      color: service.color,
      footer: 'Yangi o‘zgarishlar bo‘lsa, sizga bildirishnoma yuboramiz.',
    );
  }

  void _showInsightSheet({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color color,
    required String footer,
  }) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return _ProfileBottomSheet(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _SheetHandle(),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: color.withValues(alpha: 0.24)),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Color(0xFFF5F8FF),
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.63),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 18),
              _SheetInfoLine(
                icon: CupertinoIcons.bell_fill,
                color: color,
                text: footer,
              ),
              const SizedBox(height: 15),
            ],
          ),
        );
      },
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          98 + MediaQuery.paddingOf(context).bottom,
        ),
        backgroundColor: const Color(0xFF23364C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

class _ProfileBrandHeader extends StatelessWidget {
  final bool notificationsEnabled;
  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;

  const _ProfileBrandHeader({
    required this.notificationsEnabled,
    required this.onNotificationTap,
    required this.onSettingsTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
          ),
          child: Image.asset('assets/logo.png', fit: BoxFit.contain),
        ),
        const SizedBox(width: 11),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'YAN360',
                style: TextStyle(
                  color: Color(0xFFF3F6FC),
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.3,
                ),
              ),
              SizedBox(height: 2),
              Text(
                'SHAXSIY YURIDIK PROFIL',
                style: TextStyle(
                  color: Color(0xFF8190A5),
                  fontSize: 8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.9,
                ),
              ),
            ],
          ),
        ),
        _HeaderIconButton(
          icon: notificationsEnabled
              ? CupertinoIcons.bell_fill
              : CupertinoIcons.bell_slash,
          tooltip: 'Bildirishnomalar',
          showBadge: notificationsEnabled,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: 8),
        _HeaderIconButton(
          icon: CupertinoIcons.shield_fill,
          tooltip: 'Xavfsizlik sozlamalari',
          onTap: onSettingsTap,
        ),
      ],
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final bool showBadge;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.showBadge = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(13),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.065),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.11)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(icon, color: const Color(0xFFB8C7DC), size: 19),
                if (showBadge)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: Color(0xFF73D9AF),
                        shape: BoxShape.circle,
                      ),
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

class _ProfileHero extends StatelessWidget {
  final String name;
  final VoidCallback onEditTap;

  const _ProfileHero({required this.name, required this.onEditTap});

  @override
  Widget build(BuildContext context) {
    final nameParts = name.split(RegExp(r'\s+'));
    final initials = nameParts
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFF17375C),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFF8DB1F0).withValues(alpha: 0.23),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1D4A84).withValues(alpha: 0.26),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -33,
            top: -18,
            child: Opacity(
              opacity: 0.10,
              child: Image.asset(
                'assets/logo.png',
                width: 188,
                height: 188,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7AE0B5).withValues(alpha: 0.13),
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: const Color(0xFF86E7BD)
                              .withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            color: Color(0xFF80E2B5),
                            size: 13,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'TASDIQLANGAN',
                            style: TextStyle(
                              color: Color(0xFFC3F3DC),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.65,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Tooltip(
                      message: 'Profilni tahrirlash',
                      child: IconButton(
                        onPressed: onEditTap,
                        icon: const Icon(CupertinoIcons.pencil),
                        color: const Color(0xFFD8E5F9),
                        iconSize: 18,
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withValues(alpha: 0.10),
                          fixedSize: const Size(38, 38),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0C1F3A),
                        borderRadius: BorderRadius.circular(19),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.23),
                          width: 1.2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFFDCEAFF),
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFFF7F9FF),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.06,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Raqamli huquqiy profil',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.65),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'A’zo bo‘lgan: 2026',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.43),
                              fontSize: 10.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Profil to‘liqligi',
                        style: TextStyle(
                          color: Color(0xFFD9E7FC),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      '86%',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.78),
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: const LinearProgressIndicator(
                    value: 0.86,
                    minHeight: 7,
                    color: Color(0xFF7CE0B4),
                    backgroundColor: Color(0xFF315273),
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

class _SectionHeader extends StatelessWidget {
  final String title;
  final String trailing;
  final IconData? trailingIcon;

  const _SectionHeader({
    required this.title,
    required this.trailing,
    this.trailingIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFFF0F4FA),
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (trailingIcon != null) ...[
          Icon(trailingIcon, color: const Color(0xFF79D8AE), size: 13),
          const SizedBox(width: 5),
        ],
        Text(
          trailing,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.44),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProfileStat extends StatelessWidget {
  final String value;
  final String label;
  final Color accent;
  final IconData icon;
  final VoidCallback onTap;

  const _ProfileStat({
    required this.value,
    required this.label,
    required this.accent,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 113,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: accent, size: 18),
              const Spacer(),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: accent,
                  fontSize: value.length > 2 ? 19 : 24,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.52),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SecurityStatusCard extends StatelessWidget {
  final bool biometricEnabled;
  final VoidCallback onTap;

  const _SecurityStatusCard({
    required this.biometricEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: const Color(0xFF153329).withValues(alpha: 0.72),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF75D9AF).withValues(alpha: 0.18),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF75D9AF).withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  CupertinoIcons.lock_shield_fill,
                  color: Color(0xFF83DEB7),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      biometricEnabled
                          ? 'Biometrik himoya faol'
                          : 'Biometrik himoyani yoqing',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFE9F8F0),
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      biometricEnabled
                          ? 'Profilingiz qo‘shimcha himoyalangan'
                          : 'Hujjatlarni yanada ishonchli saqlang',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.52),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                CupertinoIcons.chevron_right,
                color: Color(0xFF9BDCBF),
                size: 17,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileServiceData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String badge;
  final Color color;
  final String detail;

  const _ProfileServiceData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.color,
    required this.detail,
  });
}

class _ProfileServiceTile extends StatelessWidget {
  final _ProfileServiceData data;
  final VoidCallback onTap;

  const _ProfileServiceTile({required this.data, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: Colors.white.withValues(alpha: 0.085)),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 78),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: data.color.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: data.color.withValues(alpha: 0.20),
                    ),
                  ),
                  child: Icon(data.icon, color: data.color, size: 21),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFF0F4FA),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.46),
                          fontSize: 10.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 9),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: data.color.withValues(alpha: 0.11),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        data.badge,
                        style: TextStyle(
                          color: data.color,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Icon(
                      CupertinoIcons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.37),
                      size: 14,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileBottomSheet extends StatelessWidget {
  final Widget child;

  const _ProfileBottomSheet({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        8,
        20,
        20 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF17283A),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: child,
    );
  }
}

class _SheetHandle extends StatelessWidget {
  const _SheetHandle();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 38,
        height: 4,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _SheetBrandMark extends StatelessWidget {
  const _SheetBrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFF4A79E0).withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF9DBBFF).withValues(alpha: 0.22),
        ),
      ),
      child: Image.asset('assets/logo.png', fit: BoxFit.contain),
    );
  }
}

class _SheetInfoLine extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _SheetInfoLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.56),
              fontSize: 11.5,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}

class _SecuritySetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _SecuritySetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.white.withValues(alpha: 0.085)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7BE0B4).withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF86E5BA), size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF1F5FA),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.46),
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          CupertinoSwitch(
            value: value,
            activeTrackColor: const Color(0xFF57B88D),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

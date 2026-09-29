import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ProfilPage extends StatefulWidget {
  const _ProfilePage({super.key});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  static const _profileItems = <_ProfileItemData>[
    _ProfileItemData(
      icon: CupertinoIcons.folder,
      title: 'Mening arizalarim',
      subtitle: 'Yuborilgan va saqlangan arizalar',
      color: Color(0xFF79A9FF),
    ),
    _ProfileItemData(
      icon: CupertinoIcons.doc_text,
      title: 'Mening shartnomalarim',
      subtitle: 'Shartnomalar va kelishuvlar',
      color: Color(0xFFB994FF),
    ),
    _ProfileItemData(
      icon: CupertinoIcons.doc_text,
      title: 'Sud ishlari',
      subtitle: 'Sud jarayonlari va hujjatlar',
      color: Color(0xFFFFB66E),
    ),
    _ProfileItemData(
      icon: CupertinoIcons.briefcase,
      title: 'Mehnat faoliyati',
      subtitle: 'Mehnat hujjatlari va ma’lumotlar',
      color: Color(0xFF6ED9B2),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildHeader()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(
            child: _ProfileIdentityCard(
              onPhotoTap: _showPhotoOptions,
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 27, 20, 13),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                const Text(
                  'Faoliyatim',
                  style: TextStyle(
                    color: Color(0xFFF1F5FC),
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                Text(
                  '4 bo‘lim',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.43),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 122),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: EdgeInsets.only(
                  bottom: index == _profileItems.length - 1 ? 0 : 10,
                ),
                child: _ProfileMenuItem(
                  data: _profileItems[index],
                  onTap: () => _showComingSoon(_profileItems[index].title),
                ),
              ),
              childCount: _profileItems.length,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Profil',
                style: TextStyle(
                  color: Color(0xFFF5F7FC),
                  fontSize: 31,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.9,
                ),
              ),
              SizedBox(height: 5),
              Text(
                'Shaxsiy ma’lumotlaringiz bir joyda',
                style: TextStyle(
                  color: Color(0xFF8F9CAE),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: _showEditProfileMessage,
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.11),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  CupertinoIcons.pencil,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.78),
                ),
                const SizedBox(width: 7),
                Text(
                  'Tahrirlash',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.80),
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF18283A),
      barrierColor: Colors.black.withValues(alpha: 0.62),
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 2, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Profil rasmini yangilash',
                  style: TextStyle(
                    color: Color(0xFFF4F7FD),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  'Profilingiz uchun rasm tanlang yoki yangi suratga oling.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 18),
                _ProfilePhotoAction(
                  icon: CupertinoIcons.photo,
                  title: 'Galereyadan tanlash',
                  subtitle: 'Qurilmangizdagi rasmni yuklash',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Galereyadan rasm tanlash');
                  },
                ),
                const SizedBox(height: 10),
                _ProfilePhotoAction(
                  icon: CupertinoIcons.camera,
                  title: 'Kamera orqali suratga olish',
                  subtitle: 'Yangi profil rasmi yarating',
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Kamera orqali suratga olish');
                  },
                ),
                const SizedBox(height: 10),
                _ProfilePhotoAction(
                  icon: CupertinoIcons.trash,
                  title: 'Rasmni olib tashlash',
                  subtitle: 'Standart avatarni qayta tiklash',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(sheetContext);
                    _showComingSoon('Rasmni olib tashlash');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditProfileMessage() {
    _showComingSoon('Profil ma’lumotlarini tahrirlash');
  }

  void _showComingSoon(String action) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$action — tez orada'),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.fromLTRB(
          20,
          0,
          20,
          98 + MediaQuery.paddingOf(context).bottom,
        ),
        backgroundColor: const Color(0xFF2A3D58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ProfileIdentityCard extends StatelessWidget {
  final VoidCallback onPhotoTap;

  const _ProfileIdentityCard({
    required this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 194,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFF4F7FB),
            Color(0xFFD8E2F0),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.78),
          width: 1.3,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6E92C8).withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -70,
            right: -45,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF7897C6).withValues(alpha: 0.22),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -72,
            right: 28,
            child: Transform.rotate(
              angle: -0.2,
              child: Container(
                width: 106,
                height: 60,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFC1D3EA).withValues(alpha: 0.58),
                      const Color(0xFF8EA8C8).withValues(alpha: 0.10),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: const Color(0xFF17283D),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: const Icon(
                        CupertinoIcons.lock,
                        color: Color(0xFFBBD0EF),
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 9),
                    const Text(
                      'YAN360',
                      style: TextStyle(
                        color: Color(0xFF17283D),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 9,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A7A5D).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: const Color(0xFF1A7A5D).withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            CupertinoIcons.checkmark_seal_fill,
                            size: 12,
                            color: Color(0xFF1A7A5D),
                          ),
                          SizedBox(width: 5),
                          Text(
                            'Tasdiqlangan',
                            style: TextStyle(
                              color: Color(0xFF1A7A5D),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _ProfileAvatar(onTap: onPhotoTap),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nurbek',
                            style: TextStyle(
                              color: Color(0xFF152338),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Otamurodov',
                            style: TextStyle(
                              color: Color(0xFF152338),
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              height: 1.0,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 9),
                          Text(
                            'A’zo bo‘lgan sana',
                            style: TextStyle(
                              color: Color(0xFF66748A),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            '2026',
                            style: TextStyle(
                              color: Color(0xFF263A55),
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 47,
                      height: 47,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7C92B5).withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: const Color(0xFF7189AF).withValues(alpha: 0.23),
                        ),
                      ),
                      child: const Icon(
                        CupertinoIcons.lock,
                        color: Color(0xFF50698F),
                        size: 23,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Row(
                  children: [
                    Text(
                      'RAQAMLI HUQUQIY PROFIL',
                      style: TextStyle(
                        color: const Color(0xFF536783).withValues(alpha: 0.78),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      CupertinoIcons.checkmark,
                      size: 18,
                      color: const Color(0xFF6680A4).withValues(alpha: 0.72),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  final VoidCallback onTap;

  const _ProfileAvatar({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 82,
            height: 94,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF2D4565),
                  Color(0xFF14263D),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.70),
                width: 2,
              ),
            ),
            child: const Center(
              child: Text(
                'NO',
                style: TextStyle(
                  color: Color(0xFFDBE8FC),
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
          ),
          Positioned(
            right: -8,
            bottom: -8,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF315B91),
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF0F4FB),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.16),
                    blurRadius: 7,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.camera_fill,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileItemData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _ProfileItemData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}

class _ProfileMenuItem extends StatelessWidget {
  final _ProfileItemData data;
  final VoidCallback onTap;

  const _ProfileMenuItem({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          constraints: const BoxConstraints(minHeight: 75),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.055),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.085),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 47,
                height: 47,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: data.color.withValues(alpha: 0.18),
                  ),
                ),
                child: Icon(
                  data.icon,
                  color: data.color,
                  size: 23,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFFF1F4FA),
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
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                CupertinoIcons.chevron_right,
                color: Colors.white.withValues(alpha: 0.42),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfilePhotoAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  const _ProfilePhotoAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? const Color(0xFFFF8B8B)
        : const Color(0xFF9DBBFF);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.055),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.085),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.13),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFFF2F5FB),
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.48),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 15,
              color: Colors.white.withValues(alpha: 0.42),
            ),
          ],
        ),
      ),
    );
  }
}


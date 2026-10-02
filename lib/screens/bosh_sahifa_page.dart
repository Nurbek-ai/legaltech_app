import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BoshSahifaPage extends StatefulWidget {
  const BoshSahifaPage({super.key});

  @override
  State<BoshSahifaPage> createState() => _BoshSahifaPageState();
}

class _BoshSahifaPageState extends State<BoshSahifaPage> {
  final _searchController = TextEditingController();

  static const _services = <_ServiceCardData>[
    _ServiceCardData(
      title: 'Shartnomani\nko‘rib chiqish',
      caption: 'Shartnoma va kelishuvlarni tekshirish',
      icon: CupertinoIcons.doc_text_search,
      colors: [Color(0xFF344D8A), Color(0xFF253762)],
      iconColor: Color(0xFFB1B6FF),
    ),
    _ServiceCardData(
      title: 'Konsultatsiya',
      caption: 'Mutaxassis bilan huquqiy maslahat',
      icon: CupertinoIcons.person_2,
      colors: [Color(0xFF7A6034), Color(0xFF4B3B31)],
      iconColor: Color(0xFFFFCB7E),
    ),
    _ServiceCardData(
      title: 'Hujjat\ntayyorlash',
      caption: 'Kerakli hujjatni tez va oson yarating',
      icon: CupertinoIcons.doc_plaintext,
      colors: [Color(0xFF6B394C), Color(0xFF432B3E)],
      iconColor: Color(0xFFFF9EAF),
    ),
    _ServiceCardData(
      title: 'Hujjatlar\nreytingi',
      caption: 'Hujjatlaringiz xavfsizlik bahosi',
      icon: CupertinoIcons.doc_checkmark,
      colors: [Color(0xFF2C6D62), Color(0xFF214A4C)],
      iconColor: Color(0xFF85E1B8),
    ),
    _ServiceCardData(
      title: 'Hujjat\nizlash',
      caption: 'Saqlangan hujjatlarni bir joydan toping',
      icon: CupertinoIcons.folder,
      colors: [Color(0xFF315C72), Color(0xFF253C5A)],
      iconColor: Color(0xFF93D5FF),
    ),
    _ServiceCardData(
      title: 'Elektron\nimzo',
      caption: 'Hujjatlarni ishonchli imzolang',
      icon: CupertinoIcons.signature,
      colors: [Color(0xFF594177), Color(0xFF3A2A57)],
      iconColor: Color(0xFFD1AEFF),
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _buildHomeContent();
  }

  Widget _buildHomeContent() {
    return CustomScrollView(
      key: const ValueKey('home'),
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildTopBar()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 29, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildGreeting()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
          sliver: SliverToBoxAdapter(child: _buildSearch()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 122),
          sliver: SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _ServiceCard(
                data: _services[index],
                onTap: () => _showServiceMessage(_services[index]),
              ),
              childCount: _services.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 158,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar() {
    return Row(
      children: [
        const Text(
          'YAN360',
          style: TextStyle(
            color: Color(0xFFF3F6FF),
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.4,
          ),
        ),
        const Spacer(),
        Semantics(
          button: true,
          label: 'Bildirishnomalar',
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.075),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.10),
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(
                  CupertinoIcons.bell,
                  size: 19,
                  color: Colors.white.withOpacity(0.82),
                ),
                Positioned(
                  top: 9,
                  right: 10,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF7D7D),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGreeting() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Xush\nkelibsiz',
          style: TextStyle(
            color: Color(0xFFF5F3F0),
            fontFamily: 'serif',
            fontSize: 33,
            fontWeight: FontWeight.w400,
            height: 0.98,
            letterSpacing: -0.9,
          ),
        ),
      ],
    );
  }

  Widget _buildSearch() {
    return CupertinoTextField(
      controller: _searchController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      keyboardType: TextInputType.text,
      textInputAction: TextInputAction.search,
      style: const TextStyle(
        color: Color(0xFFF2F5FA),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      placeholder: 'Xizmatni izlang',
      placeholderStyle: const TextStyle(
        color: Color(0xFF8793A3),
        fontSize: 14,
      ),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 16, right: 11),
        child: Icon(
          CupertinoIcons.search,
          color: Color(0xFF8A98AA),
          size: 18,
        ),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF273546).withOpacity(0.88),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.white.withOpacity(0.105),
        ),
      ),
      cursorColor: const Color(0xFFADC4FF),
    );
  }



  void _showServiceMessage(_ServiceCardData service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${service.title.replaceAll('\n', ' ')} — tez orada'),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 98),
        backgroundColor: const Color(0xFF2A3D58),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}

class _ServiceCardData {
  final String title;
  final String caption;
  final IconData icon;
  final List<Color> colors;
  final Color iconColor;

  const _ServiceCardData({
    required this.title,
    required this.caption,
    required this.icon,
    required this.colors,
    required this.iconColor,
  });
}

class _ServiceCard extends StatelessWidget {
  final _ServiceCardData data;
  final VoidCallback onTap;

  const _ServiceCard({
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: data.title.replaceAll('\n', ' '),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 13, 13, 13),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: data.colors,
            ),
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: data.colors.last.withOpacity(0.28),
                blurRadius: 13,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 37,
                    height: 37,
                    decoration: BoxDecoration(
                      color: data.iconColor.withOpacity(0.19),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(
                        color: data.iconColor.withOpacity(0.24),
                      ),
                    ),
                    child: Icon(
                      data.icon,
                      size: 20,
                      color: data.iconColor,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    CupertinoIcons.arrow_up_right,
                    size: 15,
                    color: Colors.white.withOpacity(0.42),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                data.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFF2F5FA),
                  fontSize: 14.2,
                  fontWeight: FontWeight.w700,
                  height: 1.05,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                data.caption,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.58),
                  fontSize: 9.2,
                  height: 1.14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}



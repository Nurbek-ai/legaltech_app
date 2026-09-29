import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'screens/bosh_sahifa_page.dart';
import 'screens/tarix_page.dart';
import 'screens/hujjatlar_page.dart';
import 'screens/profil_page.dart';
import 'shared/dashboard_background.dart';
import 'shared/dashboard_navigation.dart';

void main() {
  runApp(const YAN360App());
}

class YAN360App extends StatelessWidget {
  const YAN360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'YAN360',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF050A14),
        fontFamily: 'Roboto',
        useMaterial3: true,
      ),
      home: const IntroScreen(),
    );
  }
}

enum AuthMode { phoneLogin, emailLogin, phoneRegister, emailRegister }

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  AuthMode _mode = AuthMode.phoneLogin;

  bool _phoneCodeSent = false;
  bool _emailCodeSent = false;

  late final AnimationController _entranceController;

  final _loginPhoneController = TextEditingController(text: '+998 ');
  final _loginCodeController = TextEditingController();

  final _phoneRegisterFirstNameController = TextEditingController();
  final _phoneRegisterSurnameController = TextEditingController();
  final _phoneRegisterPhoneController =
      TextEditingController(text: '+998 ');
  final _phoneRegisterCodeController = TextEditingController();

  final _emailLoginController = TextEditingController();

  final _emailRegisterFirstNameController = TextEditingController();
  final _emailRegisterSurnameController = TextEditingController();
  final _emailRegisterEmailController = TextEditingController();
  final _emailRegisterCodeController = TextEditingController();

  bool get _isLogin =>
      _mode == AuthMode.phoneLogin || _mode == AuthMode.emailLogin;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();

    _putCursorAtEnd(_loginPhoneController);
    _putCursorAtEnd(_phoneRegisterPhoneController);
  }

  void _putCursorAtEnd(TextEditingController controller) {
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();

    _loginPhoneController.dispose();
    _loginCodeController.dispose();

    _phoneRegisterFirstNameController.dispose();
    _phoneRegisterSurnameController.dispose();
    _phoneRegisterPhoneController.dispose();
    _phoneRegisterCodeController.dispose();

    _emailLoginController.dispose();

    _emailRegisterFirstNameController.dispose();
    _emailRegisterSurnameController.dispose();
    _emailRegisterEmailController.dispose();
    _emailRegisterCodeController.dispose();

    super.dispose();
  }

  void _goToLogin() {
    FocusScope.of(context).unfocus();

    setState(() {
      _mode = AuthMode.phoneLogin;
      _phoneCodeSent = false;
      _emailCodeSent = false;
    });
  }

  void _goToEmailLogin() {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = AuthMode.emailLogin;
      _emailCodeSent = false;
    });
  }

  void _goToPhoneRegister() {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = AuthMode.phoneRegister;
      _phoneCodeSent = false;
    });
  }

  void _goToEmailRegister() {
    FocusScope.of(context).unfocus();
    setState(() {
      _mode = AuthMode.emailRegister;
      _emailCodeSent = false;
    });
  }

  String get _title {
    switch (_mode) {
      case AuthMode.phoneLogin:
        return 'Xush kelibsiz';
      case AuthMode.emailLogin:
        return 'Email orqali kirish';
      case AuthMode.phoneRegister:
      case AuthMode.emailRegister:
        return 'Yangi hisob';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case AuthMode.phoneLogin:
        return 'Telefon raqamingiz orqali davom eting';
      case AuthMode.emailLogin:
        return 'Email manzilingiz orqali davom eting';
      case AuthMode.phoneRegister:
        return 'Telefon raqami orqali yangi hisob yarating';
      case AuthMode.emailRegister:
        return 'Email orqali yangi hisob yarating';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const _ProfessionalBackground(),
          const _LogoWatermark(),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                20,
                22,
                20,
                24 + bottomInset,
              ),
              child: Column(
                children: [
                  _buildBrand(),
                  const SizedBox(height: 27),
                  _buildAuthCard(),
                  const SizedBox(height: 17),
                  _buildFooter(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrand() {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Column(
          children: [
            Container(
              width: 154,
              height: 154,
              padding: const EdgeInsets.all(19),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.12),
                    const Color(0xFF6E96F5).withValues(alpha: 0.055),
                    Colors.white.withValues(alpha: 0.018),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4B78E8).withValues(alpha: 0.16),
                    blurRadius: 48,
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 30,
                    offset: const Offset(0, 16),
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 17),
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFFFFFFFF),
                    Color(0xFFDCE7FF),
                    Color(0xFF86A9FF),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'YAN360',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 6.5,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Yuridik xizmatlar uchun yagona makon',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                letterSpacing: 0.15,
                color: Colors.white.withValues(alpha: 0.43),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(17, 19, 17, 17),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.052),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.105),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.34),
                blurRadius: 35,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!_isLogin) _buildBackButton(),
              if (!_isLogin) const SizedBox(height: 7),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: Column(
                  key: ValueKey(_mode),
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _subtitle,
                      style: TextStyle(
                        fontSize: 12.8,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 19),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey('$_mode-$_phoneCodeSent-$_emailCodeSent'),
                  child: _buildCurrentForm(),
                ),
              ),
              const SizedBox(height: 16),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _goToLogin,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.chevron_left,
              size: 15,
              color: const Color(0xFF91B0FF),
            ),
            const SizedBox(width: 4),
            Text(
              'Kirishga qaytish',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF91B0FF).withValues(alpha: 0.9),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentForm() {
    switch (_mode) {
      case AuthMode.phoneLogin:
        return _buildPhoneLogin();
      case AuthMode.emailLogin:
        return _buildEmailLogin();
      case AuthMode.phoneRegister:
        return _buildPhoneRegister();
      case AuthMode.emailRegister:
        return _buildEmailRegister();
    }
  }

  Widget _buildPhoneLogin() {
    return Column(
      children: [
        _UzbekPhoneField(
          controller: _loginPhoneController,
        ),
        if (_phoneCodeSent) ...[
          const SizedBox(height: 11),
          _LiquidTextField(
            controller: _loginCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 16),
          _LiquidPrimaryButton(
            label: 'Kirish',
            icon: CupertinoIcons.arrow_right,
            onPressed: _loginWithPhone,
          ),
        ] else ...[
          const SizedBox(height: 16),
          _LiquidPrimaryButton(
            label: 'SMS kodni yuborish',
            icon: CupertinoIcons.paperplane,
            onPressed: _sendPhoneCodeForLogin,
          ),
        ],
      ],
    );
  }

  Widget _buildEmailLogin() {
    return Column(
      children: [
        _LiquidTextField(
          controller: _emailLoginController,
          hintText: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          icon: CupertinoIcons.mail,
        ),
        if (_emailCodeSent) ...[
          const SizedBox(height: 11),
          _LiquidTextField(
            controller: _loginCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 16),
          _LiquidPrimaryButton(
            label: 'Kirish',
            icon: CupertinoIcons.arrow_right,
            onPressed: _loginWithEmail,
          ),
        ] else ...[
          const SizedBox(height: 16),
          _LiquidPrimaryButton(
            label: 'Kodni yuborish',
            icon: CupertinoIcons.paperplane,
            onPressed: _sendEmailCodeForLogin,
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneRegister() {
    return Column(
      children: [
        _LiquidTextField(
          controller: _phoneRegisterFirstNameController,
          hintText: 'Ism',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person,
        ),
        const SizedBox(height: 10),
        _LiquidTextField(
          controller: _phoneRegisterSurnameController,
          hintText: 'Familiya',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person,
        ),
        const SizedBox(height: 10),
        _UzbekPhoneField(
          controller: _phoneRegisterPhoneController,
        ),
        if (_phoneCodeSent) ...[
          const SizedBox(height: 11),
          _LiquidTextField(
            controller: _phoneRegisterCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 16),
          _LiquidPrimaryButton(
            label: 'Ro‘yxatdan o‘tish',
            icon: CupertinoIcons.person_add,
            onPressed: _completePhoneRegistration,
          ),
        ] else ...[
          const SizedBox(height: 16),
          _LiquidPrimaryButton(
            label: 'SMS kodni yuborish',
            icon: CupertinoIcons.paperplane,
            onPressed: _sendPhoneCodeForRegistration,
          ),
        ],
      ],
    );
  }

  Widget _buildEmailRegister() {
    return Column(
      children: [
        _LiquidTextField(
          controller: _emailRegisterFirstNameController,
          hintText: 'Ism',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person,
        ),
        const SizedBox(height: 10),
        _LiquidTextField(
          controller: _emailRegisterSurnameController,
          hintText: 'Familiya',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person,
        ),
        const SizedBox(height: 10),
        _LiquidTextField(
          controller: _emailRegisterEmailController,
          hintText: 'name@example.com',
          keyboardType: TextInputType.emailAddress,
          icon: CupertinoIcons.mail,
        ),
        if (_emailCodeSent) ...[
          const SizedBox(height: 11),
          _LiquidTextField(
            controller: _emailRegisterCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 16),
          _LiquidPrimaryButton(
            label: 'Ro‘yxatdan o‘tish',
            icon: CupertinoIcons.person_add,
            onPressed: _completeEmailRegistration,
          ),
        ] else ...[
          const SizedBox(height: 16),
          _LiquidPrimaryButton(
            label: 'Kodni yuborish',
            icon: CupertinoIcons.paperplane,
            onPressed: _sendEmailCodeForRegistration,
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons() {
    if (_mode == AuthMode.phoneRegister ||
        _mode == AuthMode.emailRegister) {
      return Row(
        children: [
          Expanded(
            child: _LiquidSecondaryButton(
              icon: CupertinoIcons.phone,
              label: 'Telefon orqali',
              active: _mode == AuthMode.phoneRegister,
              onPressed: _goToPhoneRegister,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _LiquidSecondaryButton(
              icon: CupertinoIcons.mail,
              label: 'Email orqali',
              active: _mode == AuthMode.emailRegister,
              onPressed: _goToEmailRegister,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _LiquidSecondaryButton(
            icon: CupertinoIcons.mail,
            label: 'Email orqali',
            active: _mode == AuthMode.emailLogin,
            onPressed: _goToEmailLogin,
          ),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: _LiquidSecondaryButton(
            icon: CupertinoIcons.person_add,
            label: 'Ro‘yxatdan o‘tish',
            active: false,
            onPressed: _showRegistrationChoices,
          ),
        ),
      ],
    );
  }

  void _showRegistrationChoices() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (context) {
        return CupertinoActionSheet(
          title: const Text('Ro‘yxatdan o‘tish'),
          message: const Text(
            'Qaysi usul orqali yangi hisob yaratmoqchisiz?',
          ),
          actions: [
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _goToPhoneRegister();
              },
              child: const Text('Telefon orqali'),
            ),
            CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
                _goToEmailRegister();
              },
              child: const Text('Email orqali'),
            ),
          ],
          cancelButton: CupertinoActionSheetAction(
            onPressed: () => Navigator.pop(context),
            child: const Text('Bekor qilish'),
          ),
        );
      },
    );
  }

  void _sendPhoneCodeForLogin() {
    if (!_hasUzbekPhone(_loginPhoneController.text)) {
      _showMessage('Telefon raqamini to‘liq kiriting.');
      return;
    }

    setState(() => _phoneCodeSent = true);
    _showMessage('SMS orqali tasdiqlash kodi yuborildi.');
  }

  void _loginWithPhone() {
    if (_loginCodeController.text.trim().isEmpty) {
      _showMessage('Tasdiqlash kodini kiriting.');
      return;
    }

    _openDashboard();
  }

  void _sendEmailCodeForLogin() {
    if (_emailLoginController.text.trim().isEmpty) {
      _showMessage('Email manzilini kiriting.');
      return;
    }

    setState(() => _emailCodeSent = true);
    _showMessage('Tasdiqlash kodi yuborildi.');
  }

  void _loginWithEmail() {
    if (_loginCodeController.text.trim().isEmpty) {
      _showMessage('Tasdiqlash kodini kiriting.');
      return;
    }

    _openDashboard();
  }

  void _sendPhoneCodeForRegistration() {
    if (_phoneRegisterFirstNameController.text.trim().isEmpty ||
        _phoneRegisterSurnameController.text.trim().isEmpty ||
        !_hasUzbekPhone(_phoneRegisterPhoneController.text)) {
      _showMessage('Ism, familiya va telefon raqamini kiriting.');
      return;
    }

    setState(() => _phoneCodeSent = true);
    _showMessage('SMS orqali tasdiqlash kodi yuborildi.');
  }

  void _completePhoneRegistration() {
    if (_phoneRegisterCodeController.text.trim().isEmpty) {
      _showMessage('Tasdiqlash kodini kiriting.');
      return;
    }

    _openDashboard();
  }

  void _sendEmailCodeForRegistration() {
    if (_emailRegisterFirstNameController.text.trim().isEmpty ||
        _emailRegisterSurnameController.text.trim().isEmpty ||
        _emailRegisterEmailController.text.trim().isEmpty) {
      _showMessage(
        'Ism, familiya va email manzilini kiriting.',
      );
      return;
    }

    setState(() => _emailCodeSent = true);
    _showMessage('Tasdiqlash kodi yuborildi.');
  }

  void _completeEmailRegistration() {
    if (_emailRegisterCodeController.text.trim().isEmpty) {
      _showMessage('Tasdiqlash kodini kiriting.');
      return;
    }

    _openDashboard();
  }

  void _openDashboard() {
    FocusScope.of(context).unfocus();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => const MainDashboard(),
      ),
    );
  }

  bool _hasUzbekPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 12 && digits.startsWith('998');
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'YAN LEGAL FIRM',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 2.6,
            color: Colors.white.withValues(alpha: 0.24),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Huquq • Ishonch • Texnologiya',
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 0.7,
            color: Colors.white.withValues(alpha: 0.18),
          ),
        ),
      ],
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;

    showCupertinoDialog<void>(
      context: context,
      builder: (context) {
        return CupertinoAlertDialog(
          title: const Text('YAN360'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(message),
          ),
          actions: [
            CupertinoDialogAction(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}


class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1422),
      body: Stack(
        children: [
          const DashboardBackground(),
          SafeArea(
            bottom: false,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeIn,
              child: _selectedTab == 3
                  ? const ProfilPage(key: ValueKey('profile'))
                  : _selectedTab == 2
                      ? const HujjatlarPage(key: ValueKey('documents'))
                      : _selectedTab == 1
                          ? const TarixPage(key: ValueKey('history'))
                          : const BoshSahifaPage(key: ValueKey('home')),
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    const items = <DashboardNavData>[
      DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
      DashboardNavData(CupertinoIcons.time, 'Tarix'),
      DashboardNavData(CupertinoIcons.doc_text, 'Hujjatlar'),
      DashboardNavData(CupertinoIcons.person, 'Profil'),
    ];

    return Positioned(
      left: 20,
      right: 20,
      bottom: 18 + MediaQuery.paddingOf(context).bottom,
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF283746).withValues(alpha: 0.96),
          borderRadius: BorderRadius.circular(23),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: List.generate(
            items.length,
            (index) => Expanded(
              child: DashboardNavItem(
                icon: items[index].icon,
                label: items[index].label,
                selected: _selectedTab == index,
                onTap: () => setState(() => _selectedTab = index),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfessionalBackground extends StatelessWidget {
  const _ProfessionalBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF08172F),
            Color(0xFF061020),
            Color(0xFF030812),
          ],
          stops: [0.0, 0.48, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // One soft light source at the top. No competing abstract blobs.
          Positioned(
            top: -170,
            left: -70,
            child: Container(
              width: 470,
              height: 390,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(240),
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF3269D8).withValues(alpha: 0.16),
                    const Color(0xFF3269D8).withValues(alpha: 0.035),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // A tiny amount of light at the bottom for depth.
          Positioned(
            bottom: -210,
            right: -150,
            child: Container(
              width: 430,
              height: 430,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    const Color(0xFF214EAD).withValues(alpha: 0.075),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoWatermark extends StatelessWidget {
  const _LogoWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Center(
        child: Transform.translate(
          offset: const Offset(0, 150),
          child: ImageFiltered(
            imageFilter: ImageFilter.blur(
              sigmaX: 18,
              sigmaY: 18,
            ),
            child: ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Color(0xFF4776D8),
                BlendMode.srcIn,
              ),
              child: Opacity(
                opacity: 0.020,
                child: Image.asset(
                  'assets/logo.png',
                  width: 520,
                  height: 520,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UzbekPhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _UzbekPhoneField({
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      placeholder: '** *** ** **',
      placeholderStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 14.5,
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 15, right: 9),
        child: Icon(
          CupertinoIcons.phone,
          size: 18,
          color: Colors.white.withValues(alpha: 0.52),
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.052),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.095),
        ),
      ),
      cursorColor: const Color(0xFF86A9FF),
    );
  }
}

class _LiquidTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData icon;

  const _LiquidTextField({
    required this.controller,
    required this.hintText,
    required this.keyboardType,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      keyboardType: keyboardType,
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 16,
      ),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      placeholder: hintText,
      placeholderStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.35),
        fontSize: 14.5,
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 15, right: 9),
        child: Icon(
          icon,
          size: 18,
          color: Colors.white.withValues(alpha: 0.52),
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.052),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.095),
        ),
      ),
      cursorColor: const Color(0xFF86A9FF),
    );
  }
}

class _LiquidPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _LiquidPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_LiquidPrimaryButton> createState() => _LiquidPrimaryButtonState();
}

class _LiquidPrimaryButtonState extends State<_LiquidPrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.985 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Color(0xFF709AFF),
                Color(0xFF3768DC),
              ],
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.19),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3E70E2).withValues(alpha: 0.27),
                blurRadius: 21,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.05,
                ),
              ),
              const SizedBox(width: 9),
              Icon(widget.icon, size: 17),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiquidSecondaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _LiquidSecondaryButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  @override
  State<_LiquidSecondaryButton> createState() =>
      _LiquidSecondaryButtonState();
}

class _LiquidSecondaryButtonState extends State<_LiquidSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: widget.active
                ? const Color(0xFF5E88F5).withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.042),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.active
                  ? const Color(0xFF769CFF).withValues(alpha: 0.43)
                  : Colors.white.withValues(alpha: 0.095),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.active
                    ? const Color(0xFFA8BEFF)
                    : Colors.white.withValues(alpha: 0.61),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.2,
                    fontWeight: FontWeight.w600,
                    color: widget.active
                        ? const Color(0xFFBBD0FF)
                        : Colors.white.withValues(alpha: 0.70),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

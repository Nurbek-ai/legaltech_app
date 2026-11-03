import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/bosh_sahifa_page.dart';
import 'screens/hujjatlar_page.dart';
import 'screens/profil_page.dart';
import 'screens/tarix_page.dart';
import 'shared/dashboard_background.dart';
import 'shared/dashboard_navigation.dart';
import 'shared/user_profile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: Color(0xFF020610),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const YAN360App());
}

/// Color tokens calibrated to the electric-cyan & deep-sapphire Lady Justice artwork.
class _AuthTheme {
  static const Color abyssNavy = Color(0xFF020611);
  static const Color midnightSapphire = Color(0xFF06132C);
  static const Color cardGlassTop = Color(0xFF081A3A);
  static const Color cardGlassBottom = Color(0xFF030B1B);
  static const Color inputSurface = Color(0xFF030B1A);

  static const Color electricCyan = Color(0xFF00D4FF);
  static const Color luminousAzure = Color(0xFF0088FF);
  static const Color royalSapphire = Color(0xFF0051D5);
  static const Color iceCyan = Color(0xFF6AE6FF);
  static const Color softSky = Color(0xFFA4C8F0);
  static const Color crispWhite = Color(0xFFF5FAFF);
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
        scaffoldBackgroundColor: _AuthTheme.abyssNavy,
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: const ColorScheme.dark(
          primary: _AuthTheme.electricCyan,
          secondary: _AuthTheme.luminousAzure,
          surface: _AuthTheme.midnightSapphire,
          onSurface: _AuthTheme.crispWhite,
        ),
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
  final _phoneRegisterPhoneController = TextEditingController(text: '+998 ');
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
      duration: const Duration(milliseconds: 950),
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

  String get _badgeText {
    switch (_mode) {
      case AuthMode.phoneLogin:
        return 'RAQAMLI YURIDIK EKOTIZIM';
      case AuthMode.emailLogin:
        return 'KORPORATIV VA SHAXSIY KIRISH';
      case AuthMode.phoneRegister:
      case AuthMode.emailRegister:
        return 'YANGI MIJOZ RO‘YXATI';
    }
  }

  String get _title {
    switch (_mode) {
      case AuthMode.phoneLogin:
        return 'Xush kelibsiz';
      case AuthMode.emailLogin:
        return 'Email orqali kirish';
      case AuthMode.phoneRegister:
      case AuthMode.emailRegister:
        return 'Yangi hisob yaratish';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case AuthMode.phoneLogin:
        return 'Tasdiqlangan telefon raqamingiz orqali tizimga kiring';
      case AuthMode.emailLogin:
        return 'Elektron pochta manzilingiz orqali davom eting';
      case AuthMode.phoneRegister:
        return 'Huquqiy xizmatlardan foydalanish uchun ro‘yxatdan o‘ting';
      case AuthMode.emailRegister:
        return 'Email manzilingiz orqali shaxsiy kabinet oching';
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom;
    final keyboardOpen = bottomInset > 40;

    return Scaffold(
      backgroundColor: _AuthTheme.abyssNavy,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _LadyJusticeBackground(),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    20 + (bottomInset > 0 ? 12 : 0),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: (constraints.maxHeight - 30).clamp(
                        0.0,
                        double.infinity,
                      ),
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopBrandBar(),
                          if (!keyboardOpen) ...[
                            const Spacer(),
                            _buildHeroTagline(),
                            const SizedBox(height: 16),
                          ] else
                            const SizedBox(height: 18),
                          _buildAuthCard(),
                          const SizedBox(height: 16),
                          _buildFooter(),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Prominent, standalone firm emblem with NO circular border or background box.
  Widget _buildTopBrandBar() {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, -0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.0, 0.70, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Standalone large logo (84x84) with subtle ambient glow — NO circular border
            SizedBox(
              width: 84,
              height: 84,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: _AuthTheme.electricCyan.withValues(alpha: 0.32),
                          blurRadius: 32,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/logo.png',
                    width: 84,
                    height: 84,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (_, _, _) => const Icon(
                      CupertinoIcons.shield_lefthalf_fill,
                      color: _AuthTheme.iceCyan,
                      size: 48,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: TextSpan(
                      children: [
                        const TextSpan(
                          text: 'YAN',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.2,
                            height: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: '360',
                          style: TextStyle(
                            color: _AuthTheme.electricCyan,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 3.2,
                            height: 1.0,
                            shadows: [
                              Shadow(
                                color: _AuthTheme.electricCyan.withValues(
                                  alpha: 0.65,
                                ),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Yuridik xizmatlar uchun yagona makon',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.2,
                      color: _AuthTheme.softSky.withValues(alpha: 0.86),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _AuthTheme.midnightSapphire.withValues(alpha: 0.68),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _AuthTheme.iceCyan.withValues(alpha: 0.30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(
                    CupertinoIcons.checkmark_shield_fill,
                    size: 13,
                    color: _AuthTheme.electricCyan,
                  ),
                  SizedBox(width: 5),
                  Text(
                    '24/7',
                    style: TextStyle(
                      color: _AuthTheme.crispWhite,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroTagline() {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.18, 0.85, curve: Curves.easeOut),
    );

    return FadeTransition(
      opacity: fade,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _AuthTheme.abyssNavy.withValues(alpha: 0.58),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: _AuthTheme.electricCyan.withValues(alpha: 0.32),
            ),
            boxShadow: [
              BoxShadow(
                color: _AuthTheme.electricCyan.withValues(alpha: 0.14),
                blurRadius: 16,
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: _AuthTheme.electricCyan,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                _badgeText,
                style: const TextStyle(
                  color: _AuthTheme.iceCyan,
                  fontSize: 9.8,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuthCard() {
    final fade = CurvedAnimation(
      parent: _entranceController,
      curve: const Interval(0.15, 1.0, curve: Curves.easeOut),
    );

    final slide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.15, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: slide,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _AuthTheme.cardGlassTop.withValues(alpha: 0.78),
                    _AuthTheme.cardGlassBottom.withValues(alpha: 0.88),
                  ],
                ),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: _AuthTheme.iceCyan.withValues(alpha: 0.28),
                  width: 1.1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 34,
                    offset: const Offset(0, 18),
                  ),
                  BoxShadow(
                    color: _AuthTheme.luminousAzure.withValues(alpha: 0.16),
                    blurRadius: 28,
                    spreadRadius: -2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 1.5,
                    margin: const EdgeInsets.symmetric(horizontal: 28),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          _AuthTheme.iceCyan.withValues(alpha: 0.75),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (!_isLogin) _buildBackButton(),
                        if (!_isLogin) const SizedBox(height: 8),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          child: Column(
                            key: ValueKey(_mode),
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _title,
                                style: const TextStyle(
                                  color: _AuthTheme.crispWhite,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _subtitle,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.3,
                                  color: _AuthTheme.softSky.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 240),
                          switchInCurve: Curves.easeOutCubic,
                          switchOutCurve: Curves.easeIn,
                          child: KeyedSubtree(
                            key: ValueKey(
                              '$_mode-$_phoneCodeSent-$_emailCodeSent',
                            ),
                            child: _buildCurrentForm(),
                          ),
                        ),
                        const SizedBox(height: 15),
                        _buildNavigationButtons(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _goToLogin,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: _AuthTheme.electricCyan.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: _AuthTheme.iceCyan.withValues(alpha: 0.30),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(
              CupertinoIcons.chevron_left,
              size: 14,
              color: _AuthTheme.iceCyan,
            ),
            SizedBox(width: 4),
            Text(
              'Kirishga qaytish',
              style: TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w600,
                color: _AuthTheme.iceCyan,
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
            icon: CupertinoIcons.lock_shield,
          ),
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Tizimga kirish',
            icon: CupertinoIcons.arrow_right,
            onPressed: _loginWithPhone,
          ),
        ] else ...[
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'SMS kodni yuborish',
            icon: CupertinoIcons.paperplane_fill,
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
            icon: CupertinoIcons.lock_shield,
          ),
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Tizimga kirish',
            icon: CupertinoIcons.arrow_right,
            onPressed: _loginWithEmail,
          ),
        ] else ...[
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Kodni yuborish',
            icon: CupertinoIcons.paperplane_fill,
            onPressed: _sendEmailCodeForLogin,
          ),
        ],
      ],
    );
  }

  Widget _buildPhoneRegister() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LiquidTextField(
                controller: _phoneRegisterFirstNameController,
                hintText: 'Ism',
                keyboardType: TextInputType.name,
                icon: CupertinoIcons.person,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LiquidTextField(
                controller: _phoneRegisterSurnameController,
                hintText: 'Familiya',
                keyboardType: TextInputType.name,
                icon: CupertinoIcons.person,
              ),
            ),
          ],
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
            icon: CupertinoIcons.lock_shield,
          ),
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Ro‘yxatdan o‘tish',
            icon: CupertinoIcons.person_add_solid,
            onPressed: _completePhoneRegistration,
          ),
        ] else ...[
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'SMS kodni yuborish',
            icon: CupertinoIcons.paperplane_fill,
            onPressed: _sendPhoneCodeForRegistration,
          ),
        ],
      ],
    );
  }

  Widget _buildEmailRegister() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _LiquidTextField(
                controller: _emailRegisterFirstNameController,
                hintText: 'Ism',
                keyboardType: TextInputType.name,
                icon: CupertinoIcons.person,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _LiquidTextField(
                controller: _emailRegisterSurnameController,
                hintText: 'Familiya',
                keyboardType: TextInputType.name,
                icon: CupertinoIcons.person,
              ),
            ),
          ],
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
            icon: CupertinoIcons.lock_shield,
          ),
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Ro‘yxatdan o‘tish',
            icon: CupertinoIcons.person_add_solid,
            onPressed: _completeEmailRegistration,
          ),
        ] else ...[
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Kodni yuborish',
            icon: CupertinoIcons.paperplane_fill,
            onPressed: _sendEmailCodeForRegistration,
          ),
        ],
      ],
    );
  }

  Widget _buildNavigationButtons() {
    if (_mode == AuthMode.phoneRegister || _mode == AuthMode.emailRegister) {
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
            icon: _mode == AuthMode.emailLogin
                ? CupertinoIcons.phone
                : CupertinoIcons.mail,
            label: _mode == AuthMode.emailLogin
                ? 'Telefon orqali'
                : 'Email orqali',
            active: _mode == AuthMode.emailLogin,
            onPressed: _mode == AuthMode.emailLogin
                ? _goToLogin
                : _goToEmailLogin,
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

    final phone = _loginPhoneController.text.trim();
    userProfile.value = userProfile.value.copyWith(phone: phone);
    ActivityHistoryRepository.instance.record(
      title: 'Tizimga telefon orqali kirildi',
      description: 'Tasdiqlangan raqam: $phone',
      category: ActivityCategory.profile,
      statusLabel: 'Tasdiqlandi',
    );
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

    final email = _emailLoginController.text.trim();
    if (email.isNotEmpty) {
      userProfile.value = userProfile.value.copyWith(email: email);
      ActivityHistoryRepository.instance.record(
        title: 'Tizimga email orqali kirildi',
        description: 'Tasdiqlangan email: $email',
        category: ActivityCategory.profile,
        statusLabel: 'Tasdiqlandi',
      );
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

    final fullName =
        '${_phoneRegisterFirstNameController.text.trim()} ${_phoneRegisterSurnameController.text.trim()}'
            .trim();
    final phone = _phoneRegisterPhoneController.text.trim();
    userProfile.value = userProfile.value.copyWith(
      displayName: fullName.isEmpty ? userProfile.value.displayName : fullName,
      phone: phone,
    );
    ActivityHistoryRepository.instance.record(
      title: 'Yangi foydalanuvchi ro‘yxatdan o‘tdi',
      description: '$fullName • $phone',
      category: ActivityCategory.profile,
      statusLabel: 'Yangi hisob',
    );
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

    final fullName =
        '${_emailRegisterFirstNameController.text.trim()} ${_emailRegisterSurnameController.text.trim()}'
            .trim();
    final email = _emailRegisterEmailController.text.trim();
    userProfile.value = userProfile.value.copyWith(
      displayName: fullName.isEmpty ? userProfile.value.displayName : fullName,
      email: email.isEmpty ? userProfile.value.email : email,
    );
    ActivityHistoryRepository.instance.record(
      title: 'Yangi foydalanuvchi (Email) ro‘yxatdan o‘tdi',
      description: '$fullName • $email',
      category: ActivityCategory.profile,
      statusLabel: 'Yangi hisob',
    );
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
            fontSize: 10.2,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.8,
            color: _AuthTheme.iceCyan.withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Huquq • Ishonch • Texnologiya',
          style: TextStyle(
            fontSize: 9.5,
            letterSpacing: 0.8,
            color: _AuthTheme.softSky.withValues(alpha: 0.52),
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

class _LadyJusticeBackground extends StatelessWidget {
  const _LadyJusticeBackground();

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: _AuthTheme.abyssNavy),
        Image.asset(
          'assets/login_bg.jpg',
          fit: BoxFit.cover,
          alignment: const Alignment(0.15, -0.30),
          filterQuality: FilterQuality.high,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF041026),
                    Color(0xFF061B3A),
                    Color(0xFF020611),
                  ],
                ),
              ),
            );
          },
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              stops: const [0.0, 0.16, 0.44, 0.68, 1.0],
              colors: [
                _AuthTheme.abyssNavy.withValues(alpha: 0.52),
                _AuthTheme.abyssNavy.withValues(alpha: 0.10),
                _AuthTheme.abyssNavy.withValues(alpha: 0.18),
                _AuthTheme.abyssNavy.withValues(alpha: 0.72),
                _AuthTheme.abyssNavy.withValues(alpha: 0.94),
              ],
            ),
          ),
        ),
        Positioned(
          bottom: -120,
          right: -90,
          child: IgnorePointer(
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _AuthTheme.electricCyan.withValues(alpha: 0.14),
                    _AuthTheme.luminousAzure.withValues(alpha: 0.04),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

  void _switchToTab(int index) {
    if (index >= 0 && index <= 3 && mounted) {
      setState(() => _selectedTab = index);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030917),
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
                          : BoshSahifaPage(
                              key: const ValueKey('home'),
                              onNavigateToTab: _switchToTab,
                            ),
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
      left: 18,
      right: 18,
      bottom: 16 + MediaQuery.of(context).padding.bottom,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF0E254B).withValues(alpha: 0.88),
                  const Color(0xFF061329).withValues(alpha: 0.94),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: _AuthTheme.iceCyan.withValues(alpha: 0.26),
                width: 1.1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.45),
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
                    onTap: () => _switchToTab(index),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _UzbekPhoneField extends StatefulWidget {
  final TextEditingController controller;

  const _UzbekPhoneField({
    required this.controller,
  });

  @override
  State<_UzbekPhoneField> createState() => _UzbekPhoneFieldState();
}

class _UzbekPhoneFieldState extends State<_UzbekPhoneField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: _AuthTheme.inputSurface.withValues(alpha: _focused ? 0.88 : 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused
              ? _AuthTheme.electricCyan.withValues(alpha: 0.78)
              : _AuthTheme.iceCyan.withValues(alpha: 0.22),
          width: _focused ? 1.3 : 1.0,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: _AuthTheme.electricCyan.withValues(alpha: 0.20),
                  blurRadius: 16,
                ),
              ]
            : const [],
      ),
      child: CupertinoTextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.phone,
        padding: const EdgeInsets.symmetric(
          horizontal: 15,
          vertical: 15.5,
        ),
        style: const TextStyle(
          color: _AuthTheme.crispWhite,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
        placeholder: '** *** ** **',
        placeholderStyle: TextStyle(
          color: _AuthTheme.softSky.withValues(alpha: 0.45),
          fontSize: 14.5,
          fontWeight: FontWeight.w400,
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Icon(
            CupertinoIcons.phone_fill,
            size: 17,
            color: _focused
                ? _AuthTheme.electricCyan
                : _AuthTheme.iceCyan.withValues(alpha: 0.75),
          ),
        ),
        decoration: const BoxDecoration(color: Colors.transparent),
        cursorColor: _AuthTheme.electricCyan,
      ),
    );
  }
}

class _LiquidTextField extends StatefulWidget {
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
  State<_LiquidTextField> createState() => _LiquidTextFieldState();
}

class _LiquidTextFieldState extends State<_LiquidTextField> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: _AuthTheme.inputSurface.withValues(alpha: _focused ? 0.88 : 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _focused
              ? _AuthTheme.electricCyan.withValues(alpha: 0.78)
              : _AuthTheme.iceCyan.withValues(alpha: 0.22),
          width: _focused ? 1.3 : 1.0,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: _AuthTheme.electricCyan.withValues(alpha: 0.20),
                  blurRadius: 16,
                ),
              ]
            : const [],
      ),
      child: CupertinoTextField(
        controller: widget.controller,
        focusNode: _focusNode,
        keyboardType: widget.keyboardType,
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 15.5,
        ),
        style: const TextStyle(
          color: _AuthTheme.crispWhite,
          fontSize: 15,
          fontWeight: FontWeight.w500,
        ),
        placeholder: widget.hintText,
        placeholderStyle: TextStyle(
          color: _AuthTheme.softSky.withValues(alpha: 0.45),
          fontSize: 14.2,
        ),
        prefix: Padding(
          padding: const EdgeInsets.only(left: 14, right: 6),
          child: Icon(
            widget.icon,
            size: 17,
            color: _focused
                ? _AuthTheme.electricCyan
                : _AuthTheme.iceCyan.withValues(alpha: 0.75),
          ),
        ),
        decoration: const BoxDecoration(color: Colors.transparent),
        cursorColor: _AuthTheme.electricCyan,
      ),
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
        scale: _pressed ? 0.982 : 1,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15.5, horizontal: 18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                _AuthTheme.electricCyan,
                _AuthTheme.luminousAzure,
                _AuthTheme.royalSapphire,
              ],
              stops: [0.0, 0.52, 1.0],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFA6F3FF).withValues(alpha: 0.55),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: _AuthTheme.luminousAzure.withValues(alpha: 0.42),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: _AuthTheme.electricCyan.withValues(alpha: 0.22),
                blurRadius: 12,
                spreadRadius: -1,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.25,
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                widget.icon,
                size: 17,
                color: Colors.white,
              ),
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
  State<_LiquidSecondaryButton> createState() => _LiquidSecondaryButtonState();
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
            horizontal: 10,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: widget.active
                ? _AuthTheme.electricCyan.withValues(alpha: 0.16)
                : _AuthTheme.inputSurface.withValues(alpha: 0.65),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.active
                  ? _AuthTheme.electricCyan.withValues(alpha: 0.62)
                  : _AuthTheme.iceCyan.withValues(alpha: 0.20),
              width: widget.active ? 1.2 : 1.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                size: 16,
                color: widget.active
                    ? _AuthTheme.electricCyan
                    : _AuthTheme.softSky.withValues(alpha: 0.80),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.0,
                    fontWeight: FontWeight.w600,
                    color: widget.active
                        ? _AuthTheme.crispWhite
                        : _AuthTheme.softSky.withValues(alpha: 0.88),
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
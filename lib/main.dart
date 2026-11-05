import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'screens/bosh_sahifa_page.dart';
import 'screens/hujjatlar_page.dart';
import 'screens/profil_page.dart';
import 'screens/services/advokat_yollash_page.dart';
import 'screens/services/alimony_claim_page.dart';
import 'screens/services/lawyer_draft_request_page.dart';
import 'screens/tarix_page.dart';
import 'services/alimony_claim_document_service.dart';
import 'shared/dashboard_background.dart';
import 'shared/dashboard_navigation.dart';
import 'shared/user_profile.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
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
        scaffoldBackgroundColor: const Color(0xFF102C60),
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
  UserRole _selectedLoginRole = UserRole.oddiy;

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
    _selectedLoginRole = userProfile.value.roleType;

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
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
        return 'Yangi hisob yaratish';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case AuthMode.phoneLogin:
        return 'Rolni tanlang va telefon raqamingiz orqali kiring';
      case AuthMode.emailLogin:
        return 'Email manzilingiz orqali tizimga kiring';
      case AuthMode.phoneRegister:
        return 'Telefon raqami orqali bepul ro‘yxatdan o‘ting';
      case AuthMode.emailRegister:
        return 'Email orqali yangi huquqiy hisob oching';
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          // Untinted Login Background Artwork (no color overlay hiding the image)
          const _LoginArtworkBackground(),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 18, 20, 24 + bottomInset),
              child: Column(
                children: <Widget>[
                  _buildBrand(),
                  const SizedBox(height: 22),
                  _buildAuthCard(),
                  const SizedBox(height: 16),
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
      begin: const Offset(0, 0.05),
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
          children: <Widget>[
            // Unboxed standalone firm logo (no circular border behind it)
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: const Color(0xFF55C6FF).withValues(alpha: 0.34),
                    blurRadius: 34,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/logo.png',
                fit: BoxFit.contain,
                cacheWidth: 240,
                errorBuilder: (_, __, ___) => const Icon(
                  CupertinoIcons.shield_lefthalf_fill,
                  size: 68,
                  color: Color(0xFF7CE7FF),
                ),
              ),
            ),
            const SizedBox(height: 12),
            ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: <Color>[
                    Color(0xFFFFFFFF),
                    Color(0xFFE2F1FF),
                    Color(0xFF7CE7FF),
                  ],
                ).createShader(bounds);
              },
              child: const Text(
                'YAN360',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 31,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 6.2,
                  height: 1,
                ),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Yuridik xizmatlar uchun yagona raqamli ekotizim',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
                color: Colors.white.withValues(alpha: 0.78),
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
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(17, 19, 17, 17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                const Color(0xFF8AB4F8).withValues(alpha: 0.34),
                const Color(0xFF4D79CA).withValues(alpha: 0.26),
                const Color(0xFF1F4287).withValues(alpha: 0.42),
                const Color(0xFF102859).withValues(alpha: 0.56),
              ],
              stops: const <double>[0.0, 0.32, 0.70, 1.0],
            ),
            border: Border.all(
              color: const Color(0xFFE0EEFF).withValues(alpha: 0.44),
              width: 1.25,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF040D24).withValues(alpha: 0.48),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!_isLogin) _buildBackButton(),
              if (!_isLogin) const SizedBox(height: 7),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          _title,
                          style: const TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          style: TextStyle(
                            fontSize: 12.4,
                            color: Colors.white.withValues(alpha: 0.80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedLoginRole.accentColor.withValues(
                        alpha: 0.20,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _selectedLoginRole.accentColor.withValues(
                          alpha: 0.65,
                        ),
                      ),
                    ),
                    child: Text(
                      _selectedLoginRole.shortBadge,
                      style: TextStyle(
                        color: _selectedLoginRole.accentColor,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildLoginRoleSelector(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey('$_mode-$_phoneCodeSent-$_emailCodeSent'),
                  child: _buildCurrentForm(),
                ),
              ),
              const SizedBox(height: 14),
              _buildNavigationButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRoleSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'KIRISH REJIMI (4 XIL PROFIL):',
          style: TextStyle(
            fontSize: 10.2,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: const Color(0xFFDCEBFF).withValues(alpha: 0.78),
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: UserRole.values.map((role) {
              final selected = _selectedLoginRole == role;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedLoginRole = role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: selected
                          ? LinearGradient(
                              colors: <Color>[
                                role.accentColor.withValues(alpha: 0.36),
                                role.secondaryColor.withValues(alpha: 0.42),
                              ],
                            )
                          : LinearGradient(
                              colors: <Color>[
                                Colors.white.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.06),
                              ],
                            ),
                      border: Border.all(
                        color: selected
                            ? role.accentColor.withValues(alpha: 0.85)
                            : Colors.white.withValues(alpha: 0.24),
                        width: selected ? 1.3 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          role.icon,
                          size: 14.5,
                          color: selected ? role.accentColor : Colors.white70,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          role.shortBadge,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.2,
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton() {
    return GestureDetector(
      onTap: _goToLogin,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const Icon(
              CupertinoIcons.chevron_left,
              size: 15,
              color: Color(0xFF91D2FF),
            ),
            const SizedBox(width: 4),
            Text(
              'Kirishga qaytish',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF91D2FF).withValues(alpha: 0.95),
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
      children: <Widget>[
        _UzbekPhoneField(controller: _loginPhoneController),
        if (_phoneCodeSent) ...<Widget>[
          const SizedBox(height: 11),
          _LiquidTextField(
            controller: _loginCodeController,
            hintText: 'Tasdiqlash kodi (masalan: 1234)',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Tizimga kirish',
            icon: CupertinoIcons.arrow_right,
            onPressed: _loginWithPhone,
          ),
        ] else ...<Widget>[
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
      children: <Widget>[
        _LiquidTextField(
          controller: _emailLoginController,
          hintText: 'name@yan360.uz',
          keyboardType: TextInputType.emailAddress,
          icon: CupertinoIcons.mail,
        ),
        if (_emailCodeSent) ...<Widget>[
          const SizedBox(height: 11),
          _LiquidTextField(
            controller: _loginCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Tizimga kirish',
            icon: CupertinoIcons.arrow_right,
            onPressed: _loginWithEmail,
          ),
        ] else ...<Widget>[
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
      children: <Widget>[
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
        _UzbekPhoneField(controller: _phoneRegisterPhoneController),
        if (_phoneCodeSent) ...<Widget>[
          const SizedBox(height: 11),
          _LiquidTextField(
            controller: _phoneRegisterCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Ro‘yxatdan o‘tish',
            icon: CupertinoIcons.person_add_solid,
            onPressed: _completePhoneRegistration,
          ),
        ] else ...<Widget>[
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
      children: <Widget>[
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
          hintText: 'name@yan360.uz',
          keyboardType: TextInputType.emailAddress,
          icon: CupertinoIcons.mail,
        ),
        if (_emailCodeSent) ...<Widget>[
          const SizedBox(height: 11),
          _LiquidTextField(
            controller: _emailRegisterCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 15),
          _LiquidPrimaryButton(
            label: 'Ro‘yxatdan o‘tish',
            icon: CupertinoIcons.person_add_solid,
            onPressed: _completeEmailRegistration,
          ),
        ] else ...<Widget>[
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
        children: <Widget>[
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

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
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
        ),
        const SizedBox(height: 9),
        _LiquidSecondaryButton(
          icon: CupertinoIcons.sparkles,
          label: 'Tezkor kirish (${_selectedLoginRole.label})',
          active: true,
          onPressed: () {
            userProfile.switchRole(_selectedLoginRole);
            _openDashboard();
          },
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
          actions: <Widget>[
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
    userProfile.value = userProfile.value.copyWith(
      phone: phone,
      roleType: _selectedLoginRole,
      role: _selectedLoginRole.label,
    );
    ActivityHistoryRepository.instance.record(
      title: 'Tizimga telefon orqali kirildi (${_selectedLoginRole.label})',
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
    userProfile.switchRole(_selectedLoginRole);
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
      roleType: _selectedLoginRole,
      role: _selectedLoginRole.label,
    );
    ActivityHistoryRepository.instance.record(
      title: 'Yangi foydalanuvchi ro‘yxatdan o‘tdi',
      description: '$fullName • $phone (${_selectedLoginRole.label})',
      category: ActivityCategory.profile,
      statusLabel: 'Yangi hisob',
    );
    _openDashboard();
  }

  void _sendEmailCodeForRegistration() {
    if (_emailRegisterFirstNameController.text.trim().isEmpty ||
        _emailRegisterSurnameController.text.trim().isEmpty ||
        _emailRegisterEmailController.text.trim().isEmpty) {
      _showMessage('Ism, familiya va email manzilini kiriting.');
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
    userProfile.switchRole(_selectedLoginRole);
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
      children: <Widget>[
        Text(
          'YAN LEGAL FIRM MCHJ',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.8,
            color: Colors.white.withValues(alpha: 0.62),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Huquq • Ishonch • Yuqori Texnologiya',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.8,
            color: Colors.white.withValues(alpha: 0.48),
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
          actions: <Widget>[
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

/// Renders the untinted login background image (`assets/login_bg.jpg`) without
/// applying the app's cobalt-blue gradient over it.
class _LoginArtworkBackground extends StatelessWidget {
  const _LoginArtworkBackground();

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/login_bg.jpg',
      fit: BoxFit.cover,
      alignment: Alignment.topCenter,
      errorBuilder: (_, __, ___) {
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: <Color>[
                Color(0xFF0E2656),
                Color(0xFF091B3E),
                Color(0xFF050F26),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Step 2: Dynamic 4-Role MainDashboard & Role-Adaptive Navigation
// ═══════════════════════════════════════════════════════════════════════════

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  late int _selectedTab;

  @override
  void initState() {
    super.initState();
    _selectedTab = widget.initialTab.clamp(0, 3);
    GeneratedDocumentRepository.instance.reload();
    ActivityHistoryRepository.instance.ensureInitialized();
  }

  /// Returns the exact 4 bottom navigation tabs specified for each role:
  /// - oddiy:     1. Bosh sahifa | 2. Arizalarim     | 3. Advokatxona | 4. Profil
  /// - mijoz:     1. Bosh sahifa | 2. Arizalarim     | 3. Advokatim   | 4. Profil
  /// - advokat:   1. Bosh sahifa | 2. Shartnomalarim | 3. Mijozlar    | 4. Profil
  /// - yordamchi: 1. Vazifalar   | 2. Hujjatlar      | 3. Mijozlar    | 4. Profil
  List<DashboardNavData> _navItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.oddiy:
        return const <DashboardNavData>[
          DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
          DashboardNavData(CupertinoIcons.doc_on_doc_fill, 'Arizalarim'),
          DashboardNavData(CupertinoIcons.building_2_fill, 'Advokatxona'),
          DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
        ];
      case UserRole.mijoz:
        return const <DashboardNavData>[
          DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
          DashboardNavData(
            CupertinoIcons.doc_on_doc_fill,
            'Arizalarim',
            badge: '-50%',
          ),
          DashboardNavData(
            CupertinoIcons.checkmark_seal_fill,
            'Advokatim',
            badge: 'VIP',
          ),
          DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
        ];
      case UserRole.advokat:
        return const <DashboardNavData>[
          DashboardNavData(CupertinoIcons.chart_bar_square_fill, 'Bosh sahifa'),
          DashboardNavData(
            CupertinoIcons.doc_checkmark_fill,
            'Shartnomalarim',
          ),
          DashboardNavData(CupertinoIcons.person_2_fill, 'Mijozlar'),
          DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
        ];
      case UserRole.yordamchi:
        return const <DashboardNavData>[
          DashboardNavData(CupertinoIcons.checkmark_rectangle_fill, 'Vazifalar'),
          DashboardNavData(CupertinoIcons.folder_fill, 'Hujjatlar'),
          DashboardNavData(CupertinoIcons.person_2_fill, 'Mijozlar'),
          DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
        ];
    }
  }

  Widget _buildActiveScreen(UserProfileData profile) {
    final role = profile.roleType;
    if (_selectedTab == 3) {
      return const ProfilPage(key: ValueKey<String>('tab-profil'));
    }

    switch (role) {
      case UserRole.oddiy:
        if (_selectedTab == 0) {
          return const BoshSahifaPage(key: ValueKey<String>('oddiy-home'));
        }
        if (_selectedTab == 1) {
          return _ArizalarimRoleView(
            key: const ValueKey<String>('oddiy-arizalarim'),
            profile: profile,
            onBrowseLawyers: () => setState(() => _selectedTab = 2),
          );
        }
        return _AdvokatxonaRoleView(
          key: const ValueKey<String>('oddiy-advokatxona'),
          profile: profile,
          onContractSigned: () {
            setState(() => _selectedTab = 2); // Opens Advokatim in Mijoz role
          },
        );

      case UserRole.mijoz:
        if (_selectedTab == 0) {
          return const BoshSahifaPage(key: ValueKey<String>('mijoz-home'));
        }
        if (_selectedTab == 1) {
          return _ArizalarimRoleView(
            key: const ValueKey<String>('mijoz-arizalarim'),
            profile: profile,
            onBrowseLawyers: () => setState(() => _selectedTab = 2),
          );
        }
        return _AdvokatimRoleView(
          key: const ValueKey<String>('mijoz-advokatim'),
          profile: profile,
        );

      case UserRole.advokat:
        if (_selectedTab == 0) {
          return _AdvokatHomeRoleView(
            key: const ValueKey<String>('advokat-home'),
            profile: profile,
            onOpenContracts: () => setState(() => _selectedTab = 1),
            onOpenClients: () => setState(() => _selectedTab = 2),
          );
        }
        if (_selectedTab == 1) {
          return _AdvokatContractsRoleView(
            key: const ValueKey<String>('advokat-contracts'),
            profile: profile,
          );
        }
        return _ClientsDirectoryRoleView(
          key: const ValueKey<String>('advokat-clients'),
          profile: profile,
          isAssistantView: false,
        );

      case UserRole.yordamchi:
        if (_selectedTab == 0) {
          return _AssistantTasksRoleView(
            key: const ValueKey<String>('yordamchi-tasks'),
            profile: profile,
            onOpenDocuments: () => setState(() => _selectedTab = 1),
            onOpenClients: () => setState(() => _selectedTab = 2),
          );
        }
        if (_selectedTab == 1) {
          return const HujjatlarPage(
            key: ValueKey<String>('yordamchi-documents'),
          );
        }
        return _ClientsDirectoryRoleView(
          key: const ValueKey<String>('yordamchi-clients'),
          profile: profile,
          isAssistantView: true,
        );
    }
  }

  void _showRoleSwitcherModal(BuildContext context, UserProfileData profile) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF1A3F86),
                Color(0xFF122E68),
                Color(0xFF0B1E47),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFDCEBFF).withValues(alpha: 0.38),
              width: 1.2,
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.sparkles,
                      color: Color(0xFF7CE7FF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'YAN360 Rol va Kabinetni Almashtirish',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
                      child: Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: Colors.white.withValues(alpha: 0.6),
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Har bir rol uchun maxsus pastki menyular, imtiyozlar va ish stoli avtomatik moslashadi:',
                  style: TextStyle(
                    color: const Color(0xFFDCEBFF).withValues(alpha: 0.78),
                    fontSize: 12.5,
                  ),
                ),
                const SizedBox(height: 14),
                ...UserRole.values.map((role) {
                  final active = profile.roleType == role;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlassWindow(
                      isHighlighted: active,
                      accentGlowColor: role.accentColor,
                      padding: const EdgeInsets.all(14),
                      onTap: () {
                        userProfile.switchRole(role);
                        Navigator.pop(sheetContext);
                      },
                      child: Row(
                        children: <Widget>[
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: <Color>[
                                  role.accentColor.withValues(alpha: 0.35),
                                  role.secondaryColor.withValues(alpha: 0.45),
                                ],
                              ),
                              border: Border.all(
                                color: role.accentColor.withValues(alpha: 0.75),
                              ),
                            ),
                            child: Icon(
                              role.icon,
                              color: Colors.white,
                              size: 21,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Row(
                                  children: <Widget>[
                                    Text(
                                      role.label,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 14.8,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(width: 7),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: role.accentColor.withValues(
                                          alpha: 0.22,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        role.shortBadge,
                                        style: TextStyle(
                                          color: role.accentColor,
                                          fontSize: 9.5,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  role.subtitle,
                                  style: TextStyle(
                                    color: const Color(
                                      0xFFDCEBFF,
                                    ).withValues(alpha: 0.80),
                                    fontSize: 11.8,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            active
                                ? CupertinoIcons.checkmark_circle_fill
                                : CupertinoIcons.chevron_right_circle,
                            color: active ? role.accentColor : Colors.white54,
                            size: 22,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfileData>(
      valueListenable: userProfile,
      builder: (context, profile, _) {
        final navItems = _navItemsForRole(profile.roleType);

        return Scaffold(
          backgroundColor: const Color(0xFF102C60),
          body: Stack(
            children: <Widget>[
              const DashboardBackground(),
              SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
                    // Sleek Role Status & Switcher Strip
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 6, 18, 4),
                      child: _RoleQuickStatusBar(
                        profile: profile,
                        onSwitchRoleTap: () =>
                            _showRoleSwitcherModal(context, profile),
                      ),
                    ),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 240),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        child: _buildActiveScreen(profile),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 18,
                right: 18,
                bottom: 14 + MediaQuery.of(context).padding.bottom,
                child: DashboardBottomNavigation(
                  selectedIndex: _selectedTab,
                  items: navItems,
                  accentColor: profile.roleType.accentColor,
                  onSelected: (index) => setState(() => _selectedTab = index),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RoleQuickStatusBar extends StatelessWidget {
  const _RoleQuickStatusBar({
    required this.profile,
    required this.onSwitchRoleTap,
  });

  final UserProfileData profile;
  final VoidCallback onSwitchRoleTap;

  @override
  Widget build(BuildContext context) {
    final role = profile.roleType;
    return GestureDetector(
      onTap: onSwitchRoleTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: <Color>[
              const Color(0xFF7CA3EA).withValues(alpha: 0.30),
              const Color(0xFF3E68B8).withValues(alpha: 0.28),
              const Color(0xFF1A3775).withValues(alpha: 0.50),
            ],
          ),
          border: Border.all(
            color: role.accentColor.withValues(alpha: 0.52),
            width: 1.05,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
              decoration: BoxDecoration(
                color: role.accentColor.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: role.accentColor.withValues(alpha: 0.72),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(role.icon, size: 13, color: role.accentColor),
                  const SizedBox(width: 5),
                  Text(
                    role.shortBadge,
                    style: TextStyle(
                      color: role.accentColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                profile.subscriptionStatusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFEAF3FF),
                  fontSize: 11.4,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.arrow_2_squarepath,
                    size: 12,
                    color: Colors.white,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Rol',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
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
}

// ═══════════════════════════════════════════════════════════════════════════
// 1. ARIZALARIM VIEW (For Oddiy & Mijoz roles — Tab 2)
// Combines generated DOCX petitions, lawyer draft requests & activity ledger
// ═══════════════════════════════════════════════════════════════════════════

class _ArizalarimRoleView extends StatefulWidget {
  const _ArizalarimRoleView({
    super.key,
    required this.profile,
    required this.onBrowseLawyers,
  });

  final UserProfileData profile;
  final VoidCallback onBrowseLawyers;

  @override
  State<_ArizalarimRoleView> createState() => _ArizalarimRoleViewState();
}

class _ArizalarimRoleViewState extends State<_ArizalarimRoleView> {
  int _subTab = 0; // 0 = Hujjatlar (.docx), 1 = Faoliyat va Arizalar tarixi

  @override
  Widget build(BuildContext context) {
    final isMijoz = widget.profile.roleType == UserRole.mijoz;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: LiquidGlassWindow(
            padding: const EdgeInsets.all(14),
            accentGlowColor: widget.profile.roleType.accentColor,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Mening Arizalarim va Hujjatlarim',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isMijoz
                                ? 'Shartnomali mijoz imtiyozi: Shablon arizalarga -50%, xizmatlarga -30% chegirma faol!'
                                : 'Barcha yaratilgan DOCX da’vo arizalari va advokatga yuborilgan so‘rovlar',
                            style: TextStyle(
                              color: const Color(
                                0xFFDCEBFF,
                              ).withValues(alpha: 0.84),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    LiquidActionButton(
                      label: isMijoz ? 'Yangi (-50%)' : 'Yangi ariza',
                      icon: CupertinoIcons.add_circled_solid,
                      compact: true,
                      accentColor: widget.profile.roleType.accentColor,
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const AlimonyClaimPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _LiquidTabSegmentButton(
                        label: 'Rasmiy DOCX Arizalar',
                        icon: CupertinoIcons.doc_richtext,
                        selected: _subTab == 0,
                        onTap: () => setState(() => _subTab = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _LiquidTabSegmentButton(
                        label: 'Murojaatlar Tarixi',
                        icon: CupertinoIcons.time_solid,
                        selected: _subTab == 1,
                        onTap: () => setState(() => _subTab = 1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: _subTab == 0 ? const HujjatlarPage() : const TarixPage(),
        ),
      ],
    );
  }
}

class _LiquidTabSegmentButton extends StatelessWidget {
  const _LiquidTabSegmentButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: <Color>[Color(0xFF5A95F5), Color(0xFF2E62C8)],
                )
              : LinearGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.10),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          border: Border.all(
            color: selected
                ? const Color(0xFF9ED8FF)
                : Colors.white.withValues(alpha: 0.20),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.2,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 2. ADVOKATXONA VIEW (For Oddiy Role — Tab 3)
// Filterable by Viloyat, Mutaxassislik, Tajriba; auto-sorted by feedback score;
// 1-tap "Shartnoma imzolash" upgrades user from Oddiy -> Mijoz!
// ═══════════════════════════════════════════════════════════════════════════

class _AdvokatxonaRoleView extends StatefulWidget {
  const _AdvokatxonaRoleView({
    super.key,
    required this.profile,
    required this.onContractSigned,
  });

  final UserProfileData profile;
  final VoidCallback onContractSigned;

  @override
  State<_AdvokatxonaRoleView> createState() => _AdvokatxonaRoleViewState();
}

class _AdvokatxonaRoleViewState extends State<_AdvokatxonaRoleView> {
  String _selectedRegion = 'Barchasi';
  String _selectedSpecialization = 'Barchasi';
  int _minExperienceYears = 0;

  List<LawyerDirectoryProfile> get _filteredAndRankedLawyers {
    final list = YanRoleDataCatalog.lawyers.where((lawyer) {
      final regionOk =
          _selectedRegion == 'Barchasi' || lawyer.region == _selectedRegion;
      final specOk =
          _selectedSpecialization == 'Barchasi' ||
          lawyer.specialization == _selectedSpecialization;
      final expOk = lawyer.experienceYears >= _minExperienceYears;
      return regionOk && specOk && expOk;
    }).toList();

    // Automatically sort by client feedback & rating score (highest first)
    list.sort((a, b) => b.rankingScore.compareTo(a.rankingScore));
    return list;
  }

  void _signContractWithLawyer(LawyerDirectoryProfile lawyer) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Yuridik yordam shartnomasi'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${lawyer.fullName} (${lawyer.region}) bilan rasmiy elektron shartnoma imzolaysizmi?\n\n'
              '• Dastlabki 3 oy ilova obunasi BEPUL (so‘ng \$3/oy)\n'
              '• Barcha xizmatlarga 30% chegirma\n'
              '• Konsultatsiyaga 20% chegirma\n'
              '• Shablon arizalarga 50% chegirma\n'
              '• Profil maqomingiz "Shartnomali mijoz" ga o‘tadi!',
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Bekor qilish'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(dialogContext);
                final contractNo =
                    'SH-2026/${100 + DateTime.now().millisecondsSinceEpoch % 899}';
                userProfile.switchRole(
                  UserRole.mijoz,
                  lawyerId: lawyer.id,
                  contractNo: contractNo,
                );
                ActivityHistoryRepository.instance.record(
                  title: 'Advokat bilan shartnoma imzolandi ($contractNo)',
                  description:
                      '${lawyer.fullName} bilan shartnoma tuzildi. 3 oylik bepul MIJOZ VIP imtiyozi faollashdi.',
                  category: ActivityCategory.lawyer,
                  statusLabel: 'Shartnoma faol',
                );
                widget.onContractSigned();
              },
              child: const Text('Imzolash (Bepul 3 oy)'),
            ),
          ],
        );
      },
    );
  }

  void _showFeedbackSheet(LawyerDirectoryProfile lawyer) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF1A3F86),
                Color(0xFF102A5E),
              ],
            ),
            border: Border.all(
              color: const Color(0xFFDCEBFF).withValues(alpha: 0.36),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${lawyer.fullName} — Mijozlar fikrlari (${lawyer.feedbackCount} ta)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ...lawyer.feedbacks.map(
                  (fb) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: LiquidGlassWindow(
                      padding: const EdgeInsets.all(13),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Text(
                                fb.clientName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.8,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFFFBBF24,
                                  ).withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '★ ${fb.rating.toStringAsFixed(1)} • ${fb.caseType}',
                                  style: const TextStyle(
                                    color: Color(0xFFFDE68A),
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                fb.dateLabel,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fb.comment,
                            style: const TextStyle(
                              color: Color(0xFFEAF3FF),
                              fontSize: 12.8,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lawyers = _filteredAndRankedLawyers;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          sliver: SliverToBoxAdapter(
            child: LiquidGlassWindow(
              padding: const EdgeInsets.all(16),
              accentGlowColor: const Color(0xFF7CE7FF),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: <Color>[
                              Color(0xFF56B4FF),
                              Color(0xFF2862CC),
                            ],
                          ),
                        ),
                        child: const Icon(
                          CupertinoIcons.building_2_fill,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'YAN360 Advokatxona Reytingi',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Yuqori feedbek va reytingga ega litsenziyali advokatlar avtomatik yuqorida turadi',
                              style: TextStyle(
                                color: const Color(
                                  0xFFDCEBFF,
                                ).withValues(alpha: 0.84),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Filter 1: Viloyati
                  const Text(
                    'VILOYAT BO‘YICHA SARALASH:',
                    style: TextStyle(
                      color: Color(0xFFBEE0FF),
                      fontSize: 10.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: YanRoleDataCatalog.regions.map((region) {
                        final active = _selectedRegion == region;
                        return Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: _FilterChipPill(
                            label: region,
                            active: active,
                            onTap: () =>
                                setState(() => _selectedRegion = region),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter 2: Mutaxassisligi
                  const Text(
                    'MUTAXASSISLIGI:',
                    style: TextStyle(
                      color: Color(0xFFBEE0FF),
                      fontSize: 10.2,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.7,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: YanRoleDataCatalog.specializations.map((spec) {
                        final active = _selectedSpecialization == spec;
                        return Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: _FilterChipPill(
                            label: spec,
                            active: active,
                            onTap: () =>
                                setState(() => _selectedSpecialization = spec),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Filter 3: Tajribasi
                  Row(
                    children: <Widget>[
                      const Text(
                        'TAJRIBASI:',
                        style: TextStyle(
                          color: Color(0xFFBEE0FF),
                          fontSize: 10.2,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.7,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ...[0, 5, 8, 10].map((years) {
                        final active = _minExperienceYears == years;
                        return Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: _FilterChipPill(
                            label: years == 0 ? 'Barchasi' : '$years+ yil',
                            active: active,
                            onTap: () =>
                                setState(() => _minExperienceYears = years),
                          ),
                        );
                      }),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 115),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lawyer = lawyers[index];
                final isTopRanked = index == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: LiquidGlassWindow(
                    isHighlighted: isTopRanked,
                    accentGlowColor: isTopRanked
                        ? const Color(0xFFFBBF24)
                        : const Color(0xFF7CE7FF),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFF67B6FF),
                                    Color(0xFF2858B8),
                                  ],
                                ),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  width: 1.4,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  lawyer.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      if (isTopRanked)
                                        Container(
                                          margin: const EdgeInsets.only(
                                            right: 6,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 7,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(
                                              0xFFFBBF24,
                                            ).withValues(alpha: 0.25),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: const Color(0xFFFBBF24),
                                            ),
                                          ),
                                          child: const Text(
                                            'TOP #1 FEEDBEK',
                                            style: TextStyle(
                                              color: Color(0xFFFDE68A),
                                              fontSize: 9.2,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          lawyer.fullName,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    '${lawyer.specialization} • ${lawyer.region}',
                                    style: const TextStyle(
                                      color: Color(0xFF9ED8FF),
                                      fontSize: 12.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: <Widget>[
                                      _StatMiniBadge(
                                        icon: CupertinoIcons.star_fill,
                                        text:
                                            '${lawyer.rating} (${lawyer.feedbackCount} feedbek)',
                                        color: const Color(0xFFFBBF24),
                                      ),
                                      _StatMiniBadge(
                                        icon: CupertinoIcons.briefcase_fill,
                                        text:
                                            '${lawyer.experienceYears} yil tajriba',
                                        color: const Color(0xFF7CE7FF),
                                      ),
                                      _StatMiniBadge(
                                        icon:
                                            CupertinoIcons.checkmark_seal_fill,
                                        text: '${lawyer.wonCasesCount} yutuq',
                                        color: const Color(0xFF34D399),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 11),
                        Text(
                          lawyer.bio,
                          style: TextStyle(
                            color: const Color(
                              0xFFEAF3FF,
                            ).withValues(alpha: 0.88),
                            fontSize: 12.4,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF34D399,
                            ).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: const Color(
                                0xFF34D399,
                              ).withValues(alpha: 0.45),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                CupertinoIcons.gift_fill,
                                size: 15,
                                color: Color(0xFF6EE7B7),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Shartnoma imzolanganda: 3 oy BEPUL obuna + 30%/20%/50% chegirmalar!',
                                  style: const TextStyle(
                                    color: Color(0xFFD1FAE5),
                                    fontSize: 11.3,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LiquidActionButton(
                                label: 'Feedbeklar (${lawyer.feedbackCount})',
                                icon: CupertinoIcons.chat_bubble_2_fill,
                                isPrimary: false,
                                compact: true,
                                onPressed: () => _showFeedbackSheet(lawyer),
                              ),
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              flex: 2,
                              child: LiquidActionButton(
                                label: 'Shartnoma tuzish',
                                icon: CupertinoIcons.signature,
                                compact: true,
                                accentColor: const Color(0xFF34D399),
                                onPressed: () =>
                                    _signContractWithLawyer(lawyer),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
              childCount: lawyers.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  const _FilterChipPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: active
              ? const LinearGradient(
                  colors: <Color>[Color(0xFF5AB2FF), Color(0xFF2B67D6)],
                )
              : LinearGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.06),
                  ],
                ),
          border: Border.all(
            color: active
                ? const Color(0xFFA7E4FF)
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 11.4,
            fontWeight: active ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _StatMiniBadge extends StatelessWidget {
  const _StatMiniBadge({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: color.withValues(alpha: 0.48)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 3. ADVOKATIM VIEW (For Mijoz Role — Tab 3)
// Full details of contracted lawyer, direct Chat & Video Call, Assistant info,
// 30%/20%/50% VIP discounts + 3 months free tracker, find new lawyer & cancel contract
// ═══════════════════════════════════════════════════════════════════════════

class _AdvokatimRoleView extends StatefulWidget {
  const _AdvokatimRoleView({super.key, required this.profile});

  final UserProfileData profile;

  @override
  State<_AdvokatimRoleView> createState() => _AdvokatimRoleViewState();
}

class _AdvokatimRoleViewState extends State<_AdvokatimRoleView> {
  final TextEditingController _chatController = TextEditingController();
  final List<Map<String, String>> _messages = <Map<String, String>>[
    <String, String>{
      'sender': 'lawyer',
      'text':
          'Assalomu alaykum! Shartnomangiz faol. Da’vo arizangiz va sud hujjatlari bo‘yicha yordamchim Madina Karimova bilan birga ishlayapmiz.',
      'time': '10:15',
    },
    <String, String>{
      'sender': 'user',
      'text':
          'Assalomu alaykum, rahmat! Shablon arizalarga 50% chegirma avtomatik qo‘llandi.',
      'time': '10:18',
    },
  ];

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  void _openChatModal(LawyerDirectoryProfile lawyer) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
            return Container(
              height: MediaQuery.of(context).size.height * 0.74,
              padding: EdgeInsets.fromLTRB(18, 16, 18, 18 + bottomInset),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFF1A3F86), Color(0xFF0E2554)],
                ),
                border: Border.all(
                  color: const Color(0xFFDCEBFF).withValues(alpha: 0.4),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.chat_bubble_text_fill,
                        color: Color(0xFF7CE7FF),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lawyer.fullName} — Maxfiy Muloqot',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _messages.length,
                      itemBuilder: (context, index) {
                        final msg = _messages[index];
                        final isMe = msg['sender'] == 'user';
                        return Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 9),
                            padding: const EdgeInsets.all(12),
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.74,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isMe
                                  ? const Color(0xFF2B67D6)
                                  : Colors.white.withValues(alpha: 0.14),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.24),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  msg['text'] ?? '',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['time'] ?? '',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.65),
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: CupertinoTextField(
                          controller: _chatController,
                          placeholder: 'Advokatga xabar yozing...',
                          placeholderStyle: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                          style: const TextStyle(color: Colors.white),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      LiquidActionButton(
                        label: 'Yuborish',
                        icon: CupertinoIcons.paperplane_fill,
                        compact: true,
                        onPressed: () {
                          final txt = _chatController.text.trim();
                          if (txt.isEmpty) return;
                          setModalState(() {
                            _messages.add(<String, String>{
                              'sender': 'user',
                              'text': txt,
                              'time': 'Hozir',
                            });
                            _chatController.clear();
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _startVideoCallDialog(LawyerDirectoryProfile lawyer) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text('Videomuloqot: ${lawyer.fullName}'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Shartnomali mijoz sifatida sizga konsultatsiya uchun 20% chegirma qo‘llanadi.\n\n'
              'Asosiy narx: ${lawyer.consultationPriceUzs} so‘m\n'
              'Siz uchun (-20%): ${widget.profile.applyDiscount(lawyer.consultationPriceUzs, category: 'consultation')} so‘m\n\n'
              'Shifrlangan HD videomuloqot xonasiga ulanasizmi?',
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Yopish'),
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              onPressed: () {
                Navigator.pop(dialogContext);
                ActivityHistoryRepository.instance.record(
                  title: 'Advokat bilan videomuloqot boshlandi',
                  description:
                      '${lawyer.fullName} bilan jonli videomuloqot (-20% mijoz imtiyozi bilan)',
                  category: ActivityCategory.consultation,
                  statusLabel: 'Jonli aloqa',
                );
              },
              child: const Text('Ulanish'),
            ),
          ],
        );
      },
    );
  }

  void _confirmCancelContract(LawyerDirectoryProfile lawyer) {
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('Shartnomani bekor qilish'),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${lawyer.fullName} bilan tuzilgan yuridik yordam shartnomasini bekor qilmoqchimisiz?\n\n'
              'Shartnoma bekor qilinsa, profilingiz "Oddiy foydalanuvchi" maqomiga qaytadi va 30%–50% chegirmalar to‘xtatiladi.',
            ),
          ),
          actions: <Widget>[
            CupertinoDialogAction(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Qoldirish'),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              onPressed: () {
                Navigator.pop(dialogContext);
                userProfile.switchRole(UserRole.oddiy);
                ActivityHistoryRepository.instance.record(
                  title: 'Advokat bilan shartnoma bekor qilindi',
                  description:
                      '${lawyer.fullName} bilan shartnoma yakunlandi. Profil Oddiy rejimga qaytdi.',
                  category: ActivityCategory.lawyer,
                  statusLabel: 'Bekor qilindi',
                );
              },
              child: const Text('Bekor qilish'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lawyer = YanRoleDataCatalog.byId(widget.profile.contractedLawyerId);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 115),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              // 1. Contract & 3-Month Free Trial / Discount Banner
              LiquidGlassWindow(
                isHighlighted: true,
                accentGlowColor: const Color(0xFF34D399),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF34D399,
                            ).withValues(alpha: 0.24),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFF34D399)),
                          ),
                          child: Text(
                            'SHARTNOMA № ${widget.profile.contractNumber ?? 'SH-2026/084'}',
                            style: const TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.profile.freeTrialDaysRemaining} kun BEPUL qoldi',
                          style: const TextStyle(
                            color: Color(0xFF6EE7B7),
                            fontSize: 11.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Mening Shartnomali Advokatim (VIP Imtiyozlar Faol)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Shartnoma imzolanganidan boshlab 3 oy bepul, keyin \$3/oy. Barcha chegirmalar avtomatik hisoblanadi:',
                      style: TextStyle(
                        color: const Color(0xFFDCEBFF).withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: const <Widget>[
                        Expanded(
                          child: _VipDiscountTile(
                            percent: '-30%',
                            label: 'Har qanday xizmatda',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _VipDiscountTile(
                            percent: '-20%',
                            label: 'Konsultatsiyada',
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _VipDiscountTile(
                            percent: '-50%',
                            label: 'Shablon arizada',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // 2. Contracted Lawyer Full Profile Card + Direct Chat & Video Call
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFF34D399),
                                Color(0xFF1D4ED8),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.7),
                              width: 1.5,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              lawyer.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 13),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                lawyer.fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lawyer.title} • Litsenziya: ${lawyer.licenseNumber}',
                                style: const TextStyle(
                                  color: Color(0xFF9ED8FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${lawyer.region} • ${lawyer.specialization} • ${lawyer.experienceYears} yil tajriba',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 13),
                    Text(
                      lawyer.bio,
                      style: const TextStyle(
                        color: Color(0xFFEAF3FF),
                        fontSize: 12.6,
                        height: 1.36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Xabarlashish (Chat)',
                            icon: CupertinoIcons.chat_bubble_text_fill,
                            accentColor: const Color(0xFF63B3FF),
                            onPressed: () => _openChatModal(lawyer),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Videomuloqot (-20%)',
                            icon: CupertinoIcons.videocam_fill,
                            accentColor: const Color(0xFF34D399),
                            onPressed: () => _startVideoCallDialog(lawyer),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // 3. Assigned Lawyer Assistant (Advokat Yordamchisi) Card
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                accentGlowColor: const Color(0xFFC084FC),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(
                              0xFFC084FC,
                            ).withValues(alpha: 0.25),
                            border: Border.all(color: const Color(0xFFC084FC)),
                          ),
                          child: const Icon(
                            CupertinoIcons.person_2_fill,
                            color: Color(0xFFE9D5FF),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Biriktirilgan Advokat Yordamchisi',
                                style: TextStyle(
                                  color: Color(0xFFE9D5FF),
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lawyer.assistantName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${lawyer.assistantRole} • ${lawyer.assistantPhone}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  fontSize: 11.8,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Yordamchiga yozish',
                            icon: CupertinoIcons.bubble_left_bubble_right_fill,
                            isPrimary: false,
                            compact: true,
                            onPressed: () => _openChatModal(lawyer),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Ariza yozdirish (-30%)',
                            icon: CupertinoIcons.doc_text_fill,
                            compact: true,
                            accentColor: const Color(0xFFC084FC),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const LawyerDraftRequestPage(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // 4. Additional Lawyer Search & Contract Cancellation Controls
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Shartnoma va Qo‘shimcha Advokat Boshqaruvi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Yangi advokat izlash',
                            icon: CupertinoIcons.search_circle_fill,
                            isPrimary: false,
                            compact: true,
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const AdvokatYollashPage(),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Shartnomani bekor qilish',
                            icon: CupertinoIcons.xmark_octagon_fill,
                            compact: true,
                            accentColor: const Color(0xFFF87171),
                            onPressed: () => _confirmCancelContract(lawyer),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _VipDiscountTile extends StatelessWidget {
  const _VipDiscountTile({required this.percent, required this.label});

  final String percent;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: const Color(0xFF34D399).withValues(alpha: 0.55),
        ),
      ),
      child: Column(
        children: <Widget>[
          Text(
            percent,
            style: const TextStyle(
              color: Color(0xFF6EE7B7),
              fontSize: 16.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 4. ADVOKAT ROLE VIEWS (Bosh sahifa, Shartnomalarim, Mijozlar)
// Licensed Lawyer partnered with YAN LEGAL FIRM MCHJ (3 monthly subscription tiers
// + one-time fee per signed contract)
// ═══════════════════════════════════════════════════════════════════════════

class _AdvokatHomeRoleView extends StatelessWidget {
  const _AdvokatHomeRoleView({
    super.key,
    required this.profile,
    required this.onOpenContracts,
    required this.onOpenClients,
  });

  final UserProfileData profile;
  final VoidCallback onOpenContracts;
  final VoidCallback onOpenClients;

  @override
  Widget build(BuildContext context) {
    final tier = profile.lawyerSubscriptionTier;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 115),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              LiquidGlassWindow(
                isHighlighted: true,
                accentGlowColor: const Color(0xFFFBBF24),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: const LinearGradient(
                              colors: <Color>[
                                Color(0xFFFBBF24),
                                Color(0xFFD97706),
                              ],
                            ),
                          ),
                          child: const Icon(
                            CupertinoIcons.briefcase_fill,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Advokat Kabineti • ${profile.displayName}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '"YAN LEGAL FIRM" MCHJ hamkori • Litsenziya: ${profile.lawyerLicenseNumber}',
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 11.8,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _LawyerMetricBox(
                            value: '${YanRoleDataCatalog.sampleContracts.length}',
                            label: 'Faol shartnomalar',
                            accent: const Color(0xFFFBBF24),
                            onTap: onOpenContracts,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LawyerMetricBox(
                            value: '8.9M',
                            label: 'Oylik gonorar (UZS)',
                            accent: const Color(0xFF34D399),
                            onTap: onOpenContracts,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LawyerMetricBox(
                            value: '4.98 ★',
                            label: 'Reyting (184)',
                            accent: const Color(0xFF7CE7FF),
                            onTap: onOpenClients,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // 3 Subscription Tiers Selector (3 xil obuna shaklida oylik to'lov)
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'YAN Legal Firm — 3 Xil Advokatlik Obunasi',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Oylik obuna + har bir imzolangan shartnoma uchun bir martalik komissiya to‘lovi:',
                      style: TextStyle(
                        color: const Color(0xFFDCEBFF).withValues(alpha: 0.82),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _LawyerTierCard(
                            tierIndex: 1,
                            title: 'START',
                            price: '\$19/oy',
                            perContract: '7% shartnoma',
                            selected: tier == 1,
                            onSelect: () => userProfile.update(
                              (curr) =>
                                  curr.copyWith(lawyerSubscriptionTier: 1),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LawyerTierCard(
                            tierIndex: 2,
                            title: 'PRO',
                            price: '\$39/oy',
                            perContract: '5% shartnoma',
                            selected: tier == 2,
                            onSelect: () => userProfile.update(
                              (curr) =>
                                  curr.copyWith(lawyerSubscriptionTier: 2),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LawyerTierCard(
                            tierIndex: 3,
                            title: 'ELITE',
                            price: '\$69/oy',
                            perContract: '3% + Yordamchi',
                            selected: tier == 3,
                            onSelect: () => userProfile.update(
                              (curr) =>
                                  curr.copyWith(lawyerSubscriptionTier: 3),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),

              // Quick Navigation to Shartnomalarim & Mijozlar
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Tezkor Ish Stoli Amallari',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 11),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Shartnomalarim',
                            icon: CupertinoIcons.doc_checkmark_fill,
                            accentColor: const Color(0xFFFBBF24),
                            onPressed: onOpenContracts,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Mijozlar bazasi',
                            icon: CupertinoIcons.person_2_fill,
                            accentColor: const Color(0xFF63B3FF),
                            onPressed: onOpenClients,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

class _LawyerMetricBox extends StatelessWidget {
  const _LawyerMetricBox({
    required this.value,
    required this.label,
    required this.accent,
    required this.onTap,
  });

  final String value;
  final String label;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 16.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LawyerTierCard extends StatelessWidget {
  const _LawyerTierCard({
    required this.tierIndex,
    required this.title,
    required this.price,
    required this.perContract,
    required this.selected,
    required this.onSelect,
  });

  final int tierIndex;
  final String title;
  final String price;
  final String perContract;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: selected
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[Color(0xFFF59E0B), Color(0xFFB45309)],
                )
              : LinearGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.12),
                    Colors.white.withValues(alpha: 0.05),
                  ],
                ),
          border: Border.all(
            color: selected
                ? const Color(0xFFFDE68A)
                : Colors.white.withValues(alpha: 0.24),
            width: selected ? 1.4 : 1.0,
          ),
        ),
        child: Column(
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              perContract,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 9.8,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvokatContractsRoleView extends StatelessWidget {
  const _AdvokatContractsRoleView({super.key, required this.profile});

  final UserProfileData profile;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 115),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                accentGlowColor: const Color(0xFFFBBF24),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Mening Shartnomalarim (Advokat Reyestri)',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Har bir imzolangan elektron yuridik yordam shartnomasi YAN360 bazasida himoyalangan',
                      style: TextStyle(
                        color: Color(0xFFDCEBFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...YanRoleDataCatalog.sampleContracts.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: LiquidGlassWindow(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFFBBF24,
                                ).withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                item.contractNumber,
                                style: const TextStyle(
                                  color: Color(0xFFFDE68A),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item.signedDate,
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.clientName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.caseCategory} • ${item.region}',
                          style: const TextStyle(
                            color: Color(0xFF9ED8FF),
                            fontSize: 12.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 9),
                        Row(
                          children: <Widget>[
                            Text(
                              'Gonorar: ${(item.feeAmountUzs / 1000000).toStringAsFixed(1)} mln so‘m',
                              style: const TextStyle(
                                color: Color(0xFF6EE7B7),
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF34D399,
                                ).withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                item.statusLabel,
                                style: const TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 5. MIJOZLAR DIRECTORY VIEW (Shared by Advokat & Advokat Yordamchisi — Tab 3)
// ═══════════════════════════════════════════════════════════════════════════

class _ClientsDirectoryRoleView extends StatelessWidget {
  const _ClientsDirectoryRoleView({
    super.key,
    required this.profile,
    required this.isAssistantView,
  });

  final UserProfileData profile;
  final bool isAssistantView;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 115),
          sliver: SliverList(
            delegate: SliverChildListDelegate(<Widget>[
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                accentGlowColor: isAssistantView
                    ? const Color(0xFFC084FC)
                    : const Color(0xFFFBBF24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isAssistantView
                          ? 'Mijozlar bilan Ishlash (Yordamchi Bo‘limi)'
                          : 'Shartnomali Mijozlar Bazasi',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAssistantView
                          ? 'Biriktirilgan advokat (${profile.assignedLawyerName}) mijozlarining hujjatlari va murojaatlari'
                          : 'Siz bilan yuridik yordam shartnomasi tuzgan barcha faol mijozlar',
                      style: const TextStyle(
                        color: Color(0xFFDCEBFF),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              ...YanRoleDataCatalog.sampleContracts.map(
                (client) => Padding(
                  padding: const EdgeInsets.only(bottom: 11),
                  child: LiquidGlassWindow(
                    padding: const EdgeInsets.all(15),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            CircleAvatar(
                              radius: 21,
                              backgroundColor: const Color(0xFF2B67D6),
                              child: Text(
                                client.clientName.substring(0, 1),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    client.clientName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 15.8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${client.clientPhone} • ${client.region}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 11.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF34D399,
                                ).withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                client.statusLabel,
                                style: const TextStyle(
                                  color: Color(0xFFA7F3D0),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        Text(
                          'Ish toifasi: ${client.caseCategory}',
                          style: const TextStyle(
                            color: Color(0xFF9ED8FF),
                            fontSize: 12.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 11),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: LiquidActionButton(
                                label: 'DOCX Hujjat tayyorlash',
                                icon: CupertinoIcons.doc_text_fill,
                                compact: true,
                                isPrimary: false,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => const AlimonyClaimPage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: LiquidActionButton(
                                label: 'Aloqaga chiqish',
                                icon: CupertinoIcons.phone_fill,
                                compact: true,
                                onPressed: () {
                                  ActivityHistoryRepository.instance.record(
                                    title:
                                        'Mijoz ${client.clientName} bilan bog‘lanildi',
                                    description:
                                        'Shartnoma ${client.contractNumber} bo‘yicha muloqot',
                                    category: ActivityCategory.lawyer,
                                    statusLabel: 'Bajarildi',
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// 6. ADVOKAT YORDAMCHISI VIEW (Vazifalar — Tab 1)
// Assigned to a registered lawyer by YAN Legal Firm or as personal assistant
// ═══════════════════════════════════════════════════════════════════════════

class _AssistantTasksRoleView extends StatelessWidget {
  const _AssistantTasksRoleView({
    super.key,
    required this.profile,
    required this.onOpenDocuments,
    required this.onOpenClients,
  });

  final UserProfileData profile;
  final VoidCallback onOpenDocuments;
  final VoidCallback onOpenClients;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<AssistantTaskItem>>(
      valueListenable: YanRoleDataCatalog.assistantTasks,
      builder: (context, tasks, _) {
        final completedCount = tasks.where((t) => t.isCompleted).length;

        return CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: <Widget>[
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 115),
              sliver: SliverList(
                delegate: SliverChildListDelegate(<Widget>[
                  LiquidGlassWindow(
                    isHighlighted: true,
                    accentGlowColor: const Color(0xFFC084FC),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(15),
                                gradient: const LinearGradient(
                                  colors: <Color>[
                                    Color(0xFFC084FC),
                                    Color(0xFF7C3AED),
                                  ],
                                ),
                              ),
                              child: const Icon(
                                CupertinoIcons.person_2_fill,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Advokat Yordamchisi Ish Stoli',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Biriktirilgan advokat: ${profile.assignedLawyerName} (YAN Legal Firm)',
                                    style: const TextStyle(
                                      color: Color(0xFFE9D5FF),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 13),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _LawyerMetricBox(
                                value: '${tasks.length - completedCount}',
                                label: 'Faol topshiriq',
                                accent: const Color(0xFFC084FC),
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LawyerMetricBox(
                                value: '$completedCount/${tasks.length}',
                                label: 'Bajarilgan',
                                accent: const Color(0xFF34D399),
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LawyerMetricBox(
                                value: 'DOCX',
                                label: 'Hujjatlar ombori',
                                accent: const Color(0xFF7CE7FF),
                                onTap: onOpenDocuments,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 13),
                  ...tasks.map(
                    (task) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: LiquidGlassWindow(
                        padding: const EdgeInsets.all(14),
                        onTap: () => YanRoleDataCatalog.toggleTask(task.id),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Icon(
                              task.isCompleted
                                  ? CupertinoIcons.checkmark_circle_fill
                                  : CupertinoIcons.circle,
                              color: task.isCompleted
                                  ? const Color(0xFF34D399)
                                  : const Color(0xFFC084FC),
                              size: 23,
                            ),
                            const SizedBox(width: 11),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      decoration: task.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    'Mijoz: ${task.clientName} • Muddat: ${task.deadlineLabel}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 11.8,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFFC084FC,
                                ).withValues(alpha: 0.22),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.categoryLabel,
                                style: const TextStyle(
                                  color: Color(0xFFE9D5FF),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Login Page Liquid Input Fields & Buttons
// ═══════════════════════════════════════════════════════════════════════════

class _UzbekPhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _UzbekPhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      keyboardType: TextInputType.phone,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15.5),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      placeholder: '** *** ** **',
      placeholderStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.48),
        fontSize: 14.5,
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 15, right: 9),
        child: Icon(
          CupertinoIcons.phone_fill,
          size: 18,
          color: const Color(0xFF9ED8FF).withValues(alpha: 0.9),
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xFF7FA4E8).withValues(alpha: 0.24),
            const Color(0xFF2B5096).withValues(alpha: 0.34),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDCEBFF).withValues(alpha: 0.35),
        ),
      ),
      cursorColor: const Color(0xFF7CE7FF),
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
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15.5),
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      placeholder: hintText,
      placeholderStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.48),
        fontSize: 14.5,
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 15, right: 9),
        child: Icon(
          icon,
          size: 18,
          color: const Color(0xFF9ED8FF).withValues(alpha: 0.9),
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[
            const Color(0xFF7FA4E8).withValues(alpha: 0.24),
            const Color(0xFF2B5096).withValues(alpha: 0.34),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFDCEBFF).withValues(alpha: 0.35),
        ),
      ),
      cursorColor: const Color(0xFF7CE7FF),
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
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Color(0xFF66B8FF),
                Color(0xFF3972E6),
                Color(0xFF214CB0),
              ],
            ),
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.45),
              width: 1.15,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: const Color(0xFF3E70E2).withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.8,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.1,
                ),
              ),
              const SizedBox(width: 9),
              Icon(widget.icon, size: 17, color: Colors.white),
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12.5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: widget.active
                  ? <Color>[
                      const Color(0xFF6B9FF7).withValues(alpha: 0.34),
                      const Color(0xFF2E5CB8).withValues(alpha: 0.42),
                    ]
                  : <Color>[
                      const Color(0xFF7FA4E8).withValues(alpha: 0.20),
                      const Color(0xFF2B5096).withValues(alpha: 0.28),
                    ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: widget.active
                  ? const Color(0xFF9ED8FF).withValues(alpha: 0.68)
                  : const Color(0xFFDCEBFF).withValues(alpha: 0.28),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 16,
                color: widget.active
                    ? const Color(0xFF9ED8FF)
                    : Colors.white.withValues(alpha: 0.85),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white.withValues(
                      alpha: widget.active ? 0.98 : 0.88,
                    ),
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
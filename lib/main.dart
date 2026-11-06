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
        brightness: Brightness.light,
        scaffoldBackgroundColor: YanColors.background, // Exact #FEFEFA
        fontFamily: 'Roboto',
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: YanColors.primaryBlue,
          brightness: Brightness.light,
          surface: YanColors.background,
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
      duration: const Duration(milliseconds: 700),
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
        return 'Rolni tanlang va telefon raqamingiz orqali davom eting';
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
      backgroundColor: YanColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DashboardBackground(),
          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(20, 22, 20, 24 + bottomInset),
              child: Column(
                children: <Widget>[
                  _buildBrand(),
                  const SizedBox(height: 22),
                  _buildAuthCard(),
                  const SizedBox(height: 18),
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

    return FadeTransition(
      opacity: fade,
      child: Column(
        children: <Widget>[
          // Uncompressed, full-resolution firm shield logo (no circular border)
          SizedBox(
            width: 86,
            height: 86,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) => const Icon(
                CupertinoIcons.shield_lefthalf_fill,
                size: 68,
                color: YanColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 12),
          RichText(
            text: const TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: 'YAN',
                  style: TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: '360',
                  style: TextStyle(
                    color: YanColors.primaryBlue,
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.5,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Yuridik xizmatlar platformasi',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: YanColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAuthCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: YanColors.border, width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: YanColors.primaryNavy.withValues(alpha: 0.065),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (!_isLogin) _buildBackButton(),
              if (!_isLogin) const SizedBox(height: 8),
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
                            color: YanColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _subtitle,
                          style: const TextStyle(
                            fontSize: 12.6,
                            color: YanColors.mutedText,
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
                      color: YanColors.lightBlue,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: YanColors.border),
                    ),
                    child: Text(
                      _selectedLoginRole.shortBadge,
                      style: const TextStyle(
                        color: YanColors.primaryBlue,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              _buildLoginRoleSelector(),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
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
        const Text(
          'KIRISH REJIMI (4 XIL PROFIL):',
          style: TextStyle(
            fontSize: 10.2,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
            color: YanColors.mutedText,
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
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      // Monochromatic solid button colors
                      color: selected
                          ? YanColors.primaryBlue
                          : YanColors.lightBlue,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(
                          role.icon,
                          size: 14.5,
                          color: selected
                              ? YanColors.white
                              : YanColors.primaryNavy,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          role.shortBadge,
                          style: TextStyle(
                            color: selected
                                ? YanColors.white
                                : YanColors.primaryNavy,
                            fontSize: 11.2,
                            fontWeight: FontWeight.w700,
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
      child: const Padding(
        padding: EdgeInsets.only(bottom: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              CupertinoIcons.chevron_left,
              size: 15,
              color: YanColors.primaryBlue,
            ),
            SizedBox(width: 4),
            Text(
              'Kirishga qaytish',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: YanColors.primaryBlue,
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
          _CleanTextField(
            controller: _loginCodeController,
            hintText: 'Tasdiqlash kodi (masalan: 1234)',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 15),
          _SolidPrimaryButton(
            label: 'Tizimga kirish',
            icon: CupertinoIcons.arrow_right,
            onPressed: _loginWithPhone,
          ),
        ] else ...<Widget>[
          const SizedBox(height: 15),
          _SolidPrimaryButton(
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
        _CleanTextField(
          controller: _emailLoginController,
          hintText: 'name@yan360.uz',
          keyboardType: TextInputType.emailAddress,
          icon: CupertinoIcons.mail,
        ),
        if (_emailCodeSent) ...<Widget>[
          const SizedBox(height: 11),
          _CleanTextField(
            controller: _loginCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 15),
          _SolidPrimaryButton(
            label: 'Tizimga kirish',
            icon: CupertinoIcons.arrow_right,
            onPressed: _loginWithEmail,
          ),
        ] else ...<Widget>[
          const SizedBox(height: 15),
          _SolidPrimaryButton(
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
        _CleanTextField(
          controller: _phoneRegisterFirstNameController,
          hintText: 'Ism',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person,
        ),
        const SizedBox(height: 10),
        _CleanTextField(
          controller: _phoneRegisterSurnameController,
          hintText: 'Familiya',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person,
        ),
        const SizedBox(height: 10),
        _UzbekPhoneField(controller: _phoneRegisterPhoneController),
        if (_phoneCodeSent) ...<Widget>[
          const SizedBox(height: 11),
          _CleanTextField(
            controller: _phoneRegisterCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 15),
          _SolidPrimaryButton(
            label: 'Ro‘yxatdan o‘tish',
            icon: CupertinoIcons.person_add_solid,
            onPressed: _completePhoneRegistration,
          ),
        ] else ...<Widget>[
          const SizedBox(height: 15),
          _SolidPrimaryButton(
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
        _CleanTextField(
          controller: _emailRegisterFirstNameController,
          hintText: 'Ism',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person,
        ),
        const SizedBox(height: 10),
        _CleanTextField(
          controller: _emailRegisterSurnameController,
          hintText: 'Familiya',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person,
        ),
        const SizedBox(height: 10),
        _CleanTextField(
          controller: _emailRegisterEmailController,
          hintText: 'name@yan360.uz',
          keyboardType: TextInputType.emailAddress,
          icon: CupertinoIcons.mail,
        ),
        if (_emailCodeSent) ...<Widget>[
          const SizedBox(height: 11),
          _CleanTextField(
            controller: _emailRegisterCodeController,
            hintText: 'Tasdiqlash kodi',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.lock,
          ),
          const SizedBox(height: 15),
          _SolidPrimaryButton(
            label: 'Ro‘yxatdan o‘tish',
            icon: CupertinoIcons.person_add_solid,
            onPressed: _completeEmailRegistration,
          ),
        ] else ...<Widget>[
          const SizedBox(height: 15),
          _SolidPrimaryButton(
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
            child: _SolidSecondaryButton(
              icon: CupertinoIcons.phone,
              label: 'Telefon orqali',
              active: _mode == AuthMode.phoneRegister,
              onPressed: _goToPhoneRegister,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: _SolidSecondaryButton(
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
              child: _SolidSecondaryButton(
                icon: CupertinoIcons.mail,
                label: 'Email orqali',
                active: _mode == AuthMode.emailLogin,
                onPressed: _goToEmailLogin,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _SolidSecondaryButton(
                icon: CupertinoIcons.person_add,
                label: 'Ro‘yxatdan o‘tish',
                active: false,
                onPressed: _showRegistrationChoices,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        _SolidSecondaryButton(
          icon: CupertinoIcons.arrow_right_circle_fill,
          label: 'Tezkor kirish (${_selectedLoginRole.label})',
          active: false,
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
    return const Column(
      children: <Widget>[
        Text(
          'YAN LEGAL FIRM MCHJ',
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.6,
            color: YanColors.mutedText,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Huquq • Ishonch • Yuqori Texnologiya',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.6,
            color: YanColors.subtleText,
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

// ═══════════════════════════════════════════════════════════════════════════
// MainDashboard: 5-Tab Floating Liquid Glass Navigation + Top Role Bar
// 1. Bosh sahifa | 2. Arizalarim | 3. Advokatim | 4. Advokatxona | 5. Profil
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
    _selectedTab = widget.initialTab.clamp(0, 4);
    GeneratedDocumentRepository.instance.reload();
    ActivityHistoryRepository.instance.ensureInitialized();
  }

  /// 5-tab navigation structure matching Section 7 & attached visual reference:
  /// 1. Bosh sahifa
  /// 2. Arizalarim (-50%)
  /// 3. Advokatim (VIP)
  /// 4. Advokatxona
  /// 5. Profil
  List<DashboardNavData> _navItemsForRole(UserRole role) {
    return const <DashboardNavData>[
      DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
      DashboardNavData(
        CupertinoIcons.doc_text_fill,
        'Arizalarim',
        badge: '-50%',
      ),
      DashboardNavData(
        CupertinoIcons.shield_fill,
        'Advokatim',
        badge: 'VIP',
      ),
      DashboardNavData(CupertinoIcons.building_2_fill, 'Advokatxona'),
      DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
    ];
  }

  Widget _buildActiveScreen(UserProfileData profile) {
    switch (_selectedTab) {
      case 0:
        if (profile.roleType == UserRole.advokat) {
          return _AdvokatHomeRoleView(
            key: const ValueKey<String>('advokat-home'),
            profile: profile,
            onOpenContracts: () => setState(() => _selectedTab = 2),
            onOpenClients: () => setState(() => _selectedTab = 3),
          );
        }
        if (profile.roleType == UserRole.yordamchi) {
          return _AssistantTasksRoleView(
            key: const ValueKey<String>('yordamchi-tasks'),
            profile: profile,
            onOpenDocuments: () => setState(() => _selectedTab = 1),
            onOpenClients: () => setState(() => _selectedTab = 3),
          );
        }
        return const BoshSahifaPage(key: ValueKey<String>('tab-bosh-sahifa'));

      case 1:
        return _ArizalarimRoleView(
          key: const ValueKey<String>('tab-arizalarim'),
          profile: profile,
          onBrowseLawyers: () => setState(() => _selectedTab = 3),
        );

      case 2:
        if (profile.roleType == UserRole.advokat) {
          return _AdvokatContractsRoleView(
            key: const ValueKey<String>('tab-advokat-contracts'),
            profile: profile,
          );
        }
        return _AdvokatimRoleView(
          key: const ValueKey<String>('tab-advokatim'),
          profile: profile,
          onOpenAdvokatxona: () => setState(() => _selectedTab = 3),
        );

      case 3:
        if (profile.roleType == UserRole.advokat ||
            profile.roleType == UserRole.yordamchi) {
          return _ClientsDirectoryRoleView(
            key: const ValueKey<String>('tab-mijozlar'),
            profile: profile,
            isAssistantView: profile.roleType == UserRole.yordamchi,
          );
        }
        return _AdvokatxonaRoleView(
          key: const ValueKey<String>('tab-advokatxona'),
          profile: profile,
          onContractSigned: () {
            setState(() => _selectedTab = 2); // Jump to Advokatim tab
          },
        );

      case 4:
      default:
        return const ProfilPage(key: ValueKey<String>('tab-profil'));
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
            color: YanColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: YanColors.border, width: 1.2),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: YanColors.primaryNavy.withValues(alpha: 0.12),
                blurRadius: 28,
                offset: const Offset(0, -6),
              ),
            ],
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
                      color: YanColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.person_2_square_stack_fill,
                      color: YanColors.primaryBlue,
                      size: 21,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'YAN360 Rol va Kabinetni Almashtirish',
                        style: TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 17.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.pop(sheetContext),
                      child: const Icon(
                        CupertinoIcons.xmark_circle_fill,
                        color: YanColors.subtleText,
                        size: 24,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Har bir rol uchun maxsus imtiyozlar va ish stoli avtomatik moslashadi:',
                  style: TextStyle(
                    color: YanColors.mutedText,
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
                      accentGlowColor: YanColors.primaryBlue,
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
                              color: active
                                  ? YanColors.primaryBlue
                                  : YanColors.lightBlue,
                            ),
                            child: Icon(
                              role.icon,
                              color: active
                                  ? YanColors.white
                                  : YanColors.primaryNavy,
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
                                        color: YanColors.primaryNavy,
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
                                        color: YanColors.lightBlue,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        role.shortBadge,
                                        style: const TextStyle(
                                          color: YanColors.primaryBlue,
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
                                  style: const TextStyle(
                                    color: YanColors.mutedText,
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
                            color: active
                                ? YanColors.successGreen
                                : YanColors.subtleText,
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
          backgroundColor: YanColors.background,
          body: Stack(
            children: <Widget>[
              const DashboardBackground(),
              SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
                    // Top Selective Liquid Glass Role Status Bar (Matches Reference)
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
                        duration: const Duration(milliseconds: 220),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeIn,
                        child: _buildActiveScreen(profile),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 12 + MediaQuery.of(context).padding.bottom,
                child: DashboardBottomNavigation(
                  selectedIndex: _selectedTab,
                  items: navItems,
                  accentColor: YanColors.primaryBlue,
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7.5),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.88),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white, width: 1.3),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: YanColors.primaryNavy.withValues(alpha: 0.05),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4.5),
              decoration: BoxDecoration(
                color: YanColors.lightBlue,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: YanColors.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(role.icon, size: 13.5, color: YanColors.primaryBlue),
                  const SizedBox(width: 5),
                  Text(
                    role.shortBadge,
                    style: const TextStyle(
                      color: YanColors.primaryNavy,
                      fontSize: 10.2,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 16,
              color: YanColors.border,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                profile.subscriptionStatusLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 11.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
              decoration: BoxDecoration(
                color: YanColors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: YanColors.border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.arrow_2_squarepath,
                    size: 12.5,
                    color: YanColors.primaryNavy,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Rol',
                    style: TextStyle(
                      color: YanColors.primaryNavy,
                      fontSize: 11.0,
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
// 1. ARIZALARIM VIEW (Tab 2)
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
  int _subTab = 0;

  @override
  Widget build(BuildContext context) {
    final isMijoz = widget.profile.roleType == UserRole.mijoz;

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
          child: LiquidGlassWindow(
            padding: const EdgeInsets.all(15),
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
                              color: YanColors.primaryNavy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isMijoz
                                ? 'Shartnomali mijoz imtiyozi: Shablon arizalarga -50%, xizmatlarga -30% chegirma faol!'
                                : 'Barcha yaratilgan DOCX da’vo arizalari va advokatga yuborilgan so‘rovlar',
                            style: const TextStyle(
                              color: YanColors.mutedText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    LiquidActionButton(
                      label: isMijoz ? 'Yangi (-50%)' : 'Yangi ariza',
                      icon: CupertinoIcons.add_circled_solid,
                      compact: true,
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
                      child: _MonochromaticSegmentButton(
                        label: 'Rasmiy DOCX Arizalar',
                        icon: CupertinoIcons.doc_richtext,
                        selected: _subTab == 0,
                        onTap: () => setState(() => _subTab = 0),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MonochromaticSegmentButton(
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

class _MonochromaticSegmentButton extends StatelessWidget {
  const _MonochromaticSegmentButton({
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          // Single solid color (Primary #1677D2 or Secondary #EAF5FF)
          color: selected ? YanColors.primaryBlue : YanColors.lightBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 15,
              color: selected ? YanColors.white : YanColors.primaryNavy,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? YanColors.white : YanColors.primaryNavy,
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
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
// 2. ADVOKATXONA VIEW (Tab 4)
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
            color: YanColors.background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: YanColors.border),
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
                    color: YanColors.primaryNavy,
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
                                  color: YanColors.primaryNavy,
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
                                  color: YanColors.lightBlue,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '★ ${fb.rating.toStringAsFixed(1)} • ${fb.caseType}',
                                  style: const TextStyle(
                                    color: YanColors.primaryBlue,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Text(
                                fb.dateLabel,
                                style: const TextStyle(
                                  color: YanColors.subtleText,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            fb.comment,
                            style: const TextStyle(
                              color: YanColors.mutedText,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: YanColors.primaryBlue,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          CupertinoIcons.building_2_fill,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'YAN360 Advokatxona Reytingi',
                              style: TextStyle(
                                color: YanColors.primaryNavy,
                                fontSize: 18.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              'Yuqori feedbek va reytingga ega litsenziyali advokatlar avtomatik yuqorida turadi',
                              style: TextStyle(
                                color: YanColors.mutedText,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'VILOYAT BO‘YICHA SARALASH:',
                    style: TextStyle(
                      color: YanColors.mutedText,
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
                  const Text(
                    'MUTAXASSISLIGI:',
                    style: TextStyle(
                      color: YanColors.mutedText,
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
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        const Text(
                          'TAJRIBASI:',
                          style: TextStyle(
                            color: YanColors.mutedText,
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Container(
                              width: 54,
                              height: 54,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: YanColors.primaryNavy,
                              ),
                              child: Center(
                                child: Text(
                                  lawyer.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
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
                                            color: YanColors.successGreen
                                                .withValues(alpha: 0.16),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: const Text(
                                            'TOP #1 FEEDBEK',
                                            style: TextStyle(
                                              color: Color(0xFF098562),
                                              fontSize: 9.2,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Text(
                                          lawyer.fullName,
                                          style: const TextStyle(
                                            color: YanColors.primaryNavy,
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
                                      color: YanColors.primaryBlue,
                                      fontSize: 12.2,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 6,
                                    children: <Widget>[
                                      _StatMiniBadge(
                                        icon: CupertinoIcons.star_fill,
                                        text:
                                            '${lawyer.rating} (${lawyer.feedbackCount} feedbek)',
                                        color: YanColors.primaryBlue,
                                      ),
                                      _StatMiniBadge(
                                        icon: CupertinoIcons.briefcase_fill,
                                        text:
                                            '${lawyer.experienceYears} yil tajriba',
                                        color: YanColors.primaryNavy,
                                      ),
                                      _StatMiniBadge(
                                        icon:
                                            CupertinoIcons.checkmark_seal_fill,
                                        text: '${lawyer.wonCasesCount} yutuq',
                                        color: YanColors.successGreen,
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
                          style: const TextStyle(
                            color: YanColors.mutedText,
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
                            color: YanColors.lightBlue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            children: <Widget>[
                              Icon(
                                CupertinoIcons.checkmark_seal_fill,
                                size: 15,
                                color: YanColors.successGreen,
                              ),
                              SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  'Shartnoma imzolanganda: 3 oy BEPUL obuna + 30%/20%/50% chegirmalar!',
                                  style: TextStyle(
                                    color: YanColors.primaryNavy,
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
          // Single solid color (Primary #1677D2 or Secondary #EAF5FF)
          color: active ? YanColors.primaryBlue : YanColors.lightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? YanColors.white : YanColors.primaryNavy,
            fontSize: 11.4,
            fontWeight: FontWeight.w700,
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
        color: YanColors.lightBlue,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(
              color: YanColors.primaryNavy,
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
// 3. ADVOKATIM VIEW (Tab 3)
// ═══════════════════════════════════════════════════════════════════════════

class _AdvokatimRoleView extends StatefulWidget {
  const _AdvokatimRoleView({
    super.key,
    required this.profile,
    this.onOpenAdvokatxona,
  });

  final UserProfileData profile;
  final VoidCallback? onOpenAdvokatxona;

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
                color: YanColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: YanColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.chat_bubble_text_fill,
                        color: YanColors.primaryBlue,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${lawyer.fullName} — Maxfiy Muloqot',
                          style: const TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(sheetContext),
                        child: const Icon(
                          CupertinoIcons.xmark_circle_fill,
                          color: YanColors.subtleText,
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
                                  ? YanColors.primaryBlue
                                  : YanColors.lightBlue,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  msg['text'] ?? '',
                                  style: TextStyle(
                                    color: isMe
                                        ? YanColors.white
                                        : YanColors.primaryNavy,
                                    fontSize: 13.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  msg['time'] ?? '',
                                  style: TextStyle(
                                    color: isMe
                                        ? Colors.white70
                                        : YanColors.subtleText,
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
                          placeholderStyle: const TextStyle(
                            color: YanColors.subtleText,
                          ),
                          style: const TextStyle(color: YanColors.primaryNavy),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: YanColors.border),
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
                            color: YanColors.successGreen.withValues(
                              alpha: 0.16,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'SHARTNOMA № ${widget.profile.contractNumber ?? 'SH-2026/084'}',
                            style: const TextStyle(
                              color: Color(0xFF098562),
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${widget.profile.freeTrialDaysRemaining > 0 ? widget.profile.freeTrialDaysRemaining : 78} kun BEPUL',
                          style: const TextStyle(
                            color: Color(0xFF098562),
                            fontSize: 11.8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Mening Shartnomali Advokatim (VIP Imtiyozlar)',
                      style: TextStyle(
                        color: YanColors.primaryNavy,
                        fontSize: 17.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Shartnoma imzolanganidan boshlab 3 oy bepul, keyin \$3/oy. Barcha chegirmalar avtomatik hisoblanadi:',
                      style: TextStyle(
                        color: YanColors.mutedText,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 11),
                    const Row(
                      children: <Widget>[
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
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: YanColors.primaryNavy,
                          ),
                          child: Center(
                            child: Text(
                              lawyer.initials,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 19,
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
                                  color: YanColors.primaryNavy,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lawyer.title} • Litsenziya: ${lawyer.licenseNumber}',
                                style: const TextStyle(
                                  color: YanColors.primaryBlue,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${lawyer.region} • ${lawyer.specialization} • ${lawyer.experienceYears} yil tajriba',
                                style: const TextStyle(
                                  color: YanColors.mutedText,
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
                        color: YanColors.mutedText,
                        fontSize: 12.6,
                        height: 1.36,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Xabarlashish',
                            icon: CupertinoIcons.chat_bubble_text_fill,
                            onPressed: () => _openChatModal(lawyer),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Videomuloqot (-20%)',
                            icon: CupertinoIcons.videocam_fill,
                            isPrimary: false,
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: YanColors.lightBlue,
                          ),
                          child: const Icon(
                            CupertinoIcons.person_2_fill,
                            color: YanColors.primaryBlue,
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
                                  color: YanColors.primaryBlue,
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                lawyer.assistantName,
                                style: const TextStyle(
                                  color: YanColors.primaryNavy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '${lawyer.assistantRole} • ${lawyer.assistantPhone}',
                                style: const TextStyle(
                                  color: YanColors.mutedText,
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
                        color: YanColors.primaryNavy,
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
                              if (widget.onOpenAdvokatxona != null) {
                                widget.onOpenAdvokatxona!();
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute<void>(
                                    builder: (_) => const AdvokatYollashPage(),
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Shartnomani bekor qilish',
                            icon: CupertinoIcons.xmark_octagon_fill,
                            isDestructive: true,
                            compact: true,
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
        color: YanColors.lightBlue,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: YanColors.border),
      ),
      child: Column(
        children: <Widget>[
          Text(
            percent,
            style: const TextStyle(
              color: YanColors.primaryBlue,
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
              color: YanColors.primaryNavy,
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
// 4. ADVOKAT & YORDAMCHI ROLE VIEWS
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
                            color: YanColors.primaryBlue,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(
                            CupertinoIcons.briefcase_fill,
                            color: Colors.white,
                            size: 24,
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
                                  color: YanColors.primaryNavy,
                                  fontSize: 17.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '"YAN LEGAL FIRM" MCHJ hamkori • Litsenziya: ${profile.lawyerLicenseNumber}',
                                style: const TextStyle(
                                  color: YanColors.primaryBlue,
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
                            onTap: onOpenContracts,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LawyerMetricBox(
                            value: '8.9M',
                            label: 'Oylik gonorar (UZS)',
                            onTap: onOpenContracts,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _LawyerMetricBox(
                            value: '4.98 ★',
                            label: 'Reyting (184)',
                            onTap: onOpenClients,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 13),
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'YAN Legal Firm — 3 Xil Advokatlik Obunasi',
                      style: TextStyle(
                        color: YanColors.primaryNavy,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Oylik obuna + har bir imzolangan shartnoma uchun bir martalik komissiya to‘lovi:',
                      style: TextStyle(
                        color: YanColors.mutedText,
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
              LiquidGlassWindow(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Tezkor Ish Stoli Amallari',
                      style: TextStyle(
                        color: YanColors.primaryNavy,
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
                            onPressed: onOpenContracts,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: LiquidActionButton(
                            label: 'Mijozlar bazasi',
                            icon: CupertinoIcons.person_2_fill,
                            isPrimary: false,
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
    required this.onTap,
  });

  final String value;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
        decoration: BoxDecoration(
          color: YanColors.lightBlue,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: YanColors.border),
        ),
        child: Column(
          children: <Widget>[
            Text(
              value,
              style: const TextStyle(
                color: YanColors.primaryBlue,
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
                color: YanColors.primaryNavy,
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          // Single solid color (Primary #1677D2 or Secondary #EAF5FF)
          color: selected ? YanColors.primaryBlue : YanColors.lightBlue,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: selected ? YanColors.white : YanColors.primaryNavy,
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              price,
              style: TextStyle(
                color: selected ? YanColors.white : YanColors.primaryBlue,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              perContract,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? Colors.white70 : YanColors.mutedText,
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
              const LiquidGlassWindow(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Mening Shartnomalarim (Advokat Reyestri)',
                      style: TextStyle(
                        color: YanColors.primaryNavy,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Har bir imzolangan elektron yuridik yordam shartnomasi YAN360 bazasida himoyalangan',
                      style: TextStyle(
                        color: YanColors.mutedText,
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
                                color: YanColors.lightBlue,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                item.contractNumber,
                                style: const TextStyle(
                                  color: YanColors.primaryBlue,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const Spacer(),
                            Text(
                              item.signedDate,
                              style: const TextStyle(
                                color: YanColors.subtleText,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.clientName,
                          style: const TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${item.caseCategory} • ${item.region}',
                          style: const TextStyle(
                            color: YanColors.mutedText,
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
                                color: YanColors.primaryBlue,
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
                                color: YanColors.successGreen.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Text(
                                item.statusLabel,
                                style: const TextStyle(
                                  color: Color(0xFF098562),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      isAssistantView
                          ? 'Mijozlar bilan Ishlash (Yordamchi Bo‘limi)'
                          : 'Shartnomali Mijozlar Bazasi',
                      style: const TextStyle(
                        color: YanColors.primaryNavy,
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
                        color: YanColors.mutedText,
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
                              backgroundColor: YanColors.primaryNavy,
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
                                      color: YanColors.primaryNavy,
                                      fontSize: 15.8,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${client.clientPhone} • ${client.region}',
                                    style: const TextStyle(
                                      color: YanColors.mutedText,
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
                                color: YanColors.successGreen.withValues(
                                  alpha: 0.16,
                                ),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                client.statusLabel,
                                style: const TextStyle(
                                  color: Color(0xFF098562),
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
                            color: YanColors.primaryBlue,
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: YanColors.primaryBlue,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                CupertinoIcons.person_2_fill,
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
                                    'Advokat Yordamchisi Ish Stoli',
                                    style: TextStyle(
                                      color: YanColors.primaryNavy,
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Biriktirilgan advokat: ${profile.assignedLawyerName} (YAN Legal Firm)',
                                    style: const TextStyle(
                                      color: YanColors.primaryBlue,
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
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LawyerMetricBox(
                                value: '$completedCount/${tasks.length}',
                                label: 'Bajarilgan',
                                onTap: () {},
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _LawyerMetricBox(
                                value: 'DOCX',
                                label: 'Hujjatlar ombori',
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
                                  ? YanColors.successGreen
                                  : YanColors.primaryBlue,
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
                                      color: YanColors.primaryNavy,
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
                                    style: const TextStyle(
                                      color: YanColors.mutedText,
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
                                color: YanColors.lightBlue,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                task.categoryLabel,
                                style: const TextStyle(
                                  color: YanColors.primaryBlue,
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
// Login Page Clean Input Fields & Strictly Monochromatic Solid Buttons
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
        color: YanColors.primaryNavy,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      placeholder: '** *** ** **',
      placeholderStyle: const TextStyle(
        color: YanColors.subtleText,
        fontSize: 14.5,
      ),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 15, right: 9),
        child: Icon(
          CupertinoIcons.phone_fill,
          size: 18,
          color: YanColors.primaryBlue,
        ),
      ),
      decoration: BoxDecoration(
        color: YanColors.lightBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YanColors.border),
      ),
      cursorColor: YanColors.primaryBlue,
    );
  }
}

class _CleanTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final TextInputType keyboardType;
  final IconData icon;

  const _CleanTextField({
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
        color: YanColors.primaryNavy,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      placeholder: hintText,
      placeholderStyle: const TextStyle(
        color: YanColors.subtleText,
        fontSize: 14.5,
      ),
      prefix: Padding(
        padding: const EdgeInsets.only(left: 15, right: 9),
        child: Icon(
          icon,
          size: 18,
          color: YanColors.primaryBlue,
        ),
      ),
      decoration: BoxDecoration(
        color: YanColors.lightBlue.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: YanColors.border),
      ),
      cursorColor: YanColors.primaryBlue,
    );
  }
}

/// Strictly monochromatic solid Primary Button: ONE solid #1677D2 background.
class _SolidPrimaryButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SolidPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  State<_SolidPrimaryButton> createState() => _SolidPrimaryButtonState();
}

class _SolidPrimaryButtonState extends State<_SolidPrimaryButton> {
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
        scale: _pressed ? 0.985 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            // Single solid #1677D2 background (no gradients or stripes)
            color: YanColors.primaryBlue,
            borderRadius: BorderRadius.circular(16),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: YanColors.primaryBlue.withValues(alpha: 0.22),
                blurRadius: 14,
                offset: const Offset(0, 6),
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
                  fontWeight: FontWeight.w700,
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

/// Strictly monochromatic solid Secondary Button: ONE solid #EAF5FF or #1677D2 background.
class _SolidSecondaryButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onPressed;

  const _SolidSecondaryButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onPressed,
  });

  @override
  State<_SolidSecondaryButton> createState() => _SolidSecondaryButtonState();
}

class _SolidSecondaryButtonState extends State<_SolidSecondaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.active
        ? YanColors.primaryBlue
        : YanColors.lightBlue;
    final fgColor = widget.active
        ? YanColors.white
        : YanColors.primaryNavy;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed();
      },
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12.5),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                widget.icon,
                size: 16,
                color: fgColor,
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
                    color: fgColor,
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
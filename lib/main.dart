import 'dart:io';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'screens/bosh_sahifa_page.dart';
import 'screens/hujjatlar_page.dart';
import 'screens/profil_page.dart';
import 'screens/services/alimony_claim_page.dart';
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
// MainDashboard: Strictly 4 Sections Per Role (Requirement 1)
// - Oddiy:     1. Bosh sahifa | 2. Arizalarim     | 3. Advokatxona | 4. Profil
// - Mijoz:     1. Bosh sahifa | 2. Arizalarim     | 3. Advokatim   | 4. Profil
// - Advokat:   1. Bosh sahifa | 2. Shartnomalarim | 3. Mijozlar    | 4. Profil
// - Yordamchi: 1. Bosh sahifa | 2. Vazifalar      | 3. Mijozlar    | 4. Profil
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

  List<DashboardNavData> _navItemsForRole(UserRole role) {
    switch (role) {
      case UserRole.oddiy:
        return const <DashboardNavData>[
          DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
          DashboardNavData(CupertinoIcons.doc_text_fill, 'Arizalarim'),
          DashboardNavData(CupertinoIcons.building_2_fill, 'Advokatxona'),
          DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
        ];
      case UserRole.mijoz:
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
          DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
        ];
      case UserRole.advokat:
        return const <DashboardNavData>[
          DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
          DashboardNavData(
            CupertinoIcons.doc_checkmark_fill,
            'Shartnomalarim',
          ),
          DashboardNavData(CupertinoIcons.person_2_fill, 'Mijozlar'),
          DashboardNavData(CupertinoIcons.person_crop_circle, 'Profil'),
        ];
      case UserRole.yordamchi:
        return const <DashboardNavData>[
          DashboardNavData(CupertinoIcons.house_fill, 'Bosh sahifa'),
          DashboardNavData(
            CupertinoIcons.checkmark_rectangle_fill,
            'Vazifalar',
          ),
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
          );
        }
        return _AdvokatxonaDirectoryPage(
          key: const ValueKey<String>('oddiy-advokatxona'),
          profile: profile,
          isMijozMode: false,
        );

      case UserRole.mijoz:
        if (_selectedTab == 0) {
          return const BoshSahifaPage(key: ValueKey<String>('mijoz-home'));
        }
        if (_selectedTab == 1) {
          return _ArizalarimRoleView(
            key: const ValueKey<String>('mijoz-arizalarim'),
            profile: profile,
          );
        }
        return _AdvokatxonaDirectoryPage(
          key: const ValueKey<String>('mijoz-advokatim'),
          profile: profile,
          isMijozMode: true,
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
          return const BoshSahifaPage(key: ValueKey<String>('yordamchi-home'));
        }
        if (_selectedTab == 1) {
          return _AssistantTasksRoleView(
            key: const ValueKey<String>('yordamchi-tasks'),
            profile: profile,
            onOpenClients: () => setState(() => _selectedTab = 2),
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
                  'Har bir rol uchun 4 ta maxsus bo‘lim va imtiyozlar avtomatik moslashadi:',
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
        final safeTab = _selectedTab.clamp(0, navItems.length - 1);

        return Scaffold(
          backgroundColor: YanColors.background,
          body: Stack(
            children: <Widget>[
              const DashboardBackground(),
              SafeArea(
                bottom: false,
                child: Column(
                  children: <Widget>[
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
                  selectedIndex: safeTab,
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
          color: Colors.white.withValues(alpha: 0.90),
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
            Container(width: 1, height: 16, color: YanColors.border),
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
// Requirement 2: Redesigned ADVOKATXONA / ADVOKATIM Page (Screenshot 2)
// - All filters collapsed into ONE top-right circular filter button
// - Quick sort tabs (Tavsiya etilgan | Yuqori reyting | Ko‘p izohlar)
// - Pinned Contracted Advocate at the top with VIP styling
// - Advocate cards with ratings, bio, specialty tags, and blue
//   "Profil" (opens LawyerDetailProfilePage) + "Xabar" (opens AdvocateClientChatPage)
// ═══════════════════════════════════════════════════════════════════════════

enum _LawyerSortMode { recommended, highestRated, mostReviewed }

class _AdvokatxonaDirectoryPage extends StatefulWidget {
  const _AdvokatxonaDirectoryPage({
    super.key,
    required this.profile,
    required this.isMijozMode,
  });

  final UserProfileData profile;
  final bool isMijozMode;

  @override
  State<_AdvokatxonaDirectoryPage> createState() =>
      _AdvokatxonaDirectoryPageState();
}

class _AdvokatxonaDirectoryPageState extends State<_AdvokatxonaDirectoryPage> {
  String _selectedRegion = 'Barchasi';
  String _selectedSpecialization = 'Barchasi';
  int _minExperienceYears = 0;
  _LawyerSortMode _sortMode = _LawyerSortMode.recommended;

  int get _activeFilterCount {
    var count = 0;
    if (_selectedRegion != 'Barchasi') count++;
    if (_selectedSpecialization != 'Barchasi') count++;
    if (_minExperienceYears > 0) count++;
    return count;
  }

  List<LawyerDirectoryProfile> get _sortedLawyers {
    final list = YanRoleDataCatalog.lawyers.where((lawyer) {
      final regionOk =
          _selectedRegion == 'Barchasi' || lawyer.region == _selectedRegion;
      final specOk =
          _selectedSpecialization == 'Barchasi' ||
          lawyer.specialization == _selectedSpecialization;
      final expOk = lawyer.experienceYears >= _minExperienceYears;
      return regionOk && specOk && expOk;
    }).toList();

    switch (_sortMode) {
      case _LawyerSortMode.recommended:
        list.sort((a, b) => b.rankingScore.compareTo(a.rankingScore));
      case _LawyerSortMode.highestRated:
        list.sort((a, b) => b.rating.compareTo(a.rating));
      case _LawyerSortMode.mostReviewed:
        list.sort((a, b) => b.feedbackCount.compareTo(a.feedbackCount));
    }
    return list;
  }

  void _openCollapsedFilterSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
              decoration: BoxDecoration(
                color: YanColors.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                border: Border.all(color: YanColors.border),
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
                          CupertinoIcons.slider_horizontal_3,
                          color: YanColors.primaryBlue,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Advokatlarni Saralash Filtrlari',
                            style: TextStyle(
                              color: YanColors.primaryNavy,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            setModalState(() {
                              _selectedRegion = 'Barchasi';
                              _selectedSpecialization = 'Barchasi';
                              _minExperienceYears = 0;
                            });
                            setState(() {});
                          },
                          child: const Text(
                            'Tozalash',
                            style: TextStyle(
                              color: YanColors.primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'VILOYAT / HUDUD:',
                      style: TextStyle(
                        color: YanColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: YanRoleDataCatalog.regions.map((region) {
                        final active = _selectedRegion == region;
                        return _FilterChipPill(
                          label: region,
                          active: active,
                          onTap: () {
                            setModalState(() => _selectedRegion = region);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'MUTAXASSISLIGI:',
                      style: TextStyle(
                        color: YanColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: YanRoleDataCatalog.specializations.map((spec) {
                        final active = _selectedSpecialization == spec;
                        return _FilterChipPill(
                          label: spec,
                          active: active,
                          onTap: () {
                            setModalState(() => _selectedSpecialization = spec);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ISH TAJRIBASI:',
                      style: TextStyle(
                        color: YanColors.mutedText,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <int>[0, 5, 8, 10].map((years) {
                        final active = _minExperienceYears == years;
                        return _FilterChipPill(
                          label: years == 0 ? 'Barchasi' : '$years+ yil',
                          active: active,
                          onTap: () {
                            setModalState(() => _minExperienceYears = years);
                            setState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: LiquidActionButton(
                        label:
                            'Natijalarni ko‘rsatish (${_sortedLawyers.length} advokat)',
                        icon: CupertinoIcons.checkmark_alt,
                        onPressed: () => Navigator.pop(sheetContext),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openLawyerProfilePage(LawyerDirectoryProfile lawyer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LawyerDetailProfilePage(
          lawyer: lawyer,
          profile: widget.profile,
        ),
      ),
    );
  }

  void _openLawyerChatPage(LawyerDirectoryProfile lawyer) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdvocateClientChatPage(
          lawyer: lawyer,
          profile: widget.profile,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pinnedLawyer = YanRoleDataCatalog.byId(
      widget.profile.contractedLawyerId,
    );
    final allLawyers = _sortedLawyers;
    final locationLabel = _selectedRegion == 'Barchasi'
        ? widget.profile.region
        : _selectedRegion;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        // 1. Clean Top Header + Collapsed Right-Top Filter Button (Screenshot 2)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: YanColors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: YanColors.border),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: YanColors.primaryNavy.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    CupertinoIcons.shield_lefthalf_fill,
                    color: YanColors.primaryBlue,
                    size: 20,
                  ),
                ),
                Expanded(
                  child: Column(
                    children: <Widget>[
                      Text(
                        widget.isMijozMode
                            ? 'Advokatim va Advokatxona'
                            : 'Shaxsiy Advokatlar',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        locationLabel,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: YanColors.mutedText,
                          fontSize: 12.6,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Collapsed Single Top-Right Filter Button
                GestureDetector(
                  onTap: _openCollapsedFilterSheet,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _activeFilterCount > 0
                              ? YanColors.primaryBlue
                              : YanColors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: YanColors.border),
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: YanColors.primaryNavy.withValues(
                                alpha: 0.06,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          CupertinoIcons.slider_horizontal_3,
                          color: _activeFilterCount > 0
                              ? YanColors.white
                              : YanColors.primaryNavy,
                          size: 19,
                        ),
                      ),
                      if (_activeFilterCount > 0)
                        Positioned(
                          right: -2,
                          top: -2,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: YanColors.successGreen,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                '$_activeFilterCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // 2. Sort Pill Tabs (Recommended | Highest rated | Most reviewed — Screenshot 2)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          sliver: SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: <Widget>[
                  _SortTabPill(
                    label: 'Tavsiya etilgan',
                    selected: _sortMode == _LawyerSortMode.recommended,
                    onTap: () => setState(
                      () => _sortMode = _LawyerSortMode.recommended,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SortTabPill(
                    label: 'Eng yuqori reyting',
                    selected: _sortMode == _LawyerSortMode.highestRated,
                    onTap: () => setState(
                      () => _sortMode = _LawyerSortMode.highestRated,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SortTabPill(
                    label: 'Ko‘p izohlar',
                    selected: _sortMode == _LawyerSortMode.mostReviewed,
                    onTap: () => setState(
                      () => _sortMode = _LawyerSortMode.mostReviewed,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // 3. Pinned User's Advocate at the Top of the Page
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
          sliver: SliverToBoxAdapter(
            child: _PinnedAdvocateBannerCard(
              lawyer: pinnedLawyer,
              profile: widget.profile,
              onProfileTap: () => _openLawyerProfilePage(pinnedLawyer),
              onMessageTap: () => _openLawyerChatPage(pinnedLawyer),
            ),
          ),
        ),

        // 4. All Advocates Directory Cards (Screenshot 2 style)
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 118),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final lawyer = allLawyers[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: _AdvocateDirectoryCard(
                    lawyer: lawyer,
                    isPinnedContract:
                        lawyer.id == widget.profile.contractedLawyerId,
                    onProfileTap: () => _openLawyerProfilePage(lawyer),
                    onMessageTap: () => _openLawyerChatPage(lawyer),
                  ),
                );
              },
              childCount: allLawyers.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _SortTabPill extends StatelessWidget {
  const _SortTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? YanColors.primaryBlue : YanColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? YanColors.primaryBlue : YanColors.border,
          ),
          boxShadow: selected
              ? <BoxShadow>[
                  BoxShadow(
                    color: YanColors.primaryBlue.withValues(alpha: 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? YanColors.white : YanColors.primaryNavy,
            fontSize: 13.0,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _PinnedAdvocateBannerCard extends StatelessWidget {
  const _PinnedAdvocateBannerCard({
    required this.lawyer,
    required this.profile,
    required this.onProfileTap,
    required this.onMessageTap,
  });

  final LawyerDirectoryProfile lawyer;
  final UserProfileData profile;
  final VoidCallback onProfileTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    final isMijoz = profile.roleType == UserRole.mijoz;

    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F8FF),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: YanColors.primaryBlue.withValues(alpha: 0.42),
            width: 1.4,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: YanColors.primaryBlue.withValues(alpha: 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Pinned Header Strip
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: YanColors.primaryBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        CupertinoIcons.pin_fill,
                        color: Colors.white,
                        size: 11.5,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isMijoz
                            ? 'SHARTNOMALI ADVOKATIM • PINNED'
                            : 'BIRIKTIRILGAN ADVOKAT • PINNED',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.6,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                const Icon(
                  CupertinoIcons.star_fill,
                  color: Color(0xFFF59E0B),
                  size: 15,
                ),
                const SizedBox(width: 4),
                Text(
                  '${lawyer.rating}',
                  style: const TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 3),
                Text(
                  '(${lawyer.feedbackCount} izoh)',
                  style: const TextStyle(
                    color: YanColors.mutedText,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _LawyerAvatarPortrait(lawyer: lawyer, size: 60),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        lawyer.fullName,
                        style: const TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lawyer.title} • ${lawyer.specialization}',
                        style: const TextStyle(
                          color: YanColors.primaryBlue,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${lawyer.experienceYears} yil tajriba • Yordamchi: ${lawyer.assistantName}',
                        style: const TextStyle(
                          color: YanColors.mutedText,
                          fontSize: 11.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              lawyer.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: YanColors.primaryNavy,
                fontSize: 12.2,
                height: 1.32,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        isMijoz
                            ? 'Shartnoma № ${profile.contractNumber ?? "SH-2026/084"}'
                            : 'Bepul dastlabki maslahat',
                        style: const TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const Text(
                        'Javob vaqti: ~10 daqiqada',
                        style: TextStyle(
                          color: YanColors.mutedText,
                          fontSize: 11.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _CardPillButton(
                  label: 'Profil',
                  isPrimary: false,
                  onTap: onProfileTap,
                ),
                const SizedBox(width: 8),
                _CardPillButton(
                  label: 'Xabar',
                  isPrimary: true,
                  onTap: onMessageTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AdvocateDirectoryCard extends StatelessWidget {
  const _AdvocateDirectoryCard({
    required this.lawyer,
    required this.isPinnedContract,
    required this.onProfileTap,
    required this.onMessageTap,
  });

  final LawyerDirectoryProfile lawyer;
  final bool isPinnedContract;
  final VoidCallback onProfileTap;
  final VoidCallback onMessageTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onProfileTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: YanColors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: YanColors.border, width: 1.15),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: YanColors.primaryNavy.withValues(alpha: 0.055),
              blurRadius: 18,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Top Row: Avatar + Name/Title/Exp + Star Rating & Reviews (Screenshot 2)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _LawyerAvatarPortrait(lawyer: lawyer, size: 56),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        lawyer.fullName,
                        style: const TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 16.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lawyer.specialization,
                        style: const TextStyle(
                          color: YanColors.mutedText,
                          fontSize: 12.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${lawyer.experienceYears} yil tajriba • ${lawyer.region}',
                        style: const TextStyle(
                          color: YanColors.subtleText,
                          fontSize: 11.6,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: <Widget>[
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        const Icon(
                          CupertinoIcons.star_fill,
                          color: Color(0xFFF59E0B),
                          size: 15,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${lawyer.rating}',
                          style: const TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '(${lawyer.feedbackCount} izoh)',
                      style: const TextStyle(
                        color: YanColors.subtleText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Bio text
            Text(
              lawyer.bio,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: YanColors.mutedText,
                fontSize: 12.2,
                height: 1.34,
              ),
            ),
            const SizedBox(height: 10),

            // Specialty Tags + Available Pill (Screenshot 2)
            Wrap(
              spacing: 7,
              runSpacing: 6,
              children: <Widget>[
                _SpecialtyTagPill(text: lawyer.specialization),
                _SpecialtyTagPill(text: '${lawyer.wonCasesCount} yutuq'),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4.5,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6FAF3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Bo‘sh (Online)',
                    style: TextStyle(
                      color: Color(0xFF098562),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),

            // Bottom Row: Consultation Info on Left + Profile & Message Blue Buttons on Right
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Bepul maslahat',
                        style: TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 12.4,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Javob beradi: ~15 daqiqa',
                        style: const TextStyle(
                          color: YanColors.mutedText,
                          fontSize: 11.2,
                        ),
                      ),
                    ],
                  ),
                ),
                _CardPillButton(
                  label: 'Profil',
                  isPrimary: false,
                  onTap: onProfileTap,
                ),
                const SizedBox(width: 8),
                _CardPillButton(
                  label: 'Xabar',
                  isPrimary: true,
                  onTap: onMessageTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SpecialtyTagPill extends StatelessWidget {
  const _SpecialtyTagPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F6FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: YanColors.mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _CardPillButton extends StatelessWidget {
  const _CardPillButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9.5),
        decoration: BoxDecoration(
          // Single solid blue (#1677D2) or light-blue (#EAF5FF)
          color: isPrimary ? YanColors.primaryBlue : YanColors.lightBlue,
          borderRadius: BorderRadius.circular(18),
          border: isPrimary
              ? null
              : Border.all(
                  color: YanColors.primaryBlue.withValues(alpha: 0.28),
                ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? Colors.white : YanColors.primaryBlue,
            fontSize: 12.6,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _LawyerAvatarPortrait extends StatelessWidget {
  const _LawyerAvatarPortrait({
    required this.lawyer,
    this.size = 56,
  });

  final LawyerDirectoryProfile lawyer;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: YanColors.primaryNavy,
            border: Border.all(color: YanColors.border, width: 1.5),
          ),
          child: Center(
            child: Text(
              lawyer.initials,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.32,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 13,
            height: 13,
            decoration: BoxDecoration(
              color: YanColors.successGreen,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Full-Screen Advocate Profile Page (Matches Screenshot 3: image_c998f1.png)
// Opens when the user clicks on an advocate card or "Profil" button
// ═══════════════════════════════════════════════════════════════════════════

class LawyerDetailProfilePage extends StatefulWidget {
  const LawyerDetailProfilePage({
    super.key,
    required this.lawyer,
    required this.profile,
  });

  final LawyerDirectoryProfile lawyer;
  final UserProfileData profile;

  @override
  State<LawyerDetailProfilePage> createState() =>
      _LawyerDetailProfilePageState();
}

class _LawyerDetailProfilePageState extends State<LawyerDetailProfilePage> {
  bool _isFavorite = false;
  int _selectedDayIndex = 2;

  static const List<Map<String, String>> _days = <Map<String, String>>[
    <String, String>{'num': '06', 'day': 'Juma'},
    <String, String>{'num': '07', 'day': 'Shanba'},
    <String, String>{'num': '08', 'day': 'Yakshanba'},
    <String, String>{'num': '09', 'day': 'Dushanba'},
    <String, String>{'num': '10', 'day': 'Seshanba'},
  ];

  void _openChat() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdvocateClientChatPage(
          lawyer: widget.lawyer,
          profile: widget.profile,
        ),
      ),
    );
  }

  void _bookOrSignContract() {
    final selectedDay = _days[_selectedDayIndex];
    showCupertinoDialog<void>(
      context: context,
      builder: (dialogContext) {
        return CupertinoAlertDialog(
          title: Text(widget.lawyer.fullName),
          content: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Tanlangan sana: ${selectedDay["num"]}-Noyabr (${selectedDay["day"]}).\n\n'
              'Advokat bilan uchrashuv belgilash yoki rasmiy yuridik yordam shartnomasini imzolashni tasdiqlaysizmi?\n'
              '• Shartnoma imzolansa 3 oy BEPUL VIP maqom va 30%–50% chegirmalar faollashadi!',
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
                final contractNo =
                    'SH-2026/${100 + DateTime.now().millisecondsSinceEpoch % 899}';
                userProfile.switchRole(
                  UserRole.mijoz,
                  lawyerId: widget.lawyer.id,
                  contractNo: contractNo,
                );
                ActivityHistoryRepository.instance.record(
                  title:
                      'Advokat ${widget.lawyer.fullName} qabuliga yozildi ($contractNo)',
                  description:
                      'Sana: ${selectedDay["num"]}-Noyabr • Shartnoma va MIJOZ VIP maqomi faollashdi',
                  category: ActivityCategory.lawyer,
                  statusLabel: 'Tasdiqlandi',
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: YanColors.primaryNavy,
                    content: Text(
                      '${widget.lawyer.fullName} bilan shartnoma va uchrashuv tasdiqlandi!',
                    ),
                  ),
                );
              },
              child: const Text('Tasdiqlash'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final lawyer = widget.lawyer;
    final discountedPrice = widget.profile.applyDiscount(
      lawyer.consultationPriceUzs,
      category: 'consultation',
    );
    final priceFormatted = '${(discountedPrice / 1000).round()} 000 so‘m';

    return Scaffold(
      backgroundColor: YanColors.background,
      body: Stack(
        children: <Widget>[
          const DashboardBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                // Top Bar: Back Button + Favorite Heart Button (Screenshot 3)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: YanColors.border),
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_left,
                            color: YanColors.primaryNavy,
                            size: 20,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => setState(() => _isFavorite = !_isFavorite),
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: YanColors.border),
                          ),
                          child: Icon(
                            _isFavorite
                                ? CupertinoIcons.heart_fill
                                : CupertinoIcons.heart,
                            color: _isFavorite
                                ? YanColors.destructiveRed
                                : YanColors.primaryNavy,
                            size: 20,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Hero Section (Name + Specialization + Rate on Left, Portrait on Right)
                        SizedBox(
                          height: 215,
                          child: Stack(
                            children: <Widget>[
                              // Right Portrait Card (Matches Alan Dershowitz hero in Screenshot 3)
                              Positioned(
                                right: 0,
                                top: 0,
                                bottom: 10,
                                width: 162,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(26),
                                    color: YanColors.primaryNavy,
                                    border: Border.all(
                                      color: YanColors.border,
                                      width: 1.5,
                                    ),
                                    boxShadow: <BoxShadow>[
                                      BoxShadow(
                                        color: YanColors.primaryNavy.withValues(
                                          alpha: 0.14,
                                        ),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: Stack(
                                    alignment: Alignment.center,
                                    children: <Widget>[
                                      Positioned(
                                        top: 14,
                                        right: 14,
                                        child: Opacity(
                                          opacity: 0.20,
                                          child: Image.asset(
                                            'assets/logo.png',
                                            width: 54,
                                            height: 54,
                                            filterQuality: FilterQuality.high,
                                          ),
                                        ),
                                      ),
                                      Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: <Widget>[
                                          Container(
                                            width: 78,
                                            height: 78,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: YanColors.primaryBlue,
                                              border: Border.all(
                                                color: Colors.white,
                                                width: 2.2,
                                              ),
                                            ),
                                            child: Center(
                                              child: Text(
                                                lawyer.initials,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: YanColors.successGreen,
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'Litsenziya: ${lawyer.licenseNumber}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
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
                              // Left Name, Specialization & Rate
                              Positioned(
                                left: 0,
                                top: 10,
                                right: 170,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    Text(
                                      lawyer.fullName.replaceAll(' ', '\n'),
                                      style: const TextStyle(
                                        color: YanColors.primaryNavy,
                                        fontSize: 26,
                                        fontWeight: FontWeight.w900,
                                        height: 1.12,
                                        letterSpacing: -0.4,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      lawyer.specialization,
                                      style: const TextStyle(
                                        color: YanColors.mutedText,
                                        fontSize: 13.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                    Text(
                                      priceFormatted,
                                      style: const TextStyle(
                                        color: YanColors.primaryNavy,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const Text(
                                      '/ konsultatsiya',
                                      style: TextStyle(
                                        color: YanColors.mutedText,
                                        fontSize: 12.2,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Action Strip: [ⓘ Details] + Call + Video + Solid Blue Chat Button (Screenshot 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: YanColors.border),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: YanColors.primaryNavy.withValues(
                                  alpha: 0.05,
                                ),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            children: <Widget>[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 9,
                                ),
                                decoration: BoxDecoration(
                                  color: YanColors.lightBlue,
                                  borderRadius: BorderRadius.circular(18),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    const Icon(
                                      CupertinoIcons.info_circle,
                                      size: 16,
                                      color: YanColors.primaryNavy,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      lawyer.region,
                                      style: const TextStyle(
                                        color: YanColors.primaryNavy,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),
                              _CircleProfileActionButton(
                                icon: CupertinoIcons.phone,
                                isSolidBlue: false,
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      backgroundColor: YanColors.primaryNavy,
                                      content: Text(
                                        'Advokat raqami: ${lawyer.phone}',
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(width: 8),
                              _CircleProfileActionButton(
                                icon: CupertinoIcons.videocam,
                                isSolidBlue: false,
                                onTap: _openChat,
                              ),
                              const SizedBox(width: 8),
                              _CircleProfileActionButton(
                                icon: CupertinoIcons.chat_bubble_text_fill,
                                isSolidBlue: true,
                                onTap: _openChat,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 3-Column Stats Card (Cases Won | Experience | Endorsement — Screenshot 3)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: YanColors.border),
                          ),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: _LawyerDetailStatCol(
                                  icon: CupertinoIcons.briefcase,
                                  value: '${lawyer.wonCasesCount}+',
                                  label: 'Yutgan ishlari',
                                ),
                              ),
                              Expanded(
                                child: _LawyerDetailStatCol(
                                  icon: CupertinoIcons.clock,
                                  value: '${lawyer.experienceYears} yil',
                                  label: 'Tajriba',
                                ),
                              ),
                              Expanded(
                                child: _LawyerDetailStatCol(
                                  icon: CupertinoIcons.star,
                                  value: '${lawyer.feedbackCount}+',
                                  label: 'Izoh va ishonch',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Select Date + About Lawyer Card (Screenshot 3)
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            borderRadius: BorderRadius.circular(26),
                            border: Border.all(color: YanColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: const <Widget>[
                                  Text(
                                    'Sana tanlash',
                                    style: TextStyle(
                                      color: YanColors.primaryNavy,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '<  Noyabr  >',
                                    style: TextStyle(
                                      color: YanColors.primaryNavy,
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: List<Widget>.generate(_days.length, (
                                  idx,
                                ) {
                                  final item = _days[idx];
                                  final selected = _selectedDayIndex == idx;
                                  return Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _selectedDayIndex = idx,
                                      ),
                                      child: Container(
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 3,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          color: selected
                                              ? YanColors.lightBlue
                                              : Colors.transparent,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          border: selected
                                              ? Border.all(
                                                  color: YanColors.primaryBlue,
                                                )
                                              : null,
                                        ),
                                        child: Column(
                                          children: <Widget>[
                                            Text(
                                              item['num']!,
                                              style: TextStyle(
                                                color: YanColors.primaryNavy,
                                                fontSize: 15,
                                                fontWeight: selected
                                                    ? FontWeight.w900
                                                    : FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              item['day']!,
                                              style: TextStyle(
                                                color: selected
                                                    ? YanColors.primaryBlue
                                                    : YanColors.mutedText,
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Advokat haqida',
                                style: TextStyle(
                                  color: YanColors.primaryNavy,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${lawyer.bio}\n\n'
                                '• Litsenziya raqami: ${lawyer.licenseNumber} ("YAN LEGAL FIRM" MCHJ)\n'
                                '• Biriktirilgan yordamchi: ${lawyer.assistantName} (${lawyer.assistantRole})\n'
                                '• Shartnoma imzolanganda: 3 oy BEPUL obuna va barcha xizmatlarga 30%–50% chegirma.',
                                style: const TextStyle(
                                  color: YanColors.mutedText,
                                  fontSize: 13,
                                  height: 1.42,
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Book Appointment / Sign Contract Solid #1677D2 Button
                              SizedBox(
                                width: double.infinity,
                                child: LiquidActionButton(
                                  label:
                                      'Qabulga yozilish / Shartnoma tuzish',
                                  icon: CupertinoIcons.calendar_badge_plus,
                                  onPressed: _bookOrSignContract,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class _CircleProfileActionButton extends StatelessWidget {
  const _CircleProfileActionButton({
    required this.icon,
    required this.isSolidBlue,
    required this.onTap,
  });

  final IconData icon;
  final bool isSolidBlue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isSolidBlue ? YanColors.primaryBlue : YanColors.lightBlue,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 19,
          color: isSolidBlue ? Colors.white : YanColors.primaryNavy,
        ),
      ),
    );
  }
}

class _LawyerDetailStatCol extends StatelessWidget {
  const _LawyerDetailStatCol({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Icon(icon, size: 17, color: YanColors.primaryBlue),
        const SizedBox(width: 7),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                value,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YanColors.mutedText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Full-Screen Advocate & Client Messenger Page (Requirement 2)
// Supports:
// - Voice Messages (recording & interactive playback)
// - Sending any kind of Files (.docx, .pdf), Videos, and Photos
// - "Saqlash" (Save) option on advocate-sent files, voice notes, photos & videos
// ═══════════════════════════════════════════════════════════════════════════

enum _ChatMediaType { text, voice, file, photo, video }

class _ChatMessageItem {
  _ChatMessageItem({
    required this.id,
    required this.fromLawyer,
    required this.type,
    required this.text,
    required this.timeLabel,
    this.fileName,
    this.fileSizeLabel,
    this.durationLabel,
    this.localFilePath,
    this.isSaved = false,
    this.isPlaying = false,
  });

  final String id;
  final bool fromLawyer;
  final _ChatMediaType type;
  final String text;
  final String timeLabel;
  final String? fileName;
  final String? fileSizeLabel;
  final String? durationLabel;
  final String? localFilePath;
  bool isSaved;
  bool isPlaying;
}

class AdvocateClientChatPage extends StatefulWidget {
  const AdvocateClientChatPage({
    super.key,
    required this.lawyer,
    required this.profile,
  });

  final LawyerDirectoryProfile lawyer;
  final UserProfileData profile;

  @override
  State<AdvocateClientChatPage> createState() => _AdvocateClientChatPageState();
}

class _AdvocateClientChatPageState extends State<AdvocateClientChatPage> {
  final TextEditingController _textController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  bool _isRecordingVoice = false;

  late final List<_ChatMessageItem> _messages = <_ChatMessageItem>[
    _ChatMessageItem(
      id: 'MSG-1',
      fromLawyer: true,
      type: _ChatMediaType.text,
      text:
          'Assalomu alaykum, ${widget.profile.firstName}! Men advokat ${widget.lawyer.fullName}. Sizning murojaatingiz va hujjatlaringizni ko‘rib chiqdim.',
      timeLabel: '10:12',
    ),
    _ChatMessageItem(
      id: 'MSG-2',
      fromLawyer: true,
      type: _ChatMediaType.voice,
      text: 'Advokat ovozli tushuntirishi (Sud tartibi bo‘yicha)',
      durationLabel: '0:38',
      fileSizeLabel: '420 KB • Ovozli xabar',
      timeLabel: '10:13',
    ),
    _ChatMessageItem(
      id: 'MSG-3',
      fromLawyer: true,
      type: _ChatMediaType.file,
      text: 'Sudga topshirish uchun tayyorlangan rasmiy da’vo arizasi nusxasi:',
      fileName: 'Sud_Davo_Arizasi_YAN360_Rasmiy.docx',
      fileSizeLabel: '148 KB • Microsoft Word (.docx)',
      timeLabel: '10:15',
    ),
    _ChatMessageItem(
      id: 'MSG-4',
      fromLawyer: true,
      type: _ChatMediaType.video,
      text: 'Sud majlisiga tayyorgarlik bo‘yicha video yo‘riqnoma',
      fileName: 'Sud_Majlisi_Yoriqnomasi_HD.mp4',
      durationLabel: '1:45',
      fileSizeLabel: '8.4 MB • MP4 Video',
      timeLabel: '10:16',
    ),
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _sendTextMessage() {
    final txt = _textController.text.trim();
    if (txt.isEmpty) return;
    setState(() {
      _messages.add(
        _ChatMessageItem(
          id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
          fromLawyer: false,
          type: _ChatMediaType.text,
          text: txt,
          timeLabel: 'Hozir',
        ),
      );
      _textController.clear();
    });
  }

  void _sendVoiceMessage() {
    setState(() {
      _isRecordingVoice = false;
      _messages.add(
        _ChatMessageItem(
          id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
          fromLawyer: false,
          type: _ChatMediaType.voice,
          text: 'Mijoz ovozli xabari',
          durationLabel: '0:19',
          fileSizeLabel: '210 KB • Ovozli xabar',
          timeLabel: 'Hozir',
        ),
      );
    });
  }

  Future<void> _pickAndSendPhoto() async {
    try {
      final picked = await _picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _messages.add(
            _ChatMessageItem(
              id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
              fromLawyer: false,
              type: _ChatMediaType.photo,
              text: 'Yuborilgan fotosurat hujjati',
              fileName: picked.name,
              fileSizeLabel: '1.2 MB • JPEG Rasm',
              localFilePath: picked.path,
              timeLabel: 'Hozir',
            ),
          );
        });
        return;
      }
    } catch (_) {
      // Fallback sample photo attachment if gallery is empty
    }
    setState(() {
      _messages.add(
        _ChatMessageItem(
          id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
          fromLawyer: false,
          type: _ChatMediaType.photo,
          text: 'Guvohnoma va tasdiqlovchi fotosurat ilovasi',
          fileName: 'Hujjat_Tasviri_2026.jpg',
          fileSizeLabel: '1.1 MB • Rasm',
          timeLabel: 'Hozir',
        ),
      );
    });
  }

  void _sendAttachmentItem({
    required _ChatMediaType type,
    required String title,
    required String fileName,
    required String sizeLabel,
    String? duration,
  }) {
    setState(() {
      _messages.add(
        _ChatMessageItem(
          id: 'MSG-${DateTime.now().millisecondsSinceEpoch}',
          fromLawyer: false,
          type: type,
          text: title,
          fileName: fileName,
          fileSizeLabel: sizeLabel,
          durationLabel: duration,
          timeLabel: 'Hozir',
        ),
      );
    });
  }

  void _showAttachmentPickerSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 26),
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
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: YanColors.border,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Advokatga Fayl, Rasm, Video yoki Ovoz Yuborish',
                  style: TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _AttachmentOptionTile(
                        icon: CupertinoIcons.photo_fill,
                        label: 'Rasm (Foto)',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _pickAndSendPhoto();
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AttachmentOptionTile(
                        icon: CupertinoIcons.videocam_fill,
                        label: 'Video fayl',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _sendAttachmentItem(
                            type: _ChatMediaType.video,
                            title: 'Mijoz tomonidan yuborilgan video dalil',
                            fileName: 'Dalil_Video_Yozuvi.mp4',
                            sizeLabel: '6.2 MB • MP4 Video',
                            duration: '0:52',
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _AttachmentOptionTile(
                        icon: CupertinoIcons.doc_text_fill,
                        label: 'Hujjat (.docx/.pdf)',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _sendAttachmentItem(
                            type: _ChatMediaType.file,
                            title: 'Ilova qilingan rasmiy hujjat fayli',
                            fileName: 'Fuqarolik_Hujjati_Ilova.docx',
                            sizeLabel: '96 KB • DOCX Hujjat',
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _AttachmentOptionTile(
                        icon: CupertinoIcons.mic_fill,
                        label: 'Ovozli xabar',
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _sendVoiceMessage();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _saveLawyerAttachment(_ChatMessageItem msg) {
    setState(() => msg.isSaved = true);
    ActivityHistoryRepository.instance.record(
      title: 'Advokat yuborgan fayl saqlandi: ${msg.fileName ?? msg.text}',
      description:
          '${widget.lawyer.fullName} tomonidan yuborilgan material qurilmaga va hujjatlar omboriga saqlandi',
      category: ActivityCategory.documents,
      statusLabel: 'Saqlandi',
    );
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: YanColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        content: Text(
          '"${msg.fileName ?? "Ovozli xabar"}" muvaffaqiyatli saqlandi!',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lawyer = widget.lawyer;

    return Scaffold(
      backgroundColor: YanColors.background,
      body: SafeArea(
        child: Column(
          children: <Widget>[
            // Top Chat Header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              decoration: const BoxDecoration(
                color: YanColors.white,
                border: Border(bottom: BorderSide(color: YanColors.border)),
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: YanColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.chevron_left,
                        color: YanColors.primaryNavy,
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _LawyerAvatarPortrait(lawyer: lawyer, size: 42),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          lawyer.fullName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Text(
                          'Online • Ovoz, fayl, foto va video aloqa',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: YanColors.successGreen,
                            fontSize: 11.2,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _showAttachmentPickerSheet(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: YanColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.folder_badge_plus,
                        color: YanColors.primaryBlue,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Message List
            Expanded(
              child: ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  final isMe = !msg.fromLawyer;

                  return Align(
                    alignment: isMe
                        ? Alignment.centerRight
                        : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(13),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.80,
                      ),
                      decoration: BoxDecoration(
                        color: isMe ? YanColors.primaryBlue : YanColors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: isMe
                            ? null
                            : Border.all(color: YanColors.border, width: 1.15),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: YanColors.primaryNavy.withValues(
                              alpha: 0.05,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          if (msg.type == _ChatMediaType.voice)
                            _VoiceMessageBubbleContent(
                              msg: msg,
                              isMe: isMe,
                              onPlayToggle: () =>
                                  setState(() => msg.isPlaying = !msg.isPlaying),
                            )
                          else if (msg.type == _ChatMediaType.file ||
                              msg.type == _ChatMediaType.video ||
                              msg.type == _ChatMediaType.photo)
                            _MediaAttachmentBubbleContent(
                              msg: msg,
                              isMe: isMe,
                            )
                          else
                            Text(
                              msg.text,
                              style: TextStyle(
                                color: isMe
                                    ? Colors.white
                                    : YanColors.primaryNavy,
                                fontSize: 13.8,
                                height: 1.35,
                                fontWeight: FontWeight.w500,
                              ),
                            ),

                          const SizedBox(height: 6),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                msg.timeLabel,
                                style: TextStyle(
                                  color: isMe
                                      ? Colors.white70
                                      : YanColors.subtleText,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              // Save button ("Saqlash") for any file, voice, photo, or video sent by Advocate
                              if (msg.fromLawyer &&
                                  msg.type != _ChatMediaType.text) ...<Widget>[
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: () => _saveLawyerAttachment(msg),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 9,
                                      vertical: 3.5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: msg.isSaved
                                          ? YanColors.successGreen
                                          : YanColors.primaryBlue,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: <Widget>[
                                        Icon(
                                          msg.isSaved
                                              ? CupertinoIcons.checkmark_alt
                                              : CupertinoIcons.arrow_down_to_line,
                                          size: 11.5,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          msg.isSaved ? 'Saqlandi' : 'Saqlash',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Voice Recording Banner if active
            if (_isRecordingVoice)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 10,
                ),
                color: YanColors.lightBlue,
                child: Row(
                  children: <Widget>[
                    const Icon(
                      CupertinoIcons.mic_circle_fill,
                      color: YanColors.destructiveRed,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Ovozli xabar yozilmoqda... (0:06)',
                        style: TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _isRecordingVoice = false),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          'Bekor',
                          style: TextStyle(
                            color: YanColors.destructiveRed,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    LiquidActionButton(
                      label: 'Yuborish',
                      icon: CupertinoIcons.paperplane_fill,
                      compact: true,
                      onPressed: _sendVoiceMessage,
                    ),
                  ],
                ),
              ),

            // Bottom Composer Bar (+ Attachment, Text Input, Voice Mic & Solid Blue Send)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: const BoxDecoration(
                color: YanColors.white,
                border: Border(top: BorderSide(color: YanColors.border)),
              ),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: _showAttachmentPickerSheet,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: YanColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.paperclip,
                        color: YanColors.primaryBlue,
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: CupertinoTextField(
                      controller: _textController,
                      placeholder: 'Xabar, fayl yoki ovoz yuboring...',
                      placeholderStyle: const TextStyle(
                        color: YanColors.mutedText,
                        fontSize: 13.8,
                      ),
                      style: const TextStyle(
                        color: YanColors.primaryNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: YanColors.lightBlue.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: YanColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () =>
                        setState(() => _isRecordingVoice = !_isRecordingVoice),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _isRecordingVoice
                            ? YanColors.destructiveRed
                            : YanColors.lightBlue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        CupertinoIcons.mic_fill,
                        color: _isRecordingVoice
                            ? Colors.white
                            : YanColors.primaryNavy,
                        size: 19,
                      ),
                    ),
                  ),
                  const SizedBox(width: 7),
                  GestureDetector(
                    onTap: _sendTextMessage,
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: YanColors.primaryBlue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        CupertinoIcons.paperplane_fill,
                        color: Colors.white,
                        size: 18,
                      ),
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

class _VoiceMessageBubbleContent extends StatelessWidget {
  const _VoiceMessageBubbleContent({
    required this.msg,
    required this.isMe,
    required this.onPlayToggle,
  });

  final _ChatMessageItem msg;
  final bool isMe;
  final VoidCallback onPlayToggle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        GestureDetector(
          onTap: onPlayToggle,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isMe ? Colors.white : YanColors.primaryBlue,
              shape: BoxShape.circle,
            ),
            child: Icon(
              msg.isPlaying
                  ? CupertinoIcons.pause_fill
                  : CupertinoIcons.play_arrow_solid,
              color: isMe ? YanColors.primaryBlue : Colors.white,
              size: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                msg.text,
                style: TextStyle(
                  color: isMe ? Colors.white : YanColors.primaryNavy,
                  fontSize: 12.8,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${msg.durationLabel ?? "0:20"} • ${msg.fileSizeLabel ?? "Ovozli xabar"}',
                style: TextStyle(
                  color: isMe ? Colors.white70 : YanColors.mutedText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaAttachmentBubbleContent extends StatelessWidget {
  const _MediaAttachmentBubbleContent({
    required this.msg,
    required this.isMe,
  });

  final _ChatMessageItem msg;
  final bool isMe;

  IconData get _icon => switch (msg.type) {
    _ChatMediaType.video => CupertinoIcons.play_rectangle_fill,
    _ChatMediaType.photo => CupertinoIcons.photo_fill,
    _ => CupertinoIcons.doc_text_fill,
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (msg.localFilePath != null &&
            File(msg.localFilePath!).existsSync()) ...<Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              File(msg.localFilePath!),
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.white.withValues(alpha: 0.16)
                : YanColors.lightBlue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isMe ? Colors.white : YanColors.primaryBlue,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  _icon,
                  color: isMe ? YanColors.primaryBlue : Colors.white,
                  size: 19,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      msg.fileName ?? msg.text,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isMe ? Colors.white : YanColors.primaryNavy,
                        fontSize: 12.8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      msg.fileSizeLabel ?? 'Biriktirilgan fayl',
                      style: TextStyle(
                        color: isMe ? Colors.white70 : YanColors.mutedText,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          msg.text,
          style: TextStyle(
            color: isMe ? Colors.white : YanColors.primaryNavy,
            fontSize: 12.8,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AttachmentOptionTile extends StatelessWidget {
  const _AttachmentOptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: YanColors.lightBlue,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: YanColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: YanColors.primaryBlue, size: 20),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
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
// ARIZALARIM, ADVOKAT & YORDAMCHI ROLE VIEWS
// ═══════════════════════════════════════════════════════════════════════════

class _ArizalarimRoleView extends StatefulWidget {
  const _ArizalarimRoleView({
    super.key,
    required this.profile,
  });

  final UserProfileData profile;

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
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
        decoration: BoxDecoration(
          color: active ? YanColors.primaryBlue : YanColors.lightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? YanColors.white : YanColors.primaryNavy,
            fontSize: 11.6,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

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
    final defaultLawyer = YanRoleDataCatalog.byId(profile.contractedLawyerId);

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
                                label: 'DOCX Hujjat',
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
                                label: 'Xabar yozish',
                                icon: CupertinoIcons.chat_bubble_text_fill,
                                compact: true,
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute<void>(
                                      builder: (_) => AdvocateClientChatPage(
                                        lawyer: defaultLawyer,
                                        profile: profile,
                                      ),
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
    required this.onOpenClients,
  });

  final UserProfileData profile;
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
                                CupertinoIcons.checkmark_rectangle_fill,
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
                                    'Advokat Yordamchisi Vazifalari',
                                    style: TextStyle(
                                      color: YanColors.primaryNavy,
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'Biriktirilgan advokat: ${profile.assignedLawyerName}',
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
                                value: 'Mijozlar',
                                label: 'Ro‘yxatni ochish',
                                onTap: onOpenClients,
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
// Login Page Clean Input Fields & Monochromatic Solid Buttons
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
              Icon(widget.icon, size: 16, color: fgColor),
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
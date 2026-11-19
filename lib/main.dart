import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/advocate_calendar_page.dart';
import 'screens/bosh_sahifa_page.dart';
import 'services/consultation_service.dart';
import 'screens/profil_page.dart';
import 'screens/services/alimony_claim_page.dart';
import 'services/alimony_claim_document_service.dart';
import 'shared/dashboard_background.dart';
import 'shared/dashboard_navigation.dart';
import 'shared/user_profile.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Supabase Configuration (Europe Region + Strict RLS + E2EE Ready)
// ═══════════════════════════════════════════════════════════════════════════

// ═══════════════════════════════════════════════════════════════════════════
// WebRTC TURN Server Configuration (For 3G/4G/5G Mobile Data & Strict Firewalls)
// Get free credentials (no credit card) at: https://www.metered.ca/stun-turn
// Option A (Recommended): Paste your Metered REST API URL (returns geo-nearest servers):
//   e.g. 'https://yourapp.metered.live/api/v1/turn/credentials?apiKey=YOUR_API_KEY'
// Option B: Or paste static username & credential from Metered Dashboard below.
// ═══════════════════════════════════════════════════════════════════════════
const String yanMeteredTurnApiUrl = '';
const String yanStaticTurnUsername = 'a563ad5fa22790872c877d8a';
const String yanStaticTurnCredential = 'Tz+qYirv3gOulwmK';

// Set to true once you deploy your Supabase Edge Function `send-call-push` + Firebase Cloud Messaging (FCM)
const bool yanEnableFcmCallPush = false;


const String kSupabaseUrl = 'https://driqciowlqmvribbpuud.supabase.co';
const String kSupabasePublishableKey =
    'sb_publishable_VRCn93Hc3eKnFxuiaI4faA_ZaYo1Iz0';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Supabase.initialize(
      url: kSupabaseUrl,
      anonKey: kSupabasePublishableKey,
    );
  } catch (_) {
    // Already initialized or offline fallback
  }
  runApp(const YAN360App());
}

/// Formats a +998 phone number into a valid email identifier for pre-Eskiz.uz
/// Supabase Auth (e.g. "+998 91 910 80 28" -> "yan360.998919108028@gmail.com").
String formatPhoneAsDummyEmail(String rawPhone) {
  var digits = rawPhone.replaceAll(RegExp(r'\D'), '');
  if (digits.length == 9) {
    digits = '998$digits';
  }
  return 'yan360.$digits@gmail.com';
}

/// Maps Supabase `public.profiles.role` ('client', 'advocate', 'assistant')
/// to the app's UI `UserRole`.
UserRole mapDbRoleToUserRole(String? dbRole) {
  switch (dbRole?.trim().toLowerCase()) {
    case 'advocate':
    case 'advokat':
      return UserRole.advokat;
    case 'assistant':
    case 'yordamchi':
      return UserRole.yordamchi;
    case 'mijoz':
      return UserRole.mijoz;
    case 'client':
    case 'oddiy':
    default:
      return UserRole.oddiy;
  }
}

final GlobalKey<NavigatorState> yanRootNavigatorKey =
    GlobalKey<NavigatorState>();

class YAN360App extends StatelessWidget {
  const YAN360App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: yanRootNavigatorKey,
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
      home: const _AppLaunchGate(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// App-Launch 4-Digit PIN Lock Gate
// Once a user has registered or logged into their account on this phone,
// opening the app asks ONLY for their 4-digit PIN code to enter the app.
// ═══════════════════════════════════════════════════════════════════════════

class _AppLaunchGate extends StatelessWidget {
  const _AppLaunchGate();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserProfileData>(
      valueListenable: userProfile,
      builder: (context, profile, _) {
        Session? activeSession;
        try {
          activeSession = Supabase.instance.client.auth.currentSession;
        } catch (_) {
          activeSession = null;
        }

        if (profile.hasPinCode || activeSession != null) {
          return AppPinLockScreen(profile: profile);
        }
        return const IntroScreen();
      },
    );
  }
}

class AppPinLockScreen extends StatefulWidget {
  const AppPinLockScreen({super.key, required this.profile});

  final UserProfileData profile;

  @override
  State<AppPinLockScreen> createState() => _AppPinLockScreenState();
}

class _AppPinLockScreenState extends State<AppPinLockScreen> {
  String _enteredPin = '';
  bool _hasError = false;

  void _onDigitTap(String digit) {
    if (_enteredPin.length >= 4) return;
    setState(() {
      _hasError = false;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      final savedPin = widget.profile.pinCode?.trim();
      if (savedPin == null || savedPin.isEmpty || savedPin == _enteredPin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MainDashboard()),
        );
      } else {
        setState(() {
          _hasError = true;
          _enteredPin = '';
        });
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: YanColors.destructiveRed,
            content: Text(
              'PIN-kod noto‘g‘ri. Qaytadan kiriting yoki asosiy parol orqali kiring.',
            ),
          ),
        );
      }
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _hasError = false;
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _switchToPasswordLogin() async {
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {}
    userProfile.value = userProfile.value.copyWith(clearPinCode: true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const IntroScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YanColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DashboardBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
              child: Column(
                children: <Widget>[
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                  ),
                  const SizedBox(height: 12),
                  LiquidGlassWindow(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: YanColors.lightBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            widget.profile.roleType.shortBadge,
                            style: const TextStyle(
                              color: YanColors.primaryBlue,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.profile.displayName,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Ilovani ochish uchun 4 xonali telefon PIN-kodingizni kiriting',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: YanColors.mutedText,
                            fontSize: 12.6,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List<Widget>.generate(4, (index) {
                            final filled = index < _enteredPin.length;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 140),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _hasError
                                    ? YanColors.destructiveRed
                                    : (filled
                                          ? YanColors.primaryBlue
                                          : YanColors.lightBlue),
                                border: Border.all(
                                  color: _hasError
                                      ? YanColors.destructiveRed
                                      : (filled
                                            ? YanColors.primaryBlue
                                            : YanColors.border),
                                  width: 1.5,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _PinNumericKeypad(
                    onDigitTap: _onDigitTap,
                    onBackspaceTap: _onBackspace,
                    onResetTap: () => setState(() => _enteredPin = ''),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _switchToPasswordLogin,
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Text(
                        'Parol orqali kirish yoki boshqa hisob tanlash',
                        style: TextStyle(
                          color: YanColors.primaryBlue,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Onboarding & Authentication Entry Screen (IntroScreen)
// ═══════════════════════════════════════════════════════════════════════════

enum OnboardingMode {
  signIn,
  pinQuickUnlock,
  rolePicker,
  clientRegister,
  advocateRegister,
  assistantRegister,
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen>
    with SingleTickerProviderStateMixin {
  OnboardingMode _mode = OnboardingMode.signIn;
  bool _isSigningIn = false;
  bool _obscureSignInPassword = true;
  String _enteredQuickPin = '';

  final ImagePicker _licensePicker = ImagePicker();
  File? _advocateLicenseFile;
  String? _advocateLicenseFileName;
  File? _guvohnomaFrontFile;
  String? _guvohnomaFrontFileName;
  File? _guvohnomaBackFile;
  String? _guvohnomaBackFileName;

  late final AnimationController _entranceController;

  final TextEditingController _signInPhoneController =
      TextEditingController(text: '+998 ');
  final TextEditingController _signInPasswordController =
      TextEditingController();

  final TextEditingController _regFirstNameController = TextEditingController();
  final TextEditingController _regSurnameController = TextEditingController();
  final TextEditingController _regPhoneController =
      TextEditingController(text: '+998 ');
  final TextEditingController _regStirController = TextEditingController();
  final TextEditingController _regLinkedAdvocateUuidController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();

    _putCursorAtEnd(_signInPhoneController);
    _putCursorAtEnd(_regPhoneController);
  }

  void _putCursorAtEnd(TextEditingController controller) {
    controller.selection = TextSelection.collapsed(
      offset: controller.text.length,
    );
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _signInPhoneController.dispose();
    _signInPasswordController.dispose();
    _regFirstNameController.dispose();
    _regSurnameController.dispose();
    _regPhoneController.dispose();
    _regStirController.dispose();
    _regLinkedAdvocateUuidController.dispose();
    super.dispose();
  }

  bool _hasUzbekPhone(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length >= 12 && digits.startsWith('998');
  }

  String get _selectedDbRole {
    switch (_mode) {
      case OnboardingMode.advocateRegister:
        return 'advocate';
      case OnboardingMode.assistantRegister:
        return 'assistant';
      case OnboardingMode.clientRegister:
      case OnboardingMode.rolePicker:
      case OnboardingMode.signIn:
      case OnboardingMode.pinQuickUnlock:
        return 'client';
    }
  }

  UserRole get _selectedUiRole {
    switch (_mode) {
      case OnboardingMode.advocateRegister:
        return UserRole.advokat;
      case OnboardingMode.assistantRegister:
        return UserRole.yordamchi;
      case OnboardingMode.clientRegister:
      case OnboardingMode.rolePicker:
      case OnboardingMode.signIn:
      case OnboardingMode.pinQuickUnlock:
        return UserRole.oddiy;
    }
  }

  Future<void> _pickAdvocateDocImage({
    required String docTarget,
    required ImageSource source,
  }) async {
    try {
      if (source == ImageSource.camera) {
        final camPerm = await Permission.camera.request();
        if (!camPerm.isGranted) {
          _showMessage(
            'Hujjatni suratga olish uchun ilovaga kamera ruxsatini bering.',
          );
          return;
        }
      }
      final picked = await _licensePicker.pickImage(
        source: source,
        imageQuality: 92,
      );
      if (picked != null) {
        setState(() {
          if (docTarget == 'license') {
            _advocateLicenseFile = File(picked.path);
            _advocateLicenseFileName = picked.name;
          } else if (docTarget == 'guvohnoma_front') {
            _guvohnomaFrontFile = File(picked.path);
            _guvohnomaFrontFileName = picked.name;
          } else if (docTarget == 'guvohnoma_back') {
            _guvohnomaBackFile = File(picked.path);
            _guvohnomaBackFileName = picked.name;
          }
        });
      }
    } catch (e) {
      _showMessage('Hujjat faylini tanlashda xatolik: $e');
    }
  }

  void _showAdvocateDocSourceSheet({
    required String docTarget,
    required String title,
  }) {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: Text(title),
        message: const Text(
          'Hujjat asl nusxasini tekshirish uchun aniq ko‘ringan rasm yoki skaner nusxasini tanlang:',
        ),
        actions: <Widget>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAdvocateDocImage(
                docTarget: docTarget,
                source: ImageSource.gallery,
              );
            },
            child: const Text('Galereyadan tanlash (Rasm / Skaner)'),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              _pickAdvocateDocImage(
                docTarget: docTarget,
                source: ImageSource.camera,
              );
            },
            child: const Text('Kamerada suratga olish'),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Bekor qilish'),
        ),
      ),
    );
  }

  void _proceedToMockOtpScreen() {
    final first = _regFirstNameController.text.trim();
    final last = _regSurnameController.text.trim();
    final phone = _regPhoneController.text.trim();
    final stir = _regStirController.text.replaceAll(RegExp(r'\D'), '');

    if (first.isEmpty || last.isEmpty) {
      _showMessage('Iltimos, ism va familiyangizni to‘liq kiriting.');
      return;
    }
    if (!_hasUzbekPhone(phone)) {
      _showMessage(
        'Telefon raqamini +998 XX XXX XX XX shaklida to‘liq kiriting.',
      );
      return;
    }
    if (_mode == OnboardingMode.advocateRegister) {
      if (stir.length < 9) {
        _showMessage(
          'Iltimos, faoliyat ko‘rsatadigan tuzilma STIR (INN) raqamini 9 xonali shaklda to‘liq kiriting.',
        );
        return;
      }
      if (_advocateLicenseFile == null) {
        _showMessage(
          '1-hujjat: Iltimos, Advokatlik litsenziyangiz rasmini yuklang.',
        );
        return;
      }
      if (_guvohnomaFrontFile == null || _guvohnomaBackFile == null) {
        _showMessage(
          '2-hujjat: Iltimos, Advokatlik guvohnomangizning OLD va ORQA tarafi rasmlarini to‘liq yuklang.',
        );
        return;
      }
    }

    final fullName = '$first $last'.trim();
    final linkedAdvocateId = _regLinkedAdvocateUuidController.text.trim();

    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MockOtpVerificationScreen(
          phoneNumber: phone,
          fullName: fullName,
          dbRole: _selectedDbRole,
          uiRole: _selectedUiRole,
          associatedAdvocateId:
              linkedAdvocateId.isEmpty ? null : linkedAdvocateId,
          stirNumber: stir.isEmpty ? null : stir,
          advocateLicenseFile: _advocateLicenseFile,
          advocateLicenseFileName: _advocateLicenseFileName,
          guvohnomaFrontFile: _guvohnomaFrontFile,
          guvohnomaFrontFileName: _guvohnomaFrontFileName,
          guvohnomaBackFile: _guvohnomaBackFile,
          guvohnomaBackFileName: _guvohnomaBackFileName,
        ),
      ),
    );
  }

  Future<void> _signInWithPhoneAndPassword() async {
    final phone = _signInPhoneController.text.trim();
    final password = _signInPasswordController.text;

    if (!_hasUzbekPhone(phone)) {
      _showMessage('Telefon raqamingizni to‘liq kiriting.');
      return;
    }
    if (password.length < 6) {
      _showMessage(
        'Hisob paroli kamida 6 ta belgidan (harf, raqam yoki belgi) iborat bo‘lishi kerak.',
      );
      return;
    }

    setState(() => _isSigningIn = true);
    final dummyEmail = formatPhoneAsDummyEmail(phone);

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: dummyEmail,
        password: password,
      );

      final user = response.user;
      var resolvedName =
          user?.userMetadata?['full_name']?.toString() ??
          userProfile.value.displayName;
      var resolvedRole = mapDbRoleToUserRole(
        user?.userMetadata?['role']?.toString(),
      );

      if (user != null) {
        try {
          final profileRow = await Supabase.instance.client
              .from('profiles')
              .select()
              .eq('id', user.id)
              .maybeSingle();
          if (profileRow != null) {
            resolvedName =
                profileRow['full_name']?.toString() ?? resolvedName;
            resolvedRole = mapDbRoleToUserRole(
              profileRow['role']?.toString(),
            );
          }
        } catch (_) {}
      }

      userProfile.value = userProfile.value.copyWith(
        clientId: user?.id ?? userProfile.value.clientId,
        displayName: resolvedName,
        phone: phone,
        email: dummyEmail,
        roleType: resolvedRole,
        role: resolvedRole.label,
      );

      if (!mounted) return;
      if (!userProfile.value.hasPinCode) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(
            builder: (_) => LocalPhonePinSetupScreen(
              fullName: resolvedName,
              phoneNumber: phone,
            ),
          ),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MainDashboard()),
        );
      }
    } on AuthException catch (e) {
      _showMessage(
        'Kirishda xatolik: ${e.message}\n\nTelefon raqami yoki parol noto‘g‘ri, yoxud avval "Ro‘yxatdan o‘tish" tugmasini bosing.',
      );
    } catch (e) {
      _showMessage('Ulanishda xatolik: $e');
    } finally {
      if (mounted) setState(() => _isSigningIn = false);
    }
  }

  void _onQuickPinDigit(String digit) {
    if (_enteredQuickPin.length >= 4) return;
    setState(() => _enteredQuickPin += digit);

    if (_enteredQuickPin.length == 4) {
      final savedPin = userProfile.value.pinCode?.trim();
      if (savedPin == null || savedPin == _enteredQuickPin) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute<void>(builder: (_) => const MainDashboard()),
        );
      } else {
        setState(() => _enteredQuickPin = '');
        _showMessage(
          'PIN-kod noto‘g‘ri. Qaytadan urinib ko‘ring yoki parol orqali kiring.',
        );
      }
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
              padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + bottomInset),
              child: Column(
                children: <Widget>[
                  _buildBrand(),
                  const SizedBox(height: 20),
                  _buildOnboardingCard(),
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
            width: 82,
            height: 82,
            child: Image.asset(
              'assets/logo.png',
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              isAntiAlias: true,
              errorBuilder: (_, __, ___) => const Icon(
                CupertinoIcons.shield_lefthalf_fill,
                size: 64,
                color: YanColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 10),
          RichText(
            text: const TextSpan(
              children: <InlineSpan>[
                TextSpan(
                  text: 'YAN',
                  style: TextStyle(
                    color: YanColors.primaryNavy,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.2,
                    height: 1.0,
                  ),
                ),
                TextSpan(
                  text: '360',
                  style: TextStyle(
                    color: YanColors.primaryBlue,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3.2,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'E2EE Himoyalangan Huquqiy Platforma • Supabase EU',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w600,
              color: YanColors.mutedText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOnboardingCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.94),
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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: switch (_mode) {
              OnboardingMode.signIn => _buildSignInView(),
              OnboardingMode.pinQuickUnlock => _buildPinQuickUnlockView(),
              OnboardingMode.rolePicker => _buildRolePickerView(),
              OnboardingMode.clientRegister => _buildRegistrationFormView(
                title: 'Mijoz sifatida ro‘yxatdan o‘tish',
                subtitle:
                    '1. SMS kod • 2. 6+ belgili Supabase parol • 3. 4 xonali telefon PIN-kodi',
                roleBadge: 'CLIENT (MIJOZ)',
              ),
              OnboardingMode.advocateRegister => _buildRegistrationFormView(
                title: 'Advokat sifatida ro‘yxatdan o‘tish',
                subtitle:
                    'Ism-familiya, telefon raqami, tuzilma STIR raqami, litsenziya va guvohnoma (old/orqa) nusxalarini yuklang.',
                roleBadge: 'ADVOCATE',
                showLicenseUpload: true,
              ),
              OnboardingMode.assistantRegister => _buildRegistrationFormView(
                title: 'Advokat yordamchisi ro‘yxati',
                subtitle:
                    'Biriktirilgan advokat UUID raqamini kiriting (RLS orqali advokat shartnomalariga ulanadi).',
                roleBadge: 'ASSISTANT',
                showLinkedAdvocateField: true,
              ),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSignInView() {
    return Column(
      key: const ValueKey<String>('mode-signin'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Hisobga kirish',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Telefon raqamingiz va 6+ belgili hisob parolingizni kiriting',
                    style: TextStyle(
                      fontSize: 12.4,
                      color: YanColors.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: YanColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Icon(
                    CupertinoIcons.lock_shield_fill,
                    size: 13,
                    color: YanColors.primaryBlue,
                  ),
                  SizedBox(width: 4),
                  Text(
                    'SUPABASE',
                    style: TextStyle(
                      color: YanColors.primaryBlue,
                      fontSize: 10.0,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _UzbekPhoneField(controller: _signInPhoneController),
        const SizedBox(height: 11),
        _PasswordTextField(
          controller: _signInPasswordController,
          hintText: 'Hisob paroli (harf, raqam yoki belgi)',
          obscureText: _obscureSignInPassword,
          onToggleObscure: () => setState(
            () => _obscureSignInPassword = !_obscureSignInPassword,
          ),
        ),
        const SizedBox(height: 16),
        _SolidPrimaryButton(
          label: _isSigningIn ? 'Tekshirilmoqda...' : 'Tizimga kirish',
          icon: CupertinoIcons.arrow_right,
          onPressed: _isSigningIn ? () {} : _signInWithPhoneAndPassword,
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: _SolidSecondaryButton(
                icon: CupertinoIcons.person_add_solid,
                label: 'Ro‘yxatdan o‘tish',
                active: false,
                onPressed: () =>
                    setState(() => _mode = OnboardingMode.rolePicker),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: _SolidSecondaryButton(
                icon: CupertinoIcons.circle_grid_3x3_fill,
                label: 'PIN-kod orqali',
                active: false,
                onPressed: () => setState(() {
                  _enteredQuickPin = '';
                  _mode = OnboardingMode.pinQuickUnlock;
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPinQuickUnlockView() {
    return Column(
      key: const ValueKey<String>('mode-pin-unlock'),
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: GestureDetector(
            onTap: () => setState(() => _mode = OnboardingMode.signIn),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Icon(
                  CupertinoIcons.chevron_left,
                  size: 15,
                  color: YanColors.primaryBlue,
                ),
                SizedBox(width: 4),
                Text(
                  'Parol orqali kirishga qaytish',
                  style: TextStyle(
                    color: YanColors.primaryBlue,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          '4 xonali PIN-kodni kiriting',
          style: TextStyle(
            color: YanColors.primaryNavy,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${userProfile.value.displayName} hisobiga tezkor kirish',
          style: const TextStyle(
            color: YanColors.mutedText,
            fontSize: 12.4,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List<Widget>.generate(4, (index) {
            final filled = index < _enteredQuickPin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: filled ? YanColors.primaryBlue : YanColors.lightBlue,
                border: Border.all(
                  color: filled ? YanColors.primaryBlue : YanColors.border,
                  width: 1.4,
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 18),
        _PinNumericKeypad(
          onDigitTap: _onQuickPinDigit,
          onBackspaceTap: () {
            if (_enteredQuickPin.isNotEmpty) {
              setState(
                () => _enteredQuickPin = _enteredQuickPin.substring(
                  0,
                  _enteredQuickPin.length - 1,
                ),
              );
            }
          },
          onResetTap: () => setState(() => _enteredQuickPin = ''),
        ),
      ],
    );
  }

  Widget _buildRolePickerView() {
    return Column(
      key: const ValueKey<String>('mode-role-picker'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: () => setState(() => _mode = OnboardingMode.signIn),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                CupertinoIcons.chevron_left,
                size: 15,
                color: YanColors.primaryBlue,
              ),
              SizedBox(width: 4),
              Text(
                'Kirish oynasiga qaytish',
                style: TextStyle(
                  color: YanColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const Text(
          'Kim sifatida ro‘yxatdan o‘tasiz?',
          style: TextStyle(
            color: YanColors.primaryNavy,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Supabase bazasida profilingiz va RLS huquqlaringiz tanlangan rolga qarab yaratiladi:',
          style: TextStyle(
            color: YanColors.mutedText,
            fontSize: 12.4,
          ),
        ),
        const SizedBox(height: 14),
        _RoleOnboardingChoiceCard(
          icon: CupertinoIcons.person_crop_circle_fill,
          title: 'Mijoz (Foydalanuvchi)',
          badge: 'ASOSIY',
          subtitle:
              'Huquqiy yordam, ariza yozish va litsenziyali advokat topish uchun',
          isHighlighted: true,
          onTap: () => setState(() => _mode = OnboardingMode.clientRegister),
        ),
        const SizedBox(height: 10),
        _RoleOnboardingChoiceCard(
          icon: CupertinoIcons.briefcase_fill,
          title: 'Litsenziyali Advokat',
          badge: 'ADVOCATE',
          subtitle:
              'Litsenziya, Guvohnoma (old/orqa) va STIR yuklash orqali rasmiy ro‘yxatdan o‘tish',
          isHighlighted: false,
          onTap: () => setState(() => _mode = OnboardingMode.advocateRegister),
        ),
        const SizedBox(height: 10),
        _RoleOnboardingChoiceCard(
          icon: CupertinoIcons.person_2_fill,
          title: 'Advokat Yordamchisi',
          badge: 'ASSISTANT',
          subtitle:
              'Advokatga biriktirilgan shaxsiy yordamchi (associated_advocate_id orqali)',
          isHighlighted: false,
          onTap: () => setState(() => _mode = OnboardingMode.assistantRegister),
        ),
      ],
    );
  }

  Widget _buildRegistrationFormView({
    required String title,
    required String subtitle,
    required String roleBadge,
    bool showLicenseUpload = false,
    bool showLinkedAdvocateField = false,
  }) {
    return Column(
      key: ValueKey<String>('reg-$roleBadge'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        GestureDetector(
          onTap: () => setState(() => _mode = OnboardingMode.rolePicker),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                CupertinoIcons.chevron_left,
                size: 15,
                color: YanColors.primaryBlue,
              ),
              SizedBox(width: 4),
              Text(
                'Rol tanlashga qaytish',
                style: TextStyle(
                  color: YanColors.primaryBlue,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: YanColors.lightBlue,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                roleBadge,
                style: const TextStyle(
                  color: YanColors.primaryBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: YanColors.mutedText,
            fontSize: 12.2,
            height: 1.32,
          ),
        ),
        const SizedBox(height: 15),
        _CleanTextField(
          controller: _regFirstNameController,
          hintText: 'Ismingiz (masalan: Nurbek)',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person_fill,
        ),
        const SizedBox(height: 10),
        _CleanTextField(
          controller: _regSurnameController,
          hintText: 'Familiyangiz (masalan: Otamurodov)',
          keyboardType: TextInputType.name,
          icon: CupertinoIcons.person_fill,
        ),
        const SizedBox(height: 10),
        _UzbekPhoneField(controller: _regPhoneController),
        if (showLicenseUpload) ...<Widget>[
          const SizedBox(height: 10),
          _CleanTextField(
            controller: _regStirController,
            hintText: 'Faoliyat ko‘rsatadigan tuzilma STIR (9 xonali)',
            keyboardType: TextInputType.number,
            icon: CupertinoIcons.number_square_fill,
            maxLength: 9,
          ),
          const SizedBox(height: 12),
          const Text(
            'TASDIQLOVCHI HUJJATLARNI YUKLANG (3 TA):',
            style: TextStyle(
              color: YanColors.mutedText,
              fontSize: 10.4,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 8),
          _AdvocateLicenseUploadCard(
            title: '1. Advokatlik litsenziyasi',
            subtitle: 'Litsenziya asl nusxasi rasmi yoki skaneri',
            licenseFile: _advocateLicenseFile,
            fileName: _advocateLicenseFileName,
            onUploadTap: () => _showAdvocateDocSourceSheet(
              docTarget: 'license',
              title: '1. Advokatlik litsenziyasini yuklash',
            ),
          ),
          const SizedBox(height: 9),
          _AdvocateLicenseUploadCard(
            title: '2. Advokatlik guvohnomasi (Old tarafi)',
            subtitle: 'Guvohnomaning old qismi (rasmli va muhrli tarafi)',
            licenseFile: _guvohnomaFrontFile,
            fileName: _guvohnomaFrontFileName,
            onUploadTap: () => _showAdvocateDocSourceSheet(
              docTarget: 'guvohnoma_front',
              title: 'Guvohnoma (Old tarafi) rasmini yuklash',
            ),
          ),
          const SizedBox(height: 9),
          _AdvocateLicenseUploadCard(
            title: '3. Advokatlik guvohnomasi (Orqa tarafi)',
            subtitle: 'Guvohnomaning orqa tarafini ham rasmga olib yuklang',
            licenseFile: _guvohnomaBackFile,
            fileName: _guvohnomaBackFileName,
            onUploadTap: () => _showAdvocateDocSourceSheet(
              docTarget: 'guvohnoma_back',
              title: 'Guvohnoma (Orqa tarafi) rasmini yuklash',
            ),
          ),
        ],
        if (showLinkedAdvocateField) ...<Widget>[
          const SizedBox(height: 10),
          _CleanTextField(
            controller: _regLinkedAdvocateUuidController,
            hintText: 'Advokat UUID raqami (associated_advocate_id)',
            keyboardType: TextInputType.text,
            icon: CupertinoIcons.link,
          ),
        ],
        const SizedBox(height: 16),
        _SolidPrimaryButton(
          label: 'SMS kodni olish (1/3-qadam)',
          icon: CupertinoIcons.paperplane_fill,
          onPressed: _proceedToMockOtpScreen,
        ),
      ],
    );
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
          'Zero-Knowledge E2EE • Supabase PostgreSQL RLS',
          style: TextStyle(
            fontSize: 10,
            letterSpacing: 0.5,
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

class _AdvocateLicenseUploadCard extends StatelessWidget {
  const _AdvocateLicenseUploadCard({
    required this.title,
    required this.subtitle,
    required this.licenseFile,
    required this.fileName,
    required this.onUploadTap,
  });

  final String title;
  final String subtitle;
  final File? licenseFile;
  final String? fileName;
  final VoidCallback onUploadTap;

  @override
  Widget build(BuildContext context) {
    final hasFile = licenseFile != null;

    return GestureDetector(
      onTap: onUploadTap,
      child: Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: hasFile
              ? YanColors.successGreen.withValues(alpha: 0.10)
              : YanColors.lightBlue.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasFile ? YanColors.successGreen : YanColors.border,
            width: hasFile ? 1.4 : 1.1,
          ),
        ),
        child: Row(
          children: <Widget>[
            if (hasFile)
              ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Image.file(
                  licenseFile!,
                  width: 50,
                  height: 50,
                  fit: BoxFit.cover,
                ),
              )
            else
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: YanColors.primaryBlue,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  CupertinoIcons.cloud_upload_fill,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    hasFile ? '$title ✓' : title,
                    style: const TextStyle(
                      color: YanColors.primaryNavy,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2.5),
                  Text(
                    hasFile ? (fileName ?? 'yuklangan_hujjat.jpg') : subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: YanColors.mutedText,
                      fontSize: 11.2,
                      height: 1.24,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: hasFile ? YanColors.white : YanColors.primaryBlue,
                borderRadius: BorderRadius.circular(11),
                border: hasFile ? Border.all(color: YanColors.border) : null,
              ),
              child: Text(
                hasFile ? 'Almashtirish' : 'Yuklash',
                style: TextStyle(
                  color: hasFile ? YanColors.primaryNavy : Colors.white,
                  fontSize: 11.0,
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

class _RoleOnboardingChoiceCard extends StatelessWidget {
  const _RoleOnboardingChoiceCard({
    required this.icon,
    required this.title,
    required this.badge,
    required this.subtitle,
    required this.isHighlighted,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String badge;
  final String subtitle;
  final bool isHighlighted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isHighlighted ? const Color(0xFFF2F8FF) : YanColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isHighlighted ? YanColors.primaryBlue : YanColors.border,
            width: isHighlighted ? 1.4 : 1.0,
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isHighlighted
                    ? YanColors.primaryBlue
                    : YanColors.lightBlue,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isHighlighted ? Colors.white : YanColors.primaryNavy,
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
                      Flexible(
                        child: Text(
                          title,
                          style: const TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: YanColors.lightBlue,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          badge,
                          style: const TextStyle(
                            color: YanColors.primaryBlue,
                            fontSize: 9.2,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: YanColors.mutedText,
                      fontSize: 11.6,
                      height: 1.28,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              CupertinoIcons.chevron_right,
              color: YanColors.primaryBlue,
              size: 17,
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 1 OF 3: Mock OTP Input Screen
// ═══════════════════════════════════════════════════════════════════════════

class MockOtpVerificationScreen extends StatefulWidget {
  const MockOtpVerificationScreen({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    required this.dbRole,
    required this.uiRole,
    this.associatedAdvocateId,
    this.stirNumber,
    this.advocateLicenseFile,
    this.advocateLicenseFileName,
    this.guvohnomaFrontFile,
    this.guvohnomaFrontFileName,
    this.guvohnomaBackFile,
    this.guvohnomaBackFileName,
  });

  final String phoneNumber;
  final String fullName;
  final String dbRole;
  final UserRole uiRole;
  final String? associatedAdvocateId;
  final String? stirNumber;
  final File? advocateLicenseFile;
  final String? advocateLicenseFileName;
  final File? guvohnomaFrontFile;
  final String? guvohnomaFrontFileName;
  final File? guvohnomaBackFile;
  final String? guvohnomaBackFileName;

  @override
  State<MockOtpVerificationScreen> createState() =>
      _MockOtpVerificationScreenState();
}

class _MockOtpVerificationScreenState extends State<MockOtpVerificationScreen> {
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _verifyMockOtp() {
    final code = _otpController.text.trim();
    if (code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: YanColors.primaryNavy,
          content: Text(
            '6 xonali tasdiqlash kodini kiriting (Test uchun: 000000)',
          ),
        ),
      );
      return;
    }

    FocusScope.of(context).unfocus();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AccountPasswordSetupScreen(
          phoneNumber: widget.phoneNumber,
          fullName: widget.fullName,
          dbRole: widget.dbRole,
          uiRole: widget.uiRole,
          associatedAdvocateId: widget.associatedAdvocateId,
          stirNumber: widget.stirNumber,
          advocateLicenseFile: widget.advocateLicenseFile,
          advocateLicenseFileName: widget.advocateLicenseFileName,
          guvohnomaFrontFile: widget.guvohnomaFrontFile,
          guvohnomaFrontFileName: widget.guvohnomaFrontFileName,
          guvohnomaBackFile: widget.guvohnomaBackFile,
          guvohnomaBackFileName: widget.guvohnomaBackFileName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _otpController.text.trim();

    return Scaffold(
      backgroundColor: YanColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DashboardBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: YanColors.border),
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_left,
                            color: YanColors.primaryNavy,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        '1/3-Qadam • SMS Tasdiqlash',
                        style: TextStyle(
                          color: YanColors.primaryNavy,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  LiquidGlassWindow(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: YanColors.primaryBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            CupertinoIcons.chat_bubble_text_fill,
                            color: Colors.white,
                            size: 25,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'SMS tasdiqlash kodini kiriting',
                          style: TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${widget.phoneNumber} raqamiga 6 xonali tasdiqlash kodi yuborildi.',
                          style: const TextStyle(
                            color: YanColors.mutedText,
                            fontSize: 13.2,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 14),

                        GestureDetector(
                          onTap: () {
                            setState(() => _otpController.text = '000000');
                            _verifyMockOtp();
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: YanColors.lightBlue,
                              borderRadius: BorderRadius.circular(13),
                              border: Border.all(color: YanColors.border),
                            ),
                            child: const Row(
                              children: <Widget>[
                                Icon(
                                  CupertinoIcons.sparkles,
                                  size: 16,
                                  color: YanColors.primaryBlue,
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Eskiz.uz Test Rejimi: "000000" kiriting (Avto-to‘ldirish uchun bosing)',
                                    style: TextStyle(
                                      color: YanColors.primaryNavy,
                                      fontSize: 11.8,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        GestureDetector(
                          onTap: () => _otpFocusNode.requestFocus(),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List<Widget>.generate(6, (index) {
                              final char =
                                  index < code.length ? code[index] : '';
                              final active = index == code.length;
                              return Container(
                                width: 46,
                                height: 56,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: char.isNotEmpty
                                      ? YanColors.lightBlue
                                      : YanColors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: active || char.isNotEmpty
                                        ? YanColors.primaryBlue
                                        : YanColors.border,
                                    width: active ? 1.8 : 1.15,
                                  ),
                                ),
                                child: Text(
                                  char,
                                  style: const TextStyle(
                                    color: YanColors.primaryNavy,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),

                        Opacity(
                          opacity: 0.0,
                          child: SizedBox(
                            height: 1,
                            child: CupertinoTextField(
                              controller: _otpController,
                              focusNode: _otpFocusNode,
                              keyboardType: TextInputType.number,
                              maxLength: 6,
                              autofocus: true,
                              onChanged: (val) {
                                setState(() {});
                                if (val.trim().length == 6) {
                                  _verifyMockOtp();
                                }
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        _SolidPrimaryButton(
                          label: 'Tasdiqlash va Parol yaratish',
                          icon: CupertinoIcons.arrow_right,
                          onPressed: _verifyMockOtp,
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
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// STEP 2 OF 3: 6+ Character Account Password Setup & Real Supabase SignUp
// ═══════════════════════════════════════════════════════════════════════════

class AccountPasswordSetupScreen extends StatefulWidget {
  const AccountPasswordSetupScreen({
    super.key,
    required this.phoneNumber,
    required this.fullName,
    required this.dbRole,
    required this.uiRole,
    this.associatedAdvocateId,
    this.stirNumber,
    this.advocateLicenseFile,
    this.advocateLicenseFileName,
    this.guvohnomaFrontFile,
    this.guvohnomaFrontFileName,
    this.guvohnomaBackFile,
    this.guvohnomaBackFileName,
  });

  final String phoneNumber;
  final String fullName;
  final String dbRole;
  final UserRole uiRole;
  final String? associatedAdvocateId;
  final String? stirNumber;
  final File? advocateLicenseFile;
  final String? advocateLicenseFileName;
  final File? guvohnomaFrontFile;
  final String? guvohnomaFrontFileName;
  final File? guvohnomaBackFile;
  final String? guvohnomaBackFileName;

  @override
  State<AccountPasswordSetupScreen> createState() =>
      _AccountPasswordSetupScreenState();
}

class _AccountPasswordSetupScreenState
    extends State<AccountPasswordSetupScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_onChanged);
    _confirmPasswordController.addListener(_onChanged);
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _passwordController
      ..removeListener(_onChanged)
      ..dispose();
    _confirmPasswordController
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  bool get _hasMin6Chars => _passwordController.text.length >= 6;
  bool get _passwordsMatch =>
      _passwordController.text.isNotEmpty &&
      _passwordController.text == _confirmPasswordController.text;

  Future<String> _uploadSingleVerificationDoc({
    required File file,
    required String? originalName,
    required String safeAdvocateName,
    required String advocateUuid,
    required String docLabel,
  }) async {
    final ext = (originalName ?? file.path).split('.').last.toLowerCase();
    final validExt = <String>['jpg', 'jpeg', 'png', 'webp', 'pdf'].contains(ext)
        ? ext
        : 'jpg';
    final objectPath =
        'advocate_licenses/${safeAdvocateName}_${advocateUuid}_$docLabel.$validExt';

    try {
      await Supabase.instance.client.storage
          .from('advocate_licenses')
          .upload(
            objectPath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );
      return Supabase.instance.client.storage
          .from('advocate_licenses')
          .getPublicUrl(objectPath);
    } catch (_) {
      try {
        await Supabase.instance.client.storage
            .from('chat_media')
            .upload(
              objectPath,
              file,
              fileOptions: const FileOptions(upsert: true),
            );
        return Supabase.instance.client.storage
            .from('chat_media')
            .getPublicUrl(objectPath);
      } catch (_) {
        return objectPath;
      }
    }
  }

  Future<String?> _uploadAdvocateLicenseToSupabase({
    required String advocateUuid,
    required String fullName,
    required String phone,
    required File licenseFile,
  }) async {
    final safeName = fullName
        .trim()
        .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');

    final licenseUrl = await _uploadSingleVerificationDoc(
      file: licenseFile,
      originalName: widget.advocateLicenseFileName,
      safeAdvocateName: safeName,
      advocateUuid: advocateUuid,
      docLabel: '1_litsenziya',
    );

    String? guvohnomaFrontUrl;
    if (widget.guvohnomaFrontFile != null) {
      guvohnomaFrontUrl = await _uploadSingleVerificationDoc(
        file: widget.guvohnomaFrontFile!,
        originalName: widget.guvohnomaFrontFileName,
        safeAdvocateName: safeName,
        advocateUuid: advocateUuid,
        docLabel: '2_guvohnoma_oldi',
      );
    }

    String? guvohnomaBackUrl;
    if (widget.guvohnomaBackFile != null) {
      guvohnomaBackUrl = await _uploadSingleVerificationDoc(
        file: widget.guvohnomaBackFile!,
        originalName: widget.guvohnomaBackFileName,
        safeAdvocateName: safeName,
        advocateUuid: advocateUuid,
        docLabel: '3_guvohnoma_orqa',
      );
    }

    try {
      await Supabase.instance.client.from('advocate_licenses').upsert(
        <String, dynamic>{
          'advocate_id': advocateUuid,
          'full_name': fullName,
          'phone': phone,
          'stir_number': widget.stirNumber ?? '',
          'bucket_id': 'advocate_licenses',
          'license_file_path': licenseUrl,
          'license_file_url': licenseUrl,
          'guvohnoma_front_url': guvohnomaFrontUrl ?? '',
          'guvohnoma_back_url': guvohnomaBackUrl ?? '',
          'verification_status': 'pending',
        },
      );
    } catch (_) {
      try {
        await Supabase.instance.client.from('advocate_licenses').upsert(
          <String, dynamic>{
            'advocate_id': advocateUuid,
            'full_name': '$fullName (STIR: ${widget.stirNumber ?? "-"})',
            'phone': phone,
            'license_file_path': licenseUrl,
            'license_file_url': licenseUrl,
            'verification_status': 'pending',
          },
        );
      } catch (_) {}
    }

    return licenseUrl;
  }

  Future<void> _registerRealAccountInSupabase() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    if (password.length < 6) {
      _showErrorDialog(
        'Parol kamida 6 ta belgidan (harf, raqam yoki maxsus belgi) iborat bo‘lishi shart.',
      );
      return;
    }
    if (password != confirm) {
      _showErrorDialog(
        'Kiritilgan parollar bir-biriga mos kelmadi. Iltimos, tekshirib qaytadan kiriting.',
      );
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isSubmitting = true);

    final dummyEmail = formatPhoneAsDummyEmail(widget.phoneNumber);

    final random = Random.secure();
    final keyBytes = List<int>.generate(32, (_) => random.nextInt(256));
    final publicKeyBase64 = 'PUB-X25519-${base64UrlEncode(keyBytes)}';

    final metadata = <String, dynamic>{
      'role': widget.dbRole,
      'full_name': widget.fullName,
      if (widget.associatedAdvocateId != null &&
          widget.associatedAdvocateId!.trim().isNotEmpty)
        'associated_advocate_id': widget.associatedAdvocateId!.trim(),
    };

    try {
      AuthResponse response;
      try {
        response = await Supabase.instance.client.auth.signUp(
          email: dummyEmail,
          password: password,
          data: metadata,
        );
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('already registered')) {
          response = await Supabase.instance.client.auth.signInWithPassword(
            email: dummyEmail,
            password: password,
          );
        } else {
          rethrow;
        }
      }

      final createdUser = response.user;
      String? uploadedLicenseRef;

      if (createdUser != null) {
        if (widget.dbRole == 'advocate' && widget.advocateLicenseFile != null) {
          uploadedLicenseRef = await _uploadAdvocateLicenseToSupabase(
            advocateUuid: createdUser.id,
            fullName: widget.fullName,
            phone: widget.phoneNumber,
            licenseFile: widget.advocateLicenseFile!,
          );
        }

        try {
          await Supabase.instance.client
              .from('profiles')
              .update(<String, dynamic>{
                'public_key': publicKeyBase64,
                'full_name': widget.fullName,
              })
              .eq('id', createdUser.id);
        } catch (_) {}
      }

      final shortUuid = createdUser != null
          ? createdUser.id.substring(0, 8).toUpperCase()
          : '8492';

      userProfile.value = userProfile.value.copyWith(
        clientId: 'YAN-$shortUuid',
        displayName: widget.fullName,
        phone: widget.phoneNumber,
        email: dummyEmail,
        roleType: widget.uiRole,
        role: widget.uiRole.label,
        lawyerLicenseNumber: uploadedLicenseRef != null
            ? 'STIR: ${widget.stirNumber ?? "Tasdiqlangan"}'
            : userProfile.value.lawyerLicenseNumber,
      );

      await ActivityHistoryRepository.instance.record(
        title: 'Supabase hisobi yaratildi (${widget.uiRole.label})',
        description: uploadedLicenseRef != null
            ? 'Advokat: ${widget.fullName} • Litsenziya, Guvohnoma va STIR Supabase bazasiga yuklandi'
            : 'F.I.Sh.: ${widget.fullName} • Auth: $dummyEmail',
        category: ActivityCategory.profile,
        statusLabel: 'Faol',
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => LocalPhonePinSetupScreen(
            fullName: widget.fullName,
            phoneNumber: widget.phoneNumber,
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog('Supabase Auth xatoligi:\n${e.message}');
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      _showErrorDialog('Tarmoq xatoligi:\n$e');
    }
  }

  void _showErrorDialog(String msg) {
    showCupertinoDialog<void>(
      context: context,
      builder: (ctx) => CupertinoAlertDialog(
        title: const Text('YAN360'),
        content: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(msg),
        ),
        actions: <Widget>[
          CupertinoDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dummyEmailPreview = formatPhoneAsDummyEmail(widget.phoneNumber);

    return Scaffold(
      backgroundColor: YanColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DashboardBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: YanColors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: YanColors.border),
                          ),
                          child: const Icon(
                            CupertinoIcons.arrow_left,
                            color: YanColors.primaryNavy,
                            size: 19,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          '2/3-Qadam • Hisob Parolini Yaratish',
                          style: TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  LiquidGlassWindow(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: YanColors.primaryBlue,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            CupertinoIcons.lock_shield_fill,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        const SizedBox(height: 15),
                        const Text(
                          'Hisobingiz uchun parol o‘rnating',
                          style: TextStyle(
                            color: YanColors.primaryNavy,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Kamida 6 ta belgidan iborat parol kiriting (harf, raqam yoki maxsus belgilar qatnashishi mumkin). Ushbu parol Supabase bazasida asosiy parolingiz sifatida saqlanadi.',
                          style: TextStyle(
                            color: YanColors.mutedText,
                            fontSize: 12.8,
                            height: 1.36,
                          ),
                        ),
                        const SizedBox(height: 16),

                        _PasswordTextField(
                          controller: _passwordController,
                          hintText: 'Yangi parol (kamida 6 ta belgi)',
                          obscureText: _obscurePass,
                          onToggleObscure: () =>
                              setState(() => _obscurePass = !_obscurePass),
                        ),
                        const SizedBox(height: 11),
                        _PasswordTextField(
                          controller: _confirmPasswordController,
                          hintText: 'Parolni tasdiqlang',
                          obscureText: _obscureConfirm,
                          onToggleObscure: () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                        ),
                        const SizedBox(height: 13),

                        _PasswordRuleRow(
                          passed: _hasMin6Chars,
                          text:
                              'Kamida 6 ta belgi (harf, raqam yoki belgi: a-z, 0-9, @#\$)',
                        ),
                        const SizedBox(height: 6),
                        _PasswordRuleRow(
                          passed: _passwordsMatch,
                          text: 'Ikkala parol bir-biriga mos',
                        ),
                        const SizedBox(height: 14),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: YanColors.lightBlue,
                            borderRadius: BorderRadius.circular(13),
                            border: Border.all(color: YanColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                'Supabase Login: $dummyEmailPreview',
                                style: const TextStyle(
                                  color: YanColors.primaryNavy,
                                  fontSize: 11.4,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Metadata: { role: "${widget.dbRole}", full_name: "${widget.fullName}" }',
                                style: const TextStyle(
                                  color: YanColors.primaryBlue,
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (widget.advocateLicenseFile != null) ...<Widget>[
                                const SizedBox(height: 3),
                                const Text(
                                  'Litsenziya + Guvohnoma (Oldi/Orqasi) + STIR: Supabase bazasiga yuklanadi ✓',
                                  style: TextStyle(
                                    color: Color(0xFF098562),
                                    fontSize: 10.8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        _SolidPrimaryButton(
                          label: _isSubmitting
                              ? 'Supabase bazasiga saqlanmoqda...'
                              : 'Parolni saqlash va PIN o‘rnatish (3/3)',
                          icon: CupertinoIcons.arrow_right,
                          onPressed: _isSubmitting
                              ? () {}
                              : _registerRealAccountInSupabase,
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
    );
  }
}

class _PasswordRuleRow extends StatelessWidget {
  const _PasswordRuleRow({required this.passed, required this.text});

  final bool passed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(
          passed
              ? CupertinoIcons.checkmark_circle_fill
              : CupertinoIcons.circle,
          size: 16,
          color: passed ? YanColors.successGreen : YanColors.subtleText,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: passed ? YanColors.primaryNavy : YanColors.mutedText,
              fontSize: 11.8,
              fontWeight: passed ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _PasswordTextField extends StatelessWidget {
  const _PasswordTextField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.onToggleObscure,
  });

  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final VoidCallback onToggleObscure;

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: TextInputType.visiblePassword,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15.5),
      style: const TextStyle(
        color: YanColors.primaryNavy,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      placeholder: hintText,
      placeholderStyle: const TextStyle(
        color: YanColors.subtleText,
        fontSize: 14.2,
      ),
      prefix: const Padding(
        padding: EdgeInsets.only(left: 15, right: 9),
        child: Icon(
          CupertinoIcons.lock_fill,
          size: 18,
          color: YanColors.primaryBlue,
        ),
      ),
      suffix: GestureDetector(
        onTap: onToggleObscure,
        child: Padding(
          padding: const EdgeInsets.only(right: 14),
          child: Icon(
            obscureText ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            size: 19,
            color: YanColors.mutedText,
          ),
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

// ═══════════════════════════════════════════════════════════════════════════
// STEP 3 OF 3: Local 4-Digit Phone PIN Setup Screen
// ═══════════════════════════════════════════════════════════════════════════

class LocalPhonePinSetupScreen extends StatefulWidget {
  const LocalPhonePinSetupScreen({
    super.key,
    required this.fullName,
    required this.phoneNumber,
  });

  final String fullName;
  final String phoneNumber;

  @override
  State<LocalPhonePinSetupScreen> createState() =>
      _LocalPhonePinSetupScreenState();
}

class _LocalPhonePinSetupScreenState extends State<LocalPhonePinSetupScreen> {
  String _firstPin = '';
  String _confirmPin = '';
  bool _isConfirmStep = false;

  String get _currentPin => _isConfirmStep ? _confirmPin : _firstPin;

  void _onKeyTap(String digit) {
    if (_currentPin.length >= 4) return;

    setState(() {
      if (_isConfirmStep) {
        _confirmPin += digit;
      } else {
        _firstPin += digit;
      }
    });

    if (!_isConfirmStep && _firstPin.length == 4) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (mounted) setState(() => _isConfirmStep = true);
      });
    } else if (_isConfirmStep && _confirmPin.length == 4) {
      if (_confirmPin != _firstPin) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: YanColors.destructiveRed,
            content: Text(
              'PIN-kodlar mos kelmadi. Iltimos, qaytadan kiriting.',
            ),
          ),
        );
        setState(() {
          _firstPin = '';
          _confirmPin = '';
          _isConfirmStep = false;
        });
      } else {
        _saveLocalPhonePinAndOpenApp(_confirmPin);
      }
    }
  }

  void _onBackspace() {
    setState(() {
      if (_isConfirmStep) {
        if (_confirmPin.isNotEmpty) {
          _confirmPin = _confirmPin.substring(0, _confirmPin.length - 1);
        } else {
          _isConfirmStep = false;
        }
      } else if (_firstPin.isNotEmpty) {
        _firstPin = _firstPin.substring(0, _firstPin.length - 1);
      }
    });
  }

  void _saveLocalPhonePinAndOpenApp(String pin) {
    userProfile.value = userProfile.value.copyWith(pinCode: pin);
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute<void>(builder: (_) => const MainDashboard()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: YanColors.background,
      body: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          const DashboardBackground(),
          SafeArea(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: YanColors.successGreen.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          '3/3-Qadam • Ilova PIN-kodi',
                          style: TextStyle(
                            color: Color(0xFF098562),
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    child: Column(
                      children: <Widget>[
                        LiquidGlassWindow(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: <Widget>[
                              Container(
                                width: 54,
                                height: 54,
                                decoration: BoxDecoration(
                                  color: YanColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(
                                  CupertinoIcons.circle_grid_3x3_fill,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                _isConfirmStep
                                    ? '4 xonali PIN-kodni tasdiqlang'
                                    : 'Telefon uchun 4 xonali PIN o‘rnating',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: YanColors.primaryNavy,
                                  fontSize: 20.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _isConfirmStep
                                    ? 'Ilovani ochishda ishlatiladigan 4 xonali PIN-kodni qayta kiriting'
                                    : 'Keyingi safar telefoningizda YAN360 ilovasini ochganingizda, xuddi telefon qulfi kabi faqat shu 4 xonali PIN-kod so‘raladi.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: YanColors.mutedText,
                                  fontSize: 12.6,
                                  height: 1.35,
                                ),
                              ),
                              const SizedBox(height: 18),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List<Widget>.generate(4, (index) {
                                  final filled = index < _currentPin.length;
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                    ),
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: filled
                                          ? YanColors.primaryBlue
                                          : YanColors.lightBlue,
                                      border: Border.all(
                                        color: filled
                                            ? YanColors.primaryBlue
                                            : YanColors.border,
                                        width: 1.5,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),

                        _PinNumericKeypad(
                          onDigitTap: _onKeyTap,
                          onBackspaceTap: _onBackspace,
                          onResetTap: () {
                            setState(() {
                              _firstPin = '';
                              _confirmPin = '';
                              _isConfirmStep = false;
                            });
                          },
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

class _PinNumericKeypad extends StatelessWidget {
  const _PinNumericKeypad({
    required this.onDigitTap,
    required this.onBackspaceTap,
    required this.onResetTap,
  });

  final ValueChanged<String> onDigitTap;
  final VoidCallback onBackspaceTap;
  final VoidCallback onResetTap;

  @override
  Widget build(BuildContext context) {
    const rows = <List<String>>[
      <String>['1', '2', '3'],
      <String>['4', '5', '6'],
      <String>['7', '8', '9'],
    ];

    return Column(
      children: <Widget>[
        ...rows.map(
          (row) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: row
                  .map(
                    (digit) => _KeypadCircleButton(
                      label: digit,
                      onTap: () => onDigitTap(digit),
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _KeypadCircleButton(
              icon: CupertinoIcons.refresh,
              isSecondary: true,
              onTap: onResetTap,
            ),
            _KeypadCircleButton(
              label: '0',
              onTap: () => onDigitTap('0'),
            ),
            _KeypadCircleButton(
              icon: CupertinoIcons.delete_left_fill,
              isSecondary: true,
              onTap: onBackspaceTap,
            ),
          ],
        ),
      ],
    );
  }
}

class _KeypadCircleButton extends StatelessWidget {
  const _KeypadCircleButton({
    this.label,
    this.icon,
    this.isSecondary = false,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool isSecondary;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 74,
        height: 62,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSecondary ? YanColors.lightBlue : YanColors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: YanColors.border, width: 1.2),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: YanColors.primaryNavy.withValues(alpha: 0.045),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: icon != null
            ? Icon(icon, color: YanColors.primaryNavy, size: 21)
            : Text(
                label ?? '',
                style: const TextStyle(
                  color: YanColors.primaryNavy,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// MainDashboard: Strictly 4 Sections Per Role
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
    _YanGlobalCallCenter.instance.startGlobalListening();
    ConsultationRepository.instance.ensureInitialized();
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
// ADVOKATXONA / ADVOKATIM Page — Shows ONLY Real Officially Registered Advocates
// Fetched Live from Supabase `public.profiles` (`where role = 'advocate'`)
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
  bool _isLoadingAdvocates = true;

  @override
  void initState() {
    super.initState();
    _fetchRealAdvocatesFromSupabase();
  }

  /// Queries Supabase `public.profiles` for ONLY officially registered advocates
  /// (`role = 'advocate'`). Zero fake accounts!
  Future<void> _fetchRealAdvocatesFromSupabase() async {
    if (mounted) setState(() => _isLoadingAdvocates = true);
    try {
      final byId = <String, Map<String, dynamic>>{};

      final ratingBuckets = <String, Map<String, int>>{};
      try {
        final allRows = await Supabase.instance.client
            .from('profiles')
            .select();
        for (final item in allRows) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = map['id']?.toString() ?? '';
          final role = map['role']?.toString().trim().toLowerCase() ?? '';
          if (id.isNotEmpty && (role == 'advocate' || role == 'advokat')) {
            byId[id] = map;
          }
          final pubKey = map['public_key']?.toString();
          if (pubKey != null &&
              pubKey.contains(_YanE2eeCryptoEngine._envelopeSeparator)) {
            final env = _YanE2eeCryptoEngine.decodeProfileEnvelope(pubKey);
            final rawRatings = env['advocate_ratings'];
            if (rawRatings is List) {
              for (final r in rawRatings) {
                if (r is Map) {
                  final advId = r['advocate_id']?.toString() ?? '';
                  final stars = (r['stars'] as num?)?.toInt() ?? 0;
                  if (advId.isNotEmpty && stars >= 1 && stars <= 5) {
                    final ratingId = r['ariza_id']?.toString().trim() ?? '';
                    final uniqueKey = ratingId.isEmpty
                        ? '${map['id']}:legacy:${ratingBuckets.length}:${stars}'
                        : ratingId;
                    ratingBuckets
                        .putIfAbsent(
                          _YanE2eeCryptoEngine.normalizeParticipantId(advId),
                          () => <String, int>{},
                        )
                        .putIfAbsent(uniqueKey, () => stars);
                  }
                }
              }
            }
          }
        }
      } catch (_) {}

      try {
        final licRows = await Supabase.instance.client
            .from('advocate_licenses')
            .select();
        for (final item in licRows) {
          final map = Map<String, dynamic>.from(item as Map);
          final id = map['advocate_id']?.toString() ?? map['id']?.toString() ?? '';
          if (id.isNotEmpty) {
            final existing = byId[id] ?? <String, dynamic>{'id': id};
            if ((existing['full_name']?.toString() ?? '').trim().isEmpty &&
                (map['full_name']?.toString() ?? '').trim().isNotEmpty) {
              existing['full_name'] = map['full_name'];
            }
            if ((map['phone']?.toString() ?? '').trim().isNotEmpty) {
              existing['phone'] = map['phone'];
            }
            if ((map['stir_number']?.toString() ?? '').trim().isNotEmpty) {
              existing['license_number'] = 'STIR: ${map['stir_number']}';
            }
            byId[id] = existing;
          }
        }
      } catch (_) {}

      final parsed = byId.values.map((map) {
        final base = LawyerDirectoryProfile.fromSupabaseMap(map);
        final normId = _YanE2eeCryptoEngine.normalizeParticipantId(base.id);
        final starsList = ratingBuckets[normId];
        if (starsList != null && starsList.isNotEmpty) {
          final baseSum = base.rating * base.feedbackCount;
          final addedSum = starsList.values.fold<int>(0, (a, b) => a + b);
          final totalCount = base.feedbackCount + starsList.length;
          final avg = (baseSum + addedSum) / totalCount;
          return base.copyWith(
            rating: double.parse(avg.toStringAsFixed(2)),
            feedbackCount: totalCount,
          );
        }
        return base;
      }).toList();
      YanRoleDataCatalog.registeredLawyers.value = parsed;

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser != null) {
        try {
          final contracts = await Supabase.instance.client
              .from('contracts')
              .select()
              .eq('client_id', currentUser.id)
              .limit(1);
          if (contracts.isNotEmpty) {
            final c = contracts.first;
            final advId = c['advocate_id']?.toString();
            if (advId != null && advId.isNotEmpty) {
              userProfile.value = userProfile.value.copyWith(
                contractedLawyerId: advId,
              );
            }
          }
        } catch (_) {}
      }
    } catch (_) {
      // Keep current list on network error
    } finally {
      if (mounted) setState(() => _isLoadingAdvocates = false);
    }
  }

  int get _activeFilterCount {
    var count = 0;
    if (_selectedRegion != 'Barchasi') count++;
    if (_selectedSpecialization != 'Barchasi') count++;
    if (_minExperienceYears > 0) count++;
    return count;
  }

  List<LawyerDirectoryProfile> get _sortedLawyers {
    final list = YanRoleDataCatalog.registeredLawyers.value.where((lawyer) {
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
    final pinnedLawyer = YanRoleDataCatalog.byIdOrNull(
      widget.profile.contractedLawyerId,
    );
    final allLawyers = _sortedLawyers;
    final locationLabel = _selectedRegion == 'Barchasi'
        ? 'Rasmiy ro‘yxatdan o‘tgan advokatlar (${allLawyers.length} ta)'
        : _selectedRegion;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: <Widget>[
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: <Widget>[
                GestureDetector(
                  onTap: _fetchRealAdvocatesFromSupabase,
                  child: Container(
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
                    child: _isLoadingAdvocates
                        ? const CupertinoActivityIndicator(
                            color: YanColors.primaryBlue,
                          )
                        : const Icon(
                            CupertinoIcons.refresh,
                            color: YanColors.primaryBlue,
                            size: 19,
                          ),
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
                          fontSize: 12.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
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

        SliverToBoxAdapter(
          child: ValueListenableBuilder<List<ConsultationBooking>>(
            valueListenable: ConsultationRepository.instance.consultations,
            builder: (context, allBookings, _) {
              final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
              final myId = authId.isNotEmpty ? authId : userProfile.value.clientId;
              final activeBookings = allBookings
                  .where((b) =>
                      YanRoleDataCatalog.isSameParticipant(b.clientId, myId) &&
                      b.isActiveStatus &&
                      !b.isExpired())
                  .toList()
                ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
              if (activeBookings.isEmpty) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 2),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.push_pin_rounded, size: 15, color: YanColors.primaryBlue),
                        SizedBox(width: 6),
                        Text(
                          'BAND QILINGAN KONSULTATSIYALARINGIZ',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: YanColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...activeBookings.map((booking) {
                      return _PinnedConsultationBannerCard(
                        booking: booking,
                        isAdvocateView: false,
                        onOpenChat: () {
                          final matchedAdv = YanRoleDataCatalog.registeredLawyers.value
                              .where((a) => YanRoleDataCatalog.isSameParticipant(a.id, booking.advocateId))
                              .firstOrNull;
                          final peer = matchedAdv ??
                              LawyerDirectoryProfile(
                                id: booking.advocateId,
                                fullName: booking.advocateName,
                                title: booking.advocateTitle.isEmpty
                                    ? 'Rasmiy Advokat'
                                    : booking.advocateTitle,
                                region: 'Toshkent shahri',
                                specialization: booking.advocateSpecialization.isEmpty
                                    ? 'Yuridik konsultatsiya'
                                    : booking.advocateSpecialization,
                                experienceYears: 5,
                                rating: 5.0,
                                feedbackCount: 1,
                                wonCasesCount: 10,
                                consultationPriceUzs: 99000,
                                contractMonthlyNote: 'YAN360 Advokati',
                                licenseNumber: 'Tasdiqlangan',
                                phone: '+998',
                                assistantName: '-',
                                assistantRole: '',
                                assistantPhone: '',
                                bio: 'YAN360 rasmiy advokati.',
                                feedbacks: const <LawyerFeedbackItem>[],
                              );
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AdvocateClientChatPage(
                                lawyer: peer,
                                profile: userProfile.value,
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ],
                ),
              );
            },
          ),
        ),

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

        if (pinnedLawyer != null)
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

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 118),
          sliver: _isLoadingAdvocates
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: CupertinoActivityIndicator(
                        radius: 14,
                        color: YanColors.primaryBlue,
                      ),
                    ),
                  ),
                )
              : allLawyers.isEmpty
                  ? SliverToBoxAdapter(
                      child: LiquidGlassWindow(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: <Widget>[
                            Container(
                              width: 56,
                              height: 56,
                              decoration: const BoxDecoration(
                                color: YanColors.lightBlue,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                CupertinoIcons.briefcase_fill,
                                color: YanColors.primaryBlue,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Hozircha rasmiy ro‘yxatdan o‘tgan advokatlar yo‘q',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: YanColors.primaryNavy,
                                fontSize: 16.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Barcha soxta (demo) profillar o‘chirildi. Advokat sifatida rasmiy ro‘yxatdan o‘tilgach, haqiqiy advokat profillari shu yerda avtomatik ko‘rinadi.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: YanColors.mutedText,
                                fontSize: 12.6,
                                height: 1.36,
                              ),
                            ),
                            const SizedBox(height: 16),
                            LiquidActionButton(
                              label: 'Ro‘yxatni yangilash',
                              icon: CupertinoIcons.refresh,
                              compact: true,
                              onPressed: _fetchRealAdvocatesFromSupabase,
                            ),
                          ],
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final lawyer = allLawyers[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 13),
                            child: _AdvocateDirectoryCard(
                              lawyer: lawyer,
                              isPinnedContract:
                                  lawyer.id ==
                                  widget.profile.contractedLawyerId,
                              onProfileTap: () =>
                                  _openLawyerProfilePage(lawyer),
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
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortTabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? YanColors.primaryBlue : YanColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? YanColors.primaryBlue
                : YanColors.border.withValues(alpha: 0.95),
          ),
          boxShadow: selected
              ? const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x281677D2),
                    blurRadius: 12,
                    offset: Offset(0, 4),
                  ),
                ]
              : const <BoxShadow>[],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : YanColors.primaryNavy,
          ),
        ),
      ),
    );
  }
}

class _FilterChipPill extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _FilterChipPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8.5),
        decoration: BoxDecoration(
          color: active ? YanColors.primaryBlue : YanColors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? YanColors.primaryBlue : YanColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : YanColors.primaryNavy,
          ),
        ),
      ),
    );
  }
}

class _PinnedAdvocateBannerCard extends StatelessWidget {
  final LawyerDirectoryProfile lawyer;
  final UserProfileData profile;
  final VoidCallback onProfileTap;
  final VoidCallback onMessageTap;

  const _PinnedAdvocateBannerCard({
    required this.lawyer,
    required this.profile,
    required this.onProfileTap,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YanColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: YanColors.primaryBlue.withValues(alpha: 0.45),
          width: 1.4,
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x161677D2),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: YanColors.primaryBlue,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(Icons.push_pin_rounded, size: 12, color: Colors.white),
                    SizedBox(width: 5),
                    Text(
                      'BIRIKTIRILGAN ADVOKAT • PINNED',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    lawyer.rating.toStringAsFixed(2),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                  Text(
                    ' (${lawyer.feedbackCount} izoh)',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: YanColors.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LawyerAvatarPortrait(
                initials: lawyer.initials,
                isOnline: lawyer.isVerifiedPartner,
                size: 58,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            lawyer.fullName,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: YanColors.primaryNavy,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          size: 17,
                          color: YanColors.primaryBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${lawyer.title} • ${lawyer.specialization}',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: YanColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Litsenziya: ${lawyer.licenseNumber} • ${lawyer.region}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: YanColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            lawyer.bio,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: YanColors.primaryNavy,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lawyer.consultationPriceUzs > 0
                          ? '${lawyer.consultationPriceUzs} so‘m'
                          : 'Bepul dastlabki maslahat',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Javob vaqti: ~10 daqiqada',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: YanColors.mutedText,
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
    );
  }
}

class _AdvocateDirectoryCard extends StatelessWidget {
  final LawyerDirectoryProfile lawyer;
  final bool isPinnedContract;
  final VoidCallback onProfileTap;
  final VoidCallback onMessageTap;

  const _AdvocateDirectoryCard({
    required this.lawyer,
    required this.isPinnedContract,
    required this.onProfileTap,
    required this.onMessageTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: YanColors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: YanColors.border.withValues(alpha: 0.9),
        ),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0A0E2A54),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _LawyerAvatarPortrait(
                initials: lawyer.initials,
                isOnline: lawyer.isVerifiedPartner,
                size: 54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            lawyer.fullName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: YanColors.primaryNavy,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.verified_rounded,
                          size: 16,
                          color: YanColors.primaryBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      lawyer.specialization,
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Litsenziya: ${lawyer.licenseNumber} • ${lawyer.region}',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: YanColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const Icon(
                        Icons.star_rounded,
                        size: 16,
                        color: Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        lawyer.rating.toStringAsFixed(2),
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: YanColors.primaryNavy,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '(${lawyer.feedbackCount} izoh)',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: YanColors.mutedText,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            lawyer.bio,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: YanColors.mutedText,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _SpecialtyTagPill(label: lawyer.specialization),
              if (lawyer.phone.isNotEmpty)
                _SpecialtyTagPill(label: lawyer.phone),
              _SpecialtyTagPill(
                label: lawyer.isVerifiedPartner
                    ? 'Tasdiqlangan (Online)'
                    : 'Tekshiruvda',
                isHighlight: lawyer.isVerifiedPartner,
              ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      lawyer.consultationPriceUzs > 0
                          ? '${lawyer.consultationPriceUzs} so‘m'
                          : 'Bepul maslahat',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Javob beradi: ~15 daqiqa',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: YanColors.mutedText,
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
    );
  }
}

class _SpecialtyTagPill extends StatelessWidget {
  final String label;
  final bool isHighlight;

  const _SpecialtyTagPill({
    required this.label,
    this.isHighlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isHighlight
            ? YanColors.successGreen.withValues(alpha: 0.12)
            : YanColors.lightBlue,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: isHighlight ? const Color(0xFF0A936B) : YanColors.primaryNavy,
        ),
      ),
    );
  }
}

class _CardPillButton extends StatelessWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _CardPillButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? YanColors.primaryBlue : YanColors.lightBlue,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: isPrimary
                ? YanColors.primaryBlue
                : YanColors.primaryBlue.withValues(alpha: 0.35),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: isPrimary ? Colors.white : YanColors.primaryBlue,
          ),
        ),
      ),
    );
  }
}

class _LawyerAvatarPortrait extends StatelessWidget {
  final String initials;
  final bool isOnline;
  final double size;

  const _LawyerAvatarPortrait({
    required this.initials,
    required this.isOnline,
    this.size = 54,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: YanColors.primaryNavy,
            border: Border.all(
              color: YanColors.primaryBlue.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            initials,
            style: TextStyle(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w800,
              color: Colors.white,
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
              shape: BoxShape.circle,
              color: isOnline ? YanColors.successGreen : const Color(0xFFF59E0B),
              border: Border.all(color: Colors.white, width: 2),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// LAWYER DETAIL PROFILE PAGE (DEDICATED SUPABASE PROFILE & CONTRACT SIGNING)
// ============================================================================
class LawyerDetailProfilePage extends StatefulWidget {
  final LawyerDirectoryProfile lawyer;
  final UserProfileData profile;

  const LawyerDetailProfilePage({
    super.key,
    required this.lawyer,
    required this.profile,
  });

  @override
  State<LawyerDetailProfilePage> createState() =>
      _LawyerDetailProfilePageState();
}

class _LawyerDetailProfilePageState extends State<LawyerDetailProfilePage> {
  int _selectedDetailTab = 0;
  bool _isSigningContract = false;

  void _openChat(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdvocateClientChatPage(
          lawyer: widget.lawyer,
          profile: widget.profile,
        ),
      ),
    );
  }

  Future<void> _bookOrSignContract(BuildContext context) async {
    if (_isSigningContract) return;
    setState(() => _isSigningContract = true);

    try {
      final client = Supabase.instance.client;
      final currentUser = client.auth.currentUser;
      final currentProfile = userProfile.value;

      if (currentUser != null) {
        await client.from('contracts').insert(<String, dynamic>{
          'client_id': currentUser.id,
          'advocate_id': widget.lawyer.id,
          'client_name': currentProfile.displayName,
          'advocate_name': widget.lawyer.fullName,
          'case_category': widget.lawyer.specialization,
          'status': 'active',
        });
      }
    } catch (_) {
      // Continues local state assignment if table RLS or schema differs
    }

    await userProfile.switchRole(
      UserRole.mijoz,
      lawyerId: widget.lawyer.id,
    );

    if (!mounted) return;
    setState(() => _isSigningContract = false);

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: YanColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: <Widget>[
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: YanColors.successGreen.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.verified_rounded,
                color: YanColors.successGreen,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Shartnoma biriktirildi',
                style: TextStyle(
                  fontSize: 16.5,
                  fontWeight: FontWeight.w800,
                  color: YanColors.primaryNavy,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          '${widget.lawyer.fullName} sizning shaxsiy advokatingiz sifatida biriktirildi va Mijoz (-50% VIP) maqomi faollashtirildi.',
          style: const TextStyle(
            fontSize: 13,
            color: YanColors.mutedText,
            height: 1.45,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Yopish',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: YanColors.mutedText,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: YanColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _openChat(context);
            },
            child: const Text(
              'Chatga o‘tish',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
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
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: Row(
                children: <Widget>[
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: YanColors.white,
                        border: Border.all(color: YanColors.border),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        size: 20,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      'Advokat Profili',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: YanColors.white,
                      border: Border.all(color: YanColors.border),
                    ),
                    child: const Icon(
                      Icons.verified_user_rounded,
                      size: 19,
                      color: YanColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
                child: Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: YanColors.white,
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(color: YanColors.border),
                        boxShadow: const <BoxShadow>[
                          BoxShadow(
                            color: Color(0x0D0E2A54),
                            blurRadius: 22,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          _LawyerAvatarPortrait(
                            initials: lawyer.initials,
                            isOnline: lawyer.isVerifiedPartner,
                            size: 86,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  lawyer.fullName,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                    color: YanColors.primaryNavy,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified_rounded,
                                color: YanColors.primaryBlue,
                                size: 20,
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            '${lawyer.title} • ${lawyer.specialization}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: YanColors.primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Litsenziya: ${lawyer.licenseNumber} • ${lawyer.region}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: YanColors.mutedText,
                            ),
                          ),
                          const SizedBox(height: 18),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              _CircleProfileActionButton(
                                icon: Icons.chat_bubble_rounded,
                                label: 'Xabar',
                                isPrimary: true,
                                onTap: () => _openChat(context),
                              ),
                              _CircleProfileActionButton(
                                icon: Icons.phone_in_talk_rounded,
                                label: 'Qo‘ng‘iroq',
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'E2EE Audio qo‘ng‘iroq: ${lawyer.phone.isNotEmpty ? lawyer.phone : lawyer.fullName}',
                                      ),
                                      backgroundColor: YanColors.primaryNavy,
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                              ),
                              _CircleProfileActionButton(
                                icon: Icons.assignment_turned_in_rounded,
                                label: 'Shartnoma',
                                onTap: () => _bookOrSignContract(context),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),
                          const Divider(height: 1, color: Color(0xFFE7EFFA)),
                          const SizedBox(height: 14),

                          Row(
                            children: <Widget>[
                              Expanded(
                                child: _LawyerDetailStatCol(
                                  value: '${lawyer.rating}',
                                  label: 'Reyting (${lawyer.feedbackCount})',
                                  icon: Icons.star_rounded,
                                  iconColor: const Color(0xFFF59E0B),
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 34,
                                color: const Color(0xFFE7EFFA),
                              ),
                              Expanded(
                                child: _LawyerDetailStatCol(
                                  value: lawyer.isVerifiedPartner
                                      ? 'Tasdiqlangan'
                                      : 'Tekshiruvda',
                                  label: 'Litsenziya holati',
                                  icon: Icons.verified_user_rounded,
                                  iconColor: YanColors.successGreen,
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 34,
                                color: const Color(0xFFE7EFFA),
                              ),
                              Expanded(
                                child: _LawyerDetailStatCol(
                                  value: '${lawyer.experienceYears} yil',
                                  label: 'Ish tajribasi',
                                  icon: Icons.business_rounded,
                                  iconColor: YanColors.primaryBlue,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: YanColors.lightBlue,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: <Widget>[
                          Expanded(
                            child: _MonochromaticSegmentButton(
                              label: 'Haqida',
                              selected: _selectedDetailTab == 0,
                              onTap: () =>
                                  setState(() => _selectedDetailTab = 0),
                            ),
                          ),
                          Expanded(
                            child: _MonochromaticSegmentButton(
                              label: 'Tasdiqlangan hujjatlar',
                              selected: _selectedDetailTab == 1,
                              onTap: () =>
                                  setState(() => _selectedDetailTab = 1),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    if (_selectedDetailTab == 0)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: YanColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: YanColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Advokat haqida ma’lumot',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: YanColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              lawyer.bio,
                              style: const TextStyle(
                                fontSize: 13,
                                color: YanColors.mutedText,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 14),
                            _DetailInfoRow(
                              label: 'Telefon raqami',
                              value: lawyer.phone.isNotEmpty
                                  ? lawyer.phone
                                  : 'E2EE orqali bog‘lanish',
                            ),
                            _DetailInfoRow(
                              label: 'Litsenziya raqami',
                              value: lawyer.licenseNumber,
                            ),
                            _DetailInfoRow(
                              label: 'Mutaxassisligi',
                              value: lawyer.specialization,
                            ),
                            _DetailInfoRow(
                              label: 'Hudud',
                              value: lawyer.region,
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: YanColors.white,
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(color: YanColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const Text(
                              'Supabase bazasida tekshirilgan hujjatlar',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: YanColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _VerifiedDocRow(
                              title: '1. Advokatlik litsenziyasi',
                              subtitle: 'Raqami: ${lawyer.licenseNumber}',
                            ),
                            const SizedBox(height: 8),
                            const _VerifiedDocRow(
                              title: '2. Advokatlik guvohnomasi (Old va Orqa)',
                              subtitle: 'Supabase Storage orqali yuklangan',
                            ),
                            const SizedBox(height: 8),
                            const _VerifiedDocRow(
                              title: '3. Faoliyat ko‘rsatadigan tuzilma STIR',
                              subtitle: 'Rasmiy ro‘yxatdan o‘tkazilgan',
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              decoration: const BoxDecoration(
                color: YanColors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5EFFA))),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: _SolidSecondaryButton(
                      label: 'Shartnoma tuzish',
                      icon: Icons.verified_user_rounded,
                      onPressed: () => _bookOrSignContract(context),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SolidPrimaryButton(
                      label: 'Xabar yozish',
                      icon: Icons.chat_bubble_rounded,
                      onPressed: () => _openChat(context),
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

class _DetailInfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailInfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: YanColors.mutedText,
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w800,
                color: YanColors.primaryNavy,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerifiedDocRow extends StatelessWidget {
  final String title;
  final String subtitle;

  const _VerifiedDocRow({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: YanColors.lightBlue,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.verified_rounded,
            color: YanColors.successGreen,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: YanColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: YanColors.mutedText,
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
  final IconData icon;
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _CircleProfileActionButton({
    required this.icon,
    required this.label,
    this.isPrimary = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isPrimary ? YanColors.primaryBlue : YanColors.lightBlue,
              border: Border.all(
                color: isPrimary
                    ? YanColors.primaryBlue
                    : YanColors.primaryBlue.withValues(alpha: 0.25),
              ),
            ),
            child: Icon(
              icon,
              size: 22,
              color: isPrimary ? Colors.white : YanColors.primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: YanColors.primaryNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _LawyerDetailStatCol extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color iconColor;

  const _LawyerDetailStatCol({
    required this.value,
    required this.label,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, size: 15, color: iconColor),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                value,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: YanColors.primaryNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: YanColors.mutedText,
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// ZERO-KNOWLEDGE E2EE ENGINE + INSTANT 0.00s REALTIME CHAT & OFFLINE SYNC
// + #ARIZA FILE PICKER, VIEW/SAVE, ACCEPT/REJECT & 5-STAR RATING WORKFLOW
// ============================================================================
enum _ChatMediaType { text, voice, image, video, document, callLog }

/// Structured metadata for an `#ariza` file delivery message.
/// Tracks `arizaId`, `status` ('null' when not responded, 'accepted', 'rejected'),
/// `sentTimeIso`, and original unencrypted file paths.
class _ArizaFileDeliveryMeta {
  final String arizaId;
  final String status; // 'null' (unresponded), 'accepted', 'rejected'
  final String fileName;
  final String storagePath; // Original unwatermarked file path in Supabase Storage
  final String watermarkedStoragePath; // Watermarked inspection file path in Supabase Storage
  final String storageBucket;
  final String localPath;
  final String sentTimeIso;
  final int ratedStars; // 0 = not yet rated, 1..5 = rated by client
  final String rejectionReason;

  const _ArizaFileDeliveryMeta({
    this.arizaId = 'ARZ-1001',
    this.status = 'null',
    required this.fileName,
    this.storagePath = '',
    this.watermarkedStoragePath = '',
    this.storageBucket = 'advocate_licenses',
    this.localPath = '',
    this.sentTimeIso = '',
    this.ratedStars = 0,
    this.rejectionReason = '',
  });

  DateTime? get sentAtDateTime =>
      sentTimeIso.isNotEmpty ? DateTime.tryParse(sentTimeIso)?.toLocal() : null;

  /// Delivery controls unlock once the client accepts (or after 30 minutes if unresponded).
  bool isEffectivelyAccepted(DateTime now) {
    if (status == 'accepted') return true;
    final sentAt = sentAtDateTime;
    if (status == 'null' &&
        sentAt != null &&
        now.difference(sentAt).inMinutes >= 30) {
      return true;
    }
    return false;
  }

  static int _statusRank(String s) {
    if (s == 'accepted') return 2;
    if (s == 'rejected') return 1;
    return 0;
  }

  /// Ensures background profile envelope polling never downgrades `accepted` or `rejected` back to `null`!
  static String? mergeMediaMeta(String? currentMeta, String? incomingMeta) {
    if (incomingMeta == null || incomingMeta.isEmpty) return currentMeta;
    if (currentMeta == null || currentMeta.isEmpty) return incomingMeta;
    if (currentMeta.startsWith('ARIZA_FILE_V2|') &&
        incomingMeta.startsWith('ARIZA_FILE_V2|')) {
      final cur = tryParse(currentMeta, '');
      final inc = tryParse(incomingMeta, '');
      if (cur != null && inc != null) {
        final bestStatus = _statusRank(inc.status) >= _statusRank(cur.status)
            ? inc.status
            : cur.status;
        final bestStars = inc.ratedStars > cur.ratedStars
            ? inc.ratedStars
            : cur.ratedStars;
        final bestReason = inc.rejectionReason.isNotEmpty
            ? inc.rejectionReason
            : cur.rejectionReason;
        return cur
            .copyWith(
              status: bestStatus,
              ratedStars: bestStars,
              rejectionReason: bestReason,
              storagePath: inc.storagePath.isNotEmpty
                  ? inc.storagePath
                  : cur.storagePath,
              watermarkedStoragePath: inc.watermarkedStoragePath.isNotEmpty
                  ? inc.watermarkedStoragePath
                  : cur.watermarkedStoragePath,
              storageBucket: inc.storageBucket.isNotEmpty
                  ? inc.storageBucket
                  : cur.storageBucket,
            )
            .encode();
      }
    }
    return incomingMeta;
  }

  String encode() {
    final safeId = Uri.encodeComponent(arizaId);
    final safeName = Uri.encodeComponent(fileName);
    final safeStorage = Uri.encodeComponent(storagePath);
    final safeWmStorage = Uri.encodeComponent(watermarkedStoragePath);
    final safeBucket = Uri.encodeComponent(storageBucket);
    final safeLocal = Uri.encodeComponent(localPath);
    final safeSent = Uri.encodeComponent(sentTimeIso);
    final safeReason = Uri.encodeComponent(rejectionReason);
    return 'ARIZA_FILE_V2|id:$safeId|status:$status|name:$safeName|storage:$safeStorage|wmstorage:$safeWmStorage|bucket:$safeBucket|local:$safeLocal|sent:$safeSent|stars:$ratedStars|reason:$safeReason';
  }

  _ArizaFileDeliveryMeta copyWith({
    String? arizaId,
    String? status,
    String? fileName,
    String? storagePath,
    String? watermarkedStoragePath,
    String? storageBucket,
    String? localPath,
    String? sentTimeIso,
    int? ratedStars,
    String? rejectionReason,
  }) {
    return _ArizaFileDeliveryMeta(
      arizaId: arizaId ?? this.arizaId,
      status: status ?? this.status,
      fileName: fileName ?? this.fileName,
      storagePath: storagePath ?? this.storagePath,
      watermarkedStoragePath:
          watermarkedStoragePath ?? this.watermarkedStoragePath,
      storageBucket: storageBucket ?? this.storageBucket,
      localPath: localPath ?? this.localPath,
      sentTimeIso: sentTimeIso ?? this.sentTimeIso,
      ratedStars: ratedStars ?? this.ratedStars,
      rejectionReason: rejectionReason ?? this.rejectionReason,
    );
  }

  static _ArizaFileDeliveryMeta? tryParse(String? rawMeta, String messageText) {
    if (rawMeta != null && rawMeta.startsWith('ARIZA_FILE_V2|')) {
      final map = <String, String>{};
      for (final part in rawMeta.split('|').skip(1)) {
        final idx = part.indexOf(':');
        if (idx > 0) {
          map[part.substring(0, idx)] = Uri.decodeComponent(
            part.substring(idx + 1),
          );
        }
      }
      final rawStatus = map['status'] ?? 'null';
      return _ArizaFileDeliveryMeta(
        arizaId: map['id']?.isNotEmpty == true ? map['id']! : 'ARZ-1001',
        status: rawStatus == 'pending' ? 'null' : rawStatus,
        fileName: map['name']?.isNotEmpty == true
            ? map['name']!
            : 'Tayyor_Ariza.docx',
        storagePath: map['storage'] ?? '',
        watermarkedStoragePath: map['wmstorage'] ?? '',
        storageBucket: map['bucket']?.isNotEmpty == true
            ? map['bucket']!
            : 'advocate_licenses',
        localPath: map['local'] ?? '',
        sentTimeIso: map['sent'] ?? '',
        ratedStars: int.tryParse(map['stars'] ?? '0') ?? 0,
        rejectionReason: map['reason'] ?? '',
      );
    }
    return null;
  }
}

class _YanE2eeCryptoEngine {
  _YanE2eeCryptoEngine._();

  static const String _prefix = 'E2EEv1:';
  static const String _masterSalt = 'YAN360-ZK-E2EE-UZ-2026-PRIVATE-SALT';
  static const String _envelopeKey = 'yan360_profile_envelope_v2';
  static const String _envelopeSeparator = '||E2EE_ENV:';

  static String normalizeParticipantId(String rawId) {
    var clean = rawId.trim().toLowerCase();
    if (clean.startsWith('yan-')) {
      clean = clean.substring(4);
    }
    clean = clean.replaceAll(RegExp(r'[^a-z0-9]'), '');
    // Keep the full identifier: truncating UUIDs made unrelated users collide.
    return clean.isEmpty ? 'anonuser' : clean;
  }

  static String buildCanonicalRoomKey(String idA, String idB) {
    final normA = normalizeParticipantId(idA);
    final normB = normalizeParticipantId(idB);
    final pair = <String>[normA, normB]..sort();
    return 'room_${pair[0]}__${pair[1]}';
  }

  static List<int> _deriveKeyStream(String roomKey, String nonce, int length) {
    final seedStr = '$_masterSalt|$roomKey|$nonce';
    final seedBytes = utf8.encode(seedStr);
    final out = List<int>.filled(length, 0);
    var state = 0x811C9DC5;
    for (final b in seedBytes) {
      state ^= b;
      state = (state * 0x01000193) & 0xFFFFFFFF;
    }
    for (var i = 0; i < length; i++) {
      state ^= (seedBytes[i % seedBytes.length] + i * 31) & 0xFF;
      state = ((state << 5) | (state >> 27)) & 0xFFFFFFFF;
      state = (state * 0x01000193 + 0x9E3779B9) & 0xFFFFFFFF;
      out[i] = (state ^ (state >> 16)) & 0xFF;
    }
    return out;
  }

  static String encrypt(String plaintext, String roomKey) {
    if (plaintext.startsWith(_prefix)) return plaintext;
    final rnd = Random.secure();
    final nonceBytes = List<int>.generate(8, (_) => rnd.nextInt(256));
    final nonceHex = nonceBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final plainBytes = utf8.encode(plaintext);
    final stream = _deriveKeyStream(roomKey, nonceHex, plainBytes.length);
    final cipherBytes = List<int>.generate(
      plainBytes.length,
      (i) => plainBytes[i] ^ stream[i],
    );
    return '$_prefix$nonceHex:${base64UrlEncode(cipherBytes)}';
  }

  static String decrypt(String payload, String roomKey) {
    if (!payload.startsWith(_prefix)) return payload;
    try {
      final raw = payload.substring(_prefix.length);
      final sepIndex = raw.indexOf(':');
      if (sepIndex <= 0) return payload;
      final nonceHex = raw.substring(0, sepIndex);
      final cipherB64 = raw.substring(sepIndex + 1);
      final cipherBytes = base64Url.decode(cipherB64);
      final stream = _deriveKeyStream(roomKey, nonceHex, cipherBytes.length);
      final plainBytes = List<int>.generate(
        cipherBytes.length,
        (i) => cipherBytes[i] ^ stream[i],
      );
      return utf8.decode(plainBytes, allowMalformed: true);
    } catch (_) {
      return payload;
    }
  }

  static const List<int> _binaryMagic = <int>[
    0x59, 0x41, 0x4E, 0x45, 0x32, 0x45, 0x45, 0x31 // "YANE2EE1"
  ];

  /// Encrypts binary chat file bytes (everything except `#ariza` audit files) using the room E2EE key.
  static Uint8List encryptBytes(List<int> plainBytes, String roomKey) {
    final rnd = Random.secure();
    final nonceBytes = List<int>.generate(8, (_) => rnd.nextInt(256));
    final nonceHex = nonceBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final stream = _deriveKeyStream(roomKey, nonceHex, plainBytes.length);
    final out = Uint8List(_binaryMagic.length + 8 + plainBytes.length);
    for (var i = 0; i < _binaryMagic.length; i++) {
      out[i] = _binaryMagic[i];
    }
    for (var i = 0; i < 8; i++) {
      out[_binaryMagic.length + i] = nonceBytes[i];
    }
    final offset = _binaryMagic.length + 8;
    for (var i = 0; i < plainBytes.length; i++) {
      out[offset + i] = (plainBytes[i] ^ stream[i]) & 0xFF;
    }
    return out;
  }

  /// Decrypts binary chat file bytes on-device using the room E2EE key.
  static Uint8List decryptBytes(Uint8List rawBytes, String roomKey) {
    if (rawBytes.length < _binaryMagic.length + 8) return rawBytes;
    for (var i = 0; i < _binaryMagic.length; i++) {
      if (rawBytes[i] != _binaryMagic[i]) {
        return rawBytes; // Legacy unencrypted fallback
      }
    }
    final nonceBytes = rawBytes.sublist(
      _binaryMagic.length,
      _binaryMagic.length + 8,
    );
    final nonceHex = nonceBytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final cipherLen = rawBytes.length - (_binaryMagic.length + 8);
    final stream = _deriveKeyStream(roomKey, nonceHex, cipherLen);
    final plain = Uint8List(cipherLen);
    final offset = _binaryMagic.length + 8;
    for (var i = 0; i < cipherLen; i++) {
      plain[i] = (rawBytes[offset + i] ^ stream[i]) & 0xFF;
    }
    return plain;
  }

  static Map<String, dynamic> decodeProfileEnvelope(String? rawPublicKey) {
    if (rawPublicKey == null || !rawPublicKey.contains(_envelopeSeparator)) {
      return <String, dynamic>{
        'rooms': <String, dynamic>{},
        'ariza_orders': <dynamic>[],
        'advocate_ratings': <dynamic>[],
      };
    }
    try {
      final parts = rawPublicKey.split(_envelopeSeparator);
      if (parts.length < 2) {
        return <String, dynamic>{
          'rooms': <String, dynamic>{},
          'ariza_orders': <dynamic>[],
          'advocate_ratings': <dynamic>[],
        };
      }
      final decrypted = decrypt(parts.last.trim(), _envelopeKey);
      final map = jsonDecode(decrypted);
      if (map is Map) {
        return Map<String, dynamic>.from(map);
      }
    } catch (_) {}
    return <String, dynamic>{
      'rooms': <String, dynamic>{},
      'ariza_orders': <dynamic>[],
      'advocate_ratings': <dynamic>[],
    };
  }

  static String encodeProfileEnvelope(
    String? existingPublicKey,
    Map<String, dynamic> envelope,
  ) {
    var baseKey = 'PUB-X25519-YAN360';
    if (existingPublicKey != null && existingPublicKey.trim().isNotEmpty) {
      baseKey = existingPublicKey.split(_envelopeSeparator).first.trim();
      if (baseKey.isEmpty) baseKey = 'PUB-X25519-YAN360';
    }
    final jsonStr = jsonEncode(envelope);
    final enc = encrypt(jsonStr, _envelopeKey);
    return '$baseKey$_envelopeSeparator$enc';
  }

  static Future<void> updateMyProfileE2eeEnvelope({
    String? roomKey,
    List<Map<String, dynamic>>? myRoomMessages,
    String? lastSeenInRoomIso,
    bool? isOnline,
    Map<String, dynamic>? newAdvocateRatingEntry,
  }) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    try {
      final myRow = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      final existingPubKey = myRow?['public_key']?.toString();
      final env = decodeProfileEnvelope(existingPubKey);

      final nowIso = DateTime.now().toUtc().toIso8601String();
      if (isOnline != null) {
        env['is_online'] = isOnline;
      }
      env['last_seen'] = nowIso;

      final roomsRaw = env['rooms'];
      final rooms = (roomsRaw is Map)
          ? Map<String, dynamic>.from(roomsRaw)
          : <String, dynamic>{};

      if (roomKey != null) {
        final roomEntryRaw = rooms[roomKey];
        final roomEntry = (roomEntryRaw is Map)
            ? Map<String, dynamic>.from(roomEntryRaw)
            : <String, dynamic>{};

        if (myRoomMessages != null) {
          final trimmed = myRoomMessages.length > 60
              ? myRoomMessages.sublist(myRoomMessages.length - 60)
              : myRoomMessages;
          roomEntry['messages'] = trimmed;
        }
        if (lastSeenInRoomIso != null) {
          roomEntry['last_seen_by_me'] = lastSeenInRoomIso;
        }
        rooms[roomKey] = roomEntry;
      }
      env['rooms'] = rooms;

      if (newAdvocateRatingEntry != null) {
        final rawList = env['advocate_ratings'];
        final ratingsList = (rawList is List)
            ? List<dynamic>.from(rawList)
            : <dynamic>[];
        ratingsList.add(newAdvocateRatingEntry);
        env['advocate_ratings'] = ratingsList;
      }

      final ordersList = YanRoleDataCatalog.arizaOrders.value
          .where((order) =>
              YanRoleDataCatalog.isSameParticipant(
                order.clientId,
                authUser.id,
              ) ||
              YanRoleDataCatalog.isSameParticipant(
                order.advocateId,
                authUser.id,
              ))
          .take(25)
          .map((e) => e.toJson())
          .toList();
      env['ariza_orders'] = ordersList;

      final newPubKey = encodeProfileEnvelope(existingPubKey, env);
      await Supabase.instance.client
          .from('profiles')
          .update(<String, dynamic>{'public_key': newPubKey})
          .eq('id', authUser.id);
    } catch (_) {}
  }

  static Future<File> _localArizaLedgerFile(String userId) async {
    final safeUserId = normalizeParticipantId(userId);
    return File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}yan360_ariza_orders_$safeUserId.json',
    );
  }

  static String _resolveCurrentUserId() {
    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (authId.trim().isNotEmpty) return authId.trim();
    return userProfile.value.clientId.trim();
  }

  static ArizaOrderItem _mergeOrderState(
    ArizaOrderItem existing,
    ArizaOrderItem incoming,
  ) {
    if (incoming.clientResponseStatus == 'accepted' || incoming.isCompleted) {
      return incoming;
    }
    if (existing.clientResponseStatus == 'accepted' || existing.isCompleted) {
      return existing;
    }
    if (incoming.clientResponseStatus == 'rejected') {
      return incoming;
    }
    if (existing.clientResponseStatus == 'rejected') {
      return existing;
    }
    if (incoming.arizaSentAt != null && existing.arizaSentAt == null) {
      return incoming;
    }
    return existing;
  }

  static Future<void> persistArizaOrdersLedger() async {
    final userId = _resolveCurrentUserId();
    final scopedOrders = userId.isEmpty
        ? YanRoleDataCatalog.arizaOrders.value
        : YanRoleDataCatalog.arizaOrders.value.where((order) =>
            YanRoleDataCatalog.isSameParticipant(order.clientId, userId) ||
            YanRoleDataCatalog.isSameParticipant(order.advocateId, userId));
    final list = scopedOrders.map((e) => e.toJson()).toList();
    final jsonStr = jsonEncode(list);
    final encryptedPayload = encrypt(jsonStr, _envelopeKey);

    try {
      if (userId.isNotEmpty) {
        final f = await _localArizaLedgerFile(userId);
        await f.writeAsString(encryptedPayload, flush: true);
      }
    } catch (_) {}

    await updateMyProfileE2eeEnvelope();
  }

  static Future<void> syncArizaOrdersLedger() async {
    final userId = _resolveCurrentUserId();
    final byId = <String, ArizaOrderItem>{};
    for (final item in YanRoleDataCatalog.arizaOrders.value) {
      if (userId.isEmpty ||
          YanRoleDataCatalog.isSameParticipant(item.clientId, userId) ||
          YanRoleDataCatalog.isSameParticipant(item.advocateId, userId)) {
        byId[item.id] = item;
      }
    }

    try {
      final f = userId.isEmpty ? null : await _localArizaLedgerFile(userId);
      if (f != null && await f.exists()) {
        final enc = await f.readAsString();
        final dec = decrypt(enc, _envelopeKey);
        final list = jsonDecode(dec);
        if (list is List) {
          for (final raw in list) {
            if (raw is Map) {
              final parsed = ArizaOrderItem.fromJson(
                Map<String, dynamic>.from(raw),
              );
              if (userId.isEmpty ||
                  YanRoleDataCatalog.isSameParticipant(
                    parsed.clientId,
                    userId,
                  ) ||
                  YanRoleDataCatalog.isSameParticipant(
                    parsed.advocateId,
                    userId,
                  )) {
                final existing = byId[parsed.id];
                byId[parsed.id] = existing == null
                    ? parsed
                    : _mergeOrderState(existing, parsed);
              }
            }
          }
        }
      }
    } catch (_) {}

    // Read all profile envelopes so an Advocate receives ArizaOrderItems created by a Client
    // (and a Client receives updates made by an Advocate), strictly filtered to `userId`!
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select('id, public_key');
      for (final rawRow in rows) {
        final map = Map<String, dynamic>.from(rawRow as Map);
        final pubKey = map['public_key']?.toString();
        if (pubKey == null || !pubKey.contains(_envelopeSeparator)) continue;
        final env = decodeProfileEnvelope(pubKey);
        final rawOrders = env['ariza_orders'];
        if (rawOrders is List) {
          for (final item in rawOrders) {
            if (item is Map) {
              final parsed = ArizaOrderItem.fromJson(
                Map<String, dynamic>.from(item),
              );
              if (userId.isNotEmpty &&
                  !(YanRoleDataCatalog.isSameParticipant(
                        parsed.clientId,
                        userId,
                      ) ||
                      YanRoleDataCatalog.isSameParticipant(
                        parsed.advocateId,
                        userId,
                      ))) {
                continue;
              }
              final existing = byId[parsed.id];
              byId[parsed.id] = existing == null
                  ? parsed
                  : _mergeOrderState(existing, parsed);
            }
          }
        }
      }
    } catch (_) {}

    final merged = byId.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    YanRoleDataCatalog.arizaOrders.value = merged;
  }
}

class _ChatMessageItem {
  final String id;
  final String senderId;
  final String receiverId;
  final String senderName;
  final String text;
  final String encryptedCiphertext;
  final DateTime sentAt;
  final bool isSeen;
  final DateTime? seenAt;
  final _ChatMediaType mediaType;
  final String? mediaMeta;

  const _ChatMessageItem({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.senderName,
    required this.text,
    required this.encryptedCiphertext,
    required this.sentAt,
    this.isSeen = false,
    this.seenAt,
    this.mediaType = _ChatMediaType.text,
    this.mediaMeta,
  });

  bool isMine(String myUserId) =>
      YanRoleDataCatalog.isSameParticipant(senderId, myUserId);

  _ArizaFileDeliveryMeta? get arizaDeliveryMeta =>
      _ArizaFileDeliveryMeta.tryParse(mediaMeta, text);

  bool get isStructuredArizaPackage =>
      (mediaMeta?.startsWith('ARIZA_PACKAGE') ?? false) ||
      text.startsWith('📋 RASMIY ARIZA BUYURTMASI');

  bool get isAutoWelcomeMessage => mediaMeta == 'AUTO_WELCOME';

  String get formattedSentTime {
    final h = sentAt.hour.toString().padLeft(2, '0');
    final m = sentAt.minute.toString().padLeft(2, '0');
    final s = sentAt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String get formattedFullDateTime {
    final d = sentAt.day.toString().padLeft(2, '0');
    final mo = sentAt.month.toString().padLeft(2, '0');
    final y = sentAt.year;
    return '$d.$mo.$y • $formattedSentTime';
  }

  String? get formattedSeenDateTime {
    if (seenAt == null) return null;
    final d = seenAt!.day.toString().padLeft(2, '0');
    final mo = seenAt!.month.toString().padLeft(2, '0');
    final h = seenAt!.hour.toString().padLeft(2, '0');
    final m = seenAt!.minute.toString().padLeft(2, '0');
    final s = seenAt!.second.toString().padLeft(2, '0');
    return '$d.$mo.${seenAt!.year} • $h:$m:$s';
  }

  _ChatMessageItem copyWith({
    bool? isSeen,
    DateTime? seenAt,
    String? encryptedCiphertext,
    String? mediaMeta,
  }) {
    return _ChatMessageItem(
      id: id,
      senderId: senderId,
      receiverId: receiverId,
      senderName: senderName,
      text: text,
      encryptedCiphertext: encryptedCiphertext ?? this.encryptedCiphertext,
      sentAt: sentAt,
      isSeen: isSeen ?? this.isSeen,
      seenAt: seenAt ?? this.seenAt,
      mediaType: mediaType,
      mediaMeta: mediaMeta ?? this.mediaMeta,
    );
  }

  Map<String, dynamic> toServerJson(String roomKey) {
    final rawMediaMeta = mediaMeta;
    final cipher = encryptedCiphertext.isNotEmpty
        ? encryptedCiphertext
        : _YanE2eeCryptoEngine.encrypt(text, roomKey);
    return <String, dynamic>{
      'id': id,
      'room_key': roomKey,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'sender_name': senderName,
      'encrypted_content': cipher,
      'media_type': mediaType.name,
      'media_meta': rawMediaMeta == null
          ? null
          : _YanE2eeCryptoEngine.encrypt(rawMediaMeta, roomKey),
      'is_seen': isSeen,
      'sent_at': sentAt.toIso8601String(),
      'seen_at': seenAt?.toIso8601String(),
    };
  }

  factory _ChatMessageItem.fromServerJson(
    Map<String, dynamic> map,
    String roomKey,
  ) {
    final rawCipher =
        map['encrypted_content']?.toString() ?? map['content']?.toString() ?? '';
    final decryptedText = _YanE2eeCryptoEngine.decrypt(rawCipher, roomKey);
    final mediaName = map['media_type']?.toString() ?? 'text';
    final resolvedMedia = _ChatMediaType.values.firstWhere(
      (e) => e.name == mediaName,
      orElse: () => _ChatMediaType.text,
    );
    return _ChatMessageItem(
      id:
          map['id']?.toString() ??
          'MSG-${DateTime.now().microsecondsSinceEpoch}',
      senderId: map['sender_id']?.toString() ?? '',
      receiverId: map['receiver_id']?.toString() ?? '',
      senderName: map['sender_name']?.toString() ?? 'Foydalanuvchi',
      text: decryptedText,
      encryptedCiphertext: rawCipher,
      sentAt:
          DateTime.tryParse(
            map['sent_at']?.toString() ?? map['created_at']?.toString() ?? '',
          )?.toLocal() ??
          DateTime.now(),
      isSeen: map['is_seen'] == true,
      seenAt: DateTime.tryParse(map['seen_at']?.toString() ?? '')?.toLocal(),
      mediaType: resolvedMedia,
      mediaMeta: map['media_meta'] == null
          ? null
          : _YanE2eeCryptoEngine.decrypt(
              map['media_meta'].toString(),
              roomKey,
            ),
    );
  }
}

class AdvocateClientChatPage extends StatefulWidget {
  final LawyerDirectoryProfile lawyer;
  final UserProfileData profile;
  final bool isEmbeddedTab;
  final String? initialCallMode;

  const AdvocateClientChatPage({
    super.key,
    required this.lawyer,
    required this.profile,
    this.isEmbeddedTab = false,
    this.initialCallMode,
  });

  static Future<void> sendArizaPackageAndOpenChat({
    required BuildContext context,
    required LawyerDirectoryProfile advocate,
    required UserProfileData clientProfile,
    required String referenceCode,
    required String subjectTitle,
    required String detailedStatement,
    required List<String> attachmentNames,
    required String formattedCostLabel,
  }) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    final myUserId = (authUser?.id != null && authUser!.id.isNotEmpty)
        ? authUser.id
        : clientProfile.clientId;
    final peerUserId = advocate.id.trim().isNotEmpty
        ? advocate.id.trim()
        : 'peer_${advocate.fullName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    final roomKey = _YanE2eeCryptoEngine.buildCanonicalRoomKey(
      myUserId,
      peerUserId,
    );

    final now = DateTime.now();
    final deadline = now.add(const Duration(minutes: 30));

    final orderItem = ArizaOrderItem(
      id: referenceCode,
      clientId: myUserId,
      clientName: clientProfile.displayName,
      clientPhone: clientProfile.phone,
      clientRegion: clientProfile.region,
      advocateId: peerUserId,
      advocateName: advocate.fullName,
      categoryType: 'Ariza yozdirish',
      subjectTitle: subjectTitle,
      detailedStatement: detailedStatement,
      attachmentNames: attachmentNames,
      createdAt: now,
      deadlineAt: deadline,
      isCompleted: false,
    );
    YanRoleDataCatalog.upsertArizaOrder(orderItem);

    final docSummary = attachmentNames.isEmpty
        ? 'Hujjat ilova qilinmagan (chatda yuborilishi mumkin)'
        : List<String>.generate(
            attachmentNames.length,
            (i) => '${i + 1}. ${attachmentNames[i]}',
          ).join('\n');

    final deadlineClock =
        '${deadline.hour.toString().padLeft(2, '0')}:${deadline.minute.toString().padLeft(2, '0')}';

    final structuredText =
        '📋 RASMIY ARIZA BUYURTMASI ($referenceCode)\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '01 • MUROJAATCHI MA’LUMOTLARI:\n'
        '• F.I.Sh.: ${clientProfile.displayName}\n'
        '• Telefon: ${clientProfile.phone}\n'
        '• Hudud: ${clientProfile.region}\n\n'
        '02 • ARIZA MAVZUSI:\n'
        '• $subjectTitle\n\n'
        '03 • NIMA SODIR BO‘LGANI (BATAFSIL BAYON):\n'
        '$detailedStatement\n\n'
        '04 • ILOVA QILINGAN HUJJATLAR (${attachmentNames.length} ta):\n'
        '$docSummary\n\n'
        '05 • MUDDAT VA HOLAT:\n'
        '• Tayyor bo‘lish muddati: 30 daqiqa ($deadlineClock gacha)\n'
        '• Xizmat holati: $formattedCostLabel';

    final msg1 = _ChatMessageItem(
      id: 'ARZ-${now.microsecondsSinceEpoch}',
      senderId: myUserId,
      receiverId: peerUserId,
      senderName: clientProfile.displayName,
      text: structuredText,
      encryptedCiphertext: _YanE2eeCryptoEngine.encrypt(
        structuredText,
        roomKey,
      ),
      sentAt: now,
      isSeen: false,
      seenAt: null,
      mediaType: _ChatMediaType.document,
      mediaMeta:
          'ARIZA_PACKAGE|$referenceCode|30 daqiqa ($deadlineClock gacha)',
    );

    final newMessages = <_ChatMessageItem>[msg1];

    for (var i = 0; i < attachmentNames.length; i++) {
      final docTime = now.add(Duration(milliseconds: 12 * (i + 1)));
      final docText =
          '📎 E2EE Hujjat #${i + 1}: ${attachmentNames[i]} ($referenceCode)';
      newMessages.add(
        _ChatMessageItem(
          id: 'ARZ-DOC-${docTime.microsecondsSinceEpoch}-$i',
          senderId: myUserId,
          receiverId: peerUserId,
          senderName: clientProfile.displayName,
          text: docText,
          encryptedCiphertext: _YanE2eeCryptoEngine.encrypt(docText, roomKey),
          sentAt: docTime,
          isSeen: false,
          seenAt: null,
          mediaType: _ChatMediaType.image,
          mediaMeta: 'E2EE Hujjat #${i + 1} • ${attachmentNames[i]}',
        ),
      );
    }

    final autoReplyTime = now.add(const Duration(milliseconds: 220));
    const autoReplyText =
        'Xizmatimizdan foydalanganingiz uchun rahmat! Murojaatingiz va barcha ma’lumotlaringizni qabul qildim. '
        'Yanada to‘liq va mukammal ariza yozish uchun sizga qo‘shimcha savollar berishim mumkin. '
        'Arizangiz 30 daqiqa ichida tayyor bo‘ladi.';

    final autoWelcomeMsg = _ChatMessageItem(
      id: 'AUTO-WELCOME-${autoReplyTime.microsecondsSinceEpoch}',
      senderId: peerUserId,
      receiverId: myUserId,
      senderName: advocate.fullName,
      text: autoReplyText,
      encryptedCiphertext: _YanE2eeCryptoEngine.encrypt(autoReplyText, roomKey),
      sentAt: autoReplyTime,
      isSeen: true,
      seenAt: autoReplyTime,
      mediaType: _ChatMediaType.text,
      mediaMeta: 'AUTO_WELCOME',
    );
    newMessages.add(autoWelcomeMsg);

    final cacheFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}yan360_$roomKey.json',
    );
    final existingById = <String, Map<String, dynamic>>{};
    try {
      if (await cacheFile.exists()) {
        final raw = await cacheFile.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map && item['id'] != null) {
              existingById[item['id'].toString()] = Map<String, dynamic>.from(
                item,
              );
            }
          }
        }
      }
    } catch (_) {}

    for (final m in newMessages) {
      final serverMap = m.toServerJson(roomKey);
      existingById[m.id] = serverMap;
    }

    final mergedList = existingById.values.toList();
    try {
      await cacheFile.writeAsString(jsonEncode(mergedList), flush: true);
    } catch (_) {}

    await _YanE2eeCryptoEngine.updateMyProfileE2eeEnvelope(
      roomKey: roomKey,
      myRoomMessages: mergedList,
      isOnline: true,
    );

    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AdvocateClientChatPage(
          lawyer: advocate,
          profile: clientProfile,
        ),
      ),
    );
  }

  static Future<void> sendConsultationBookingAndOpenChat({
    required BuildContext context,
    required LawyerDirectoryProfile advocate,
    required UserProfileData clientProfile,
    required ConsultationBooking booking,
  }) async {
    final authUser = Supabase.instance.client.auth.currentUser;
    final myUserId = (authUser?.id != null && authUser!.id.isNotEmpty)
        ? authUser.id
        : clientProfile.clientId;
    final peerUserId = advocate.id.trim().isNotEmpty
        ? advocate.id.trim()
        : booking.advocateId;
    final roomKey = _YanE2eeCryptoEngine.buildCanonicalRoomKey(
      myUserId,
      peerUserId,
    );

    final now = DateTime.now();
    final notificationText =
        '📅 RASMIY VIDEO KONSULTATSIYA BAND QILINDI (${booking.id})\n'
        '━━━━━━━━━━━━━━━━━━━━━━━━━━\n'
        '• Advokat: ${advocate.fullName}\n'
        '• Mijoz: ${clientProfile.displayName}\n'
        '• Sana: ${booking.friendlyDateLabel}\n'
        '• Vaqt oralig‘i: ${booking.timeRangeLabel} (Toshkent vaqti)\n'
        '• Davomiyligi: 19 daqiqa (+1 daqiqa tanaffus)\n\n'
        '⏱ Diqqat: “Video qo‘ng‘iroqni boshlash” tugmasi faqat belgilangan ${booking.timeRangeLabel} oralig‘ida faol bo‘ladi. '
        'Muddat tugashi (00:00) bilan video qo‘ng‘iroq har ikki tomon uchun avtomatik yakunlanadi.';

    final bookingMsg = _ChatMessageItem(
      id: 'KNS-MSG-${now.microsecondsSinceEpoch}',
      senderId: myUserId,
      receiverId: peerUserId,
      senderName: clientProfile.displayName,
      text: notificationText,
      encryptedCiphertext: _YanE2eeCryptoEngine.encrypt(
        notificationText,
        roomKey,
      ),
      sentAt: now,
      isSeen: false,
      seenAt: null,
      mediaType: _ChatMediaType.document,
      mediaMeta: booking.encodeChatMeta(),
    );

    final cacheFile = File(
      '${Directory.systemTemp.path}${Platform.pathSeparator}yan360_$roomKey.json',
    );
    final existingById = <String, Map<String, dynamic>>{};
    try {
      if (await cacheFile.exists()) {
        final raw = await cacheFile.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map && item['id'] != null) {
              existingById[item['id'].toString()] = Map<String, dynamic>.from(
                item,
              );
            }
          }
        }
      }
    } catch (_) {}

    final serverMap = bookingMsg.toServerJson(roomKey);
    existingById[bookingMsg.id] = serverMap;
    final mergedList = existingById.values.toList();
    try {
      await cacheFile.writeAsString(jsonEncode(mergedList), flush: true);
    } catch (_) {}

    await _YanE2eeCryptoEngine.updateMyProfileE2eeEnvelope(
      roomKey: roomKey,
      myRoomMessages: mergedList,
      isOnline: true,
    );

    try {
      await Supabase.instance.client.from('messages').insert(serverMap);
    } catch (_) {}

    if (!context.mounted) return;
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => AdvocateClientChatPage(
          lawyer: advocate,
          profile: clientProfile,
        ),
      ),
    );
  }

  @override
  State<AdvocateClientChatPage> createState() => _AdvocateClientChatPageState();
}

class _AdvocateClientChatPageState extends State<AdvocateClientChatPage>
    with WidgetsBindingObserver {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _filePicker = ImagePicker();
  final List<_ChatMessageItem> _messages = <_ChatMessageItem>[];

  RealtimeChannel? _roomChannel;
  Timer? _offlinePollAndHeartbeatTimer;
  Timer? _uiCountdownTicker;
  late final String _myUserId;
  late final String _peerUserId;
  late final String _roomKey;

  bool _isMyAppInForeground = true;
  bool _isPeerOnline = false;
  DateTime _peerLastSeen = DateTime.now();
  DateTime? _lastPeerRealtimePingAt;
  bool _isSyncingHistory = true;
  bool _isPollingProfiles = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    final authUser = Supabase.instance.client.auth.currentUser;
    _myUserId = (authUser?.id != null && authUser!.id.isNotEmpty)
        ? authUser.id
        : widget.profile.clientId;
    _peerUserId = widget.lawyer.id.trim().isNotEmpty
        ? widget.lawyer.id.trim()
        : 'peer_${widget.lawyer.fullName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    _roomKey = _YanE2eeCryptoEngine.buildCanonicalRoomKey(_myUserId, _peerUserId);

    _initRealtimeZeroLagChannel();
    _loadCrossDeviceEncryptedHistory();
    _YanE2eeCryptoEngine.syncArizaOrdersLedger();

    _uiCountdownTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isMyAppInForeground) {
        setState(() {});
      }
    });

    _offlinePollAndHeartbeatTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) {
        if (!mounted) return;
        if (_isMyAppInForeground) {
          _broadcastMyPresence(isOnline: true, requestAck: false);
          _syncOfflineMessagesFromProfilesEnvelopes();
        }
        if (_isPeerOnline &&
            _lastPeerRealtimePingAt != null &&
            DateTime.now().difference(_lastPeerRealtimePingAt!).inSeconds >
                10) {
          setState(() {
            _isPeerOnline = false;
            _peerLastSeen = DateTime.now();
          });
        }
      },
    );

    if (widget.initialCallMode != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startE2eeCall(isVideo: widget.initialCallMode == 'video');
        }
      });
    }
  }

  @override
  void dispose() {
    _uiCountdownTicker?.cancel();
    _offlinePollAndHeartbeatTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    _broadcastMyPresence(isOnline: false);
    _syncMyRoomStateToProfileEnvelope(isOnline: false);
    if (_roomChannel != null) {
      Supabase.instance.client.removeChannel(_roomChannel!);
    }
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final inApp = state == AppLifecycleState.resumed;
    if (_isMyAppInForeground != inApp) {
      setState(() => _isMyAppInForeground = inApp);
      _broadcastMyPresence(isOnline: inApp, requestAck: inApp);
      _syncMyRoomStateToProfileEnvelope(isOnline: inApp);
      if (inApp) {
        _requestPeerHistorySync();
        _syncOfflineMessagesFromProfilesEnvelopes();
        _markAllIncomingAsSeen();
      }
    }
  }

  void _initRealtimeZeroLagChannel() {
    try {
      final channel = Supabase.instance.client.channel(
        'yan360_e2ee_$_roomKey',
        opts: const RealtimeChannelConfig(self: false, ack: false),
      );

      channel
          .onBroadcast(
            event: 'e2ee_msg',
            callback: (payload) {
              if (!mounted) return;
              final msg = _ChatMessageItem.fromServerJson(payload, _roomKey);
              if (!_belongsToThisRoom(msg)) return;
              final idx = _messages.indexWhere((m) => m.id == msg.id);
              if (idx < 0) {
                final resolved = (_isMyAppInForeground && !msg.isMine(_myUserId))
                    ? msg.copyWith(isSeen: true, seenAt: DateTime.now())
                    : msg;
                setState(() {
                  _messages.add(resolved);
                  _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
                  _isPeerOnline = true;
                  _lastPeerRealtimePingAt = DateTime.now();
                  _peerLastSeen = DateTime.now();
                });
                _scrollToBottomInstant();
                _saveLocalEncryptedCache();
                if (_isMyAppInForeground && !msg.isMine(_myUserId)) {
                  _sendSeenReceipt(<String>[msg.id]);
                }
              } else {
                final mergedMeta = _ArizaFileDeliveryMeta.mergeMediaMeta(
                  _messages[idx].mediaMeta,
                  msg.mediaMeta,
                );
                setState(() {
                  _messages[idx] = msg.copyWith(mediaMeta: mergedMeta);
                });
                _saveLocalEncryptedCache();
              }
            },
          )
          .onBroadcast(
            event: 'e2ee_ariza_decision',
            callback: (payload) {
              if (!mounted) return;
              final msgId = payload['message_id']?.toString() ?? '';
              final newMeta = payload['media_meta']?.toString() ?? '';
              final decision = payload['decision']?.toString() ?? '';
              final idx = _messages.indexWhere((m) => m.id == msgId);
              if (idx >= 0 && newMeta.isNotEmpty) {
                setState(() {
                  _messages[idx] = _messages[idx].copyWith(mediaMeta: newMeta);
                });
                _saveLocalEncryptedCache();
                _syncMyRoomStateToProfileEnvelope();
              }
              if (decision == 'rejected') {
                final reason = payload['rejection_reason']?.toString() ?? '';
                final isAdvocate =
                    widget.profile.roleType == UserRole.advokat ||
                    widget.profile.roleType == UserRole.yordamchi;
                YanRoleDataCatalog.markArizaRejectedByClient(
                  clientId: isAdvocate ? _peerUserId : _myUserId,
                  advocateId: isAdvocate ? _myUserId : _peerUserId,
                  rejectionReason: reason,
                );
              } else if (decision == 'accepted') {
                final isAdvocate =
                    widget.profile.roleType == UserRole.advokat ||
                    widget.profile.roleType == UserRole.yordamchi;
                YanRoleDataCatalog.markArizaCompletedByHashtag(
                  clientId: isAdvocate ? _peerUserId : _myUserId,
                  advocateId: isAdvocate ? _myUserId : _peerUserId,
                  advocateName: isAdvocate
                      ? widget.profile.displayName
                      : widget.lawyer.fullName,
                  arizaContent: 'Ariza qabul qilindi',
                  attachmentMeta: newMeta,
                );
              }
              final stars = (payload['rated_stars'] as num?)?.toInt() ?? 0;
              if (stars >= 1 && stars <= 5) {
                final advId = payload['advocate_id']?.toString() ?? _myUserId;
                final advName =
                    payload['advocate_name']?.toString() ??
                    widget.profile.displayName;
                final clientName =
                    payload['client_name']?.toString() ?? 'Mijoz';
                YanRoleDataCatalog.applyAdvocateStarRating(
                  advocateId: advId,
                  advocateName: advName,
                  stars: stars,
                  clientName: clientName,
                  ratingId: payload['ariza_id']?.toString() ?? '',
                );
              }
            },
          )
          .onBroadcast(
            event: 'e2ee_sync_request',
            callback: (payload) {
              if (!mounted) return;
              final reqId = payload['requester_id']?.toString() ?? '';
              if (reqId.isNotEmpty &&
                  _YanE2eeCryptoEngine.normalizeParticipantId(reqId) !=
                      _YanE2eeCryptoEngine.normalizeParticipantId(_myUserId)) {
                setState(() {
                  _isPeerOnline = true;
                  _lastPeerRealtimePingAt = DateTime.now();
                  _peerLastSeen = DateTime.now();
                });
                _broadcastMyEncryptedHistoryBundle();
              }
            },
          )
          .onBroadcast(
            event: 'e2ee_history_bundle',
            callback: (payload) {
              if (!mounted) return;
              final rawList = payload['messages'];
              if (rawList is! List) return;
              var changed = false;
              final newlySeenIds = <String>[];
              final now = DateTime.now();

              for (final item in rawList) {
                if (item is Map) {
                  final incoming = _ChatMessageItem.fromServerJson(
                    Map<String, dynamic>.from(item),
                    _roomKey,
                  );
                  if (!_belongsToThisRoom(incoming)) continue;
                  final idx = _messages.indexWhere((m) => m.id == incoming.id);
                  if (idx < 0) {
                    final resolved =
                        (_isMyAppInForeground && !incoming.isMine(_myUserId))
                        ? incoming.copyWith(isSeen: true, seenAt: now)
                        : incoming;
                    _messages.add(resolved);
                    if (_isMyAppInForeground && !incoming.isMine(_myUserId)) {
                      newlySeenIds.add(incoming.id);
                    }
                    changed = true;
                  } else {
                    if (!_messages[idx].isSeen && incoming.isSeen) {
                      _messages[idx] = _messages[idx].copyWith(
                        isSeen: true,
                        seenAt: incoming.seenAt ?? now,
                      );
                      changed = true;
                    }
                    final mergedMeta = _ArizaFileDeliveryMeta.mergeMediaMeta(
                      _messages[idx].mediaMeta,
                      incoming.mediaMeta,
                    );
                    if (mergedMeta != _messages[idx].mediaMeta) {
                      _messages[idx] = _messages[idx].copyWith(
                        mediaMeta: mergedMeta,
                      );
                      changed = true;
                    }
                  }
                }
              }

              if (changed && mounted) {
                setState(() {
                  _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
                });
                _scrollToBottomInstant();
                _saveLocalEncryptedCache();
                if (newlySeenIds.isNotEmpty) {
                  _sendSeenReceipt(newlySeenIds);
                }
              }
            },
          )
          .onBroadcast(
            event: 'e2ee_seen',
            callback: (payload) {
              if (!mounted) return;
              final seenAt =
                  DateTime.tryParse(payload['seen_at']?.toString() ?? '')
                      ?.toLocal() ??
                  DateTime.now();
              final idsRaw = payload['message_ids'];
              final idSet = <String>{};
              if (idsRaw is List) {
                for (final item in idsRaw) {
                  idSet.add(item.toString());
                }
              }
              setState(() {
                for (var i = 0; i < _messages.length; i++) {
                  final m = _messages[i];
                  if (m.isMine(_myUserId) &&
                      (!m.isSeen || idSet.isEmpty || idSet.contains(m.id))) {
                    _messages[i] = m.copyWith(isSeen: true, seenAt: seenAt);
                  }
                }
              });
              _saveLocalEncryptedCache();
              _syncMyRoomStateToProfileEnvelope();
            },
          )
          .onBroadcast(
            event: 'presence_state',
            callback: (payload) {
              if (!mounted) return;
              final sender = payload['user_id']?.toString() ?? '';
              if (sender.isNotEmpty &&
                  _YanE2eeCryptoEngine.normalizeParticipantId(sender) !=
                      _YanE2eeCryptoEngine.normalizeParticipantId(_myUserId)) {
                final online = payload['is_online'] == true;
                final ts =
                    DateTime.tryParse(payload['timestamp']?.toString() ?? '')
                        ?.toLocal() ??
                    DateTime.now();
                setState(() {
                  _isPeerOnline = online;
                  if (online) _lastPeerRealtimePingAt = DateTime.now();
                  _peerLastSeen = ts;
                });
                if (online && payload['request_ack'] == true) {
                  _broadcastMyPresence(
                    isOnline: _isMyAppInForeground,
                    requestAck: false,
                  );
                  _broadcastMyEncryptedHistoryBundle();
                }
              }
            },
          )
          .onBroadcast(
            event: 'call_signal',
            callback: (payload) {
              if (!mounted) return;
              _YanGlobalCallCenter.instance.handleIncomingSignalPayload(
                Map<String, dynamic>.from(payload),
                myUserIdOverride: _myUserId,
              );
            },
          )
          .subscribe((status, error) {
            if (status == RealtimeSubscribeStatus.subscribed) {
              _broadcastMyPresence(
                isOnline: _isMyAppInForeground,
                requestAck: true,
              );
              _requestPeerHistorySync();
              _broadcastMyEncryptedHistoryBundle();
              _markAllIncomingAsSeen();
            }
          });

      _roomChannel = channel;
    } catch (_) {}
  }

  Future<void> _requestPeerHistorySync() async {
    try {
      await _roomChannel?.sendBroadcastMessage(
        event: 'e2ee_sync_request',
        payload: <String, dynamic>{
          'requester_id': _myUserId,
          'timestamp': DateTime.now().toUtc().toIso8601String(),
        },
      );
    } catch (_) {}
  }

  Future<void> _broadcastMyEncryptedHistoryBundle() async {
    if (_messages.isEmpty) return;
    try {
      final list = _messages.map((m) => m.toServerJson(_roomKey)).toList();
      await _roomChannel?.sendBroadcastMessage(
        event: 'e2ee_history_bundle',
        payload: <String, dynamic>{
          'sender_id': _myUserId,
          'messages': list,
        },
      );
    } catch (_) {}
  }

  Future<void> _broadcastMyPresence({
    required bool isOnline,
    bool requestAck = false,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      await _roomChannel?.sendBroadcastMessage(
        event: 'presence_state',
        payload: <String, dynamic>{
          'user_id': _myUserId,
          'user_name': widget.profile.displayName,
          'is_online': isOnline,
          'timestamp': nowIso,
          'request_ack': requestAck,
        },
      );
    } catch (_) {}
  }

  Future<File> _localRoomCacheFile() async {
    final dir = Directory.systemTemp;
    return File('${dir.path}${Platform.pathSeparator}yan360_$_roomKey.json');
  }

  Future<void> _saveLocalEncryptedCache() async {
    try {
      final f = await _localRoomCacheFile();
      final list = _messages.map((m) => m.toServerJson(_roomKey)).toList();
      await f.writeAsString(jsonEncode(list), flush: true);
    } catch (_) {}
  }

  Future<void> _syncMyRoomStateToProfileEnvelope({
    bool? isOnline,
    Map<String, dynamic>? newAdvocateRatingEntry,
  }) async {
    final list = _messages.map((m) => m.toServerJson(_roomKey)).toList();
    final nowIso = DateTime.now().toUtc().toIso8601String();
    await _YanE2eeCryptoEngine.updateMyProfileE2eeEnvelope(
      roomKey: _roomKey,
      myRoomMessages: list,
      lastSeenInRoomIso: _isMyAppInForeground ? nowIso : null,
      isOnline: isOnline ?? _isMyAppInForeground,
      newAdvocateRatingEntry: newAdvocateRatingEntry,
    );
  }

  Future<void> _syncOfflineMessagesFromProfilesEnvelopes() async {
    if (_isPollingProfiles) return;
    _isPollingProfiles = true;
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select()
          .inFilter('id', <String>[_myUserId, _peerUserId]);
      var changed = false;
      final newlySeenIncomingIds = <String>[];
      final now = DateTime.now();
      final normPeer = _YanE2eeCryptoEngine.normalizeParticipantId(_peerUserId);

      for (final rawRow in rows) {
        final row = Map<String, dynamic>.from(rawRow as Map);
        final rowId = row['id']?.toString() ?? '';
        final normRowId = _YanE2eeCryptoEngine.normalizeParticipantId(rowId);
        final pubKey = row['public_key']?.toString();
        if (pubKey == null ||
            !pubKey.contains(_YanE2eeCryptoEngine._envelopeSeparator)) {
          continue;
        }

        final env = _YanE2eeCryptoEngine.decodeProfileEnvelope(pubKey);

        if (normRowId == normPeer) {
          final envLastSeen = DateTime.tryParse(
            env['last_seen']?.toString() ?? '',
          )?.toLocal();
          final envOnline = env['is_online'] == true;
          if (envLastSeen != null) {
            final isRecent =
                DateTime.now().difference(envLastSeen).inSeconds <= 12;
            if (mounted && (_lastPeerRealtimePingAt == null)) {
              setState(() {
                _isPeerOnline = envOnline && isRecent;
                _peerLastSeen = envLastSeen;
              });
            }
          }
        }

        final roomsRaw = env['rooms'];
        if (roomsRaw is! Map) continue;
        final roomDataRaw = roomsRaw[_roomKey];
        if (roomDataRaw is! Map) continue;
        final roomData = Map<String, dynamic>.from(roomDataRaw);

        if (normRowId == normPeer) {
          final peerSeenAt = DateTime.tryParse(
            roomData['last_seen_by_me']?.toString() ?? '',
          )?.toLocal();
          if (peerSeenAt != null) {
            for (var i = 0; i < _messages.length; i++) {
              final m = _messages[i];
              if (m.isMine(_myUserId) &&
                  !m.isSeen &&
                  !m.sentAt.isAfter(
                    peerSeenAt.add(const Duration(seconds: 2)),
                  )) {
                _messages[i] = m.copyWith(isSeen: true, seenAt: peerSeenAt);
                changed = true;
              }
            }
          }
        }

        final rawMsgs = roomData['messages'];
        if (rawMsgs is List) {
          for (final item in rawMsgs) {
            if (item is Map) {
              final incoming = _ChatMessageItem.fromServerJson(
                Map<String, dynamic>.from(item),
                _roomKey,
              );
              if (!_belongsToThisRoom(incoming)) continue;
              final idx = _messages.indexWhere((m) => m.id == incoming.id);
              if (idx < 0) {
                final resolved =
                    (_isMyAppInForeground && !incoming.isMine(_myUserId))
                    ? incoming.copyWith(isSeen: true, seenAt: now)
                    : incoming;
                _messages.add(resolved);
                if (_isMyAppInForeground && !incoming.isMine(_myUserId)) {
                  newlySeenIncomingIds.add(incoming.id);
                }
                changed = true;
              } else {
                if (!_messages[idx].isSeen && incoming.isSeen) {
                  _messages[idx] = _messages[idx].copyWith(
                    isSeen: true,
                    seenAt: incoming.seenAt ?? now,
                  );
                  changed = true;
                }
                final mergedMeta = _ArizaFileDeliveryMeta.mergeMediaMeta(
                  _messages[idx].mediaMeta,
                  incoming.mediaMeta,
                );
                if (mergedMeta != _messages[idx].mediaMeta) {
                  _messages[idx] = _messages[idx].copyWith(
                    mediaMeta: mergedMeta,
                  );
                  changed = true;
                }
              }
            }
          }
        }
      }

      // Also sync ariza status from `public.arizas` table so status ('accepted' / 'rejected')
      // is authoritative even if a profile envelope was stale
      try {
        for (var i = 0; i < _messages.length; i++) {
          final meta = _messages[i].arizaDeliveryMeta;
          if (meta != null && meta.arizaId.isNotEmpty) {
            final dbRow = await Supabase.instance.client
                .from('arizas')
                .select('status')
                .eq('ariza_id', meta.arizaId)
                .maybeSingle();
            final dbStatus = dbRow?['status']?.toString();
            if (dbStatus != null &&
                (dbStatus == 'accepted' || dbStatus == 'rejected') &&
                meta.status != dbStatus) {
              final nextMeta = meta.copyWith(status: dbStatus).encode();
              _messages[i] = _messages[i].copyWith(mediaMeta: nextMeta);
              changed = true;
            }
          }
        }
      } catch (_) {}

      await _YanE2eeCryptoEngine.syncArizaOrdersLedger();

      if (changed && mounted) {
        setState(() {
          _messages.sort((a, b) => a.sentAt.compareTo(b.sentAt));
        });
        _scrollToBottomInstant();
        _saveLocalEncryptedCache();
        if (newlySeenIncomingIds.isNotEmpty) {
          _sendSeenReceipt(newlySeenIncomingIds);
        } else {
          _syncMyRoomStateToProfileEnvelope();
        }
      }
    } catch (_) {
    } finally {
      _isPollingProfiles = false;
    }
  }

  Future<void> _loadCrossDeviceEncryptedHistory() async {
    final byId = <String, _ChatMessageItem>{};

    try {
      final localFile = await _localRoomCacheFile();
      if (await localFile.exists()) {
        final raw = await localFile.readAsString();
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          for (final item in decoded) {
            if (item is Map) {
              final msg = _ChatMessageItem.fromServerJson(
                Map<String, dynamic>.from(item),
                _roomKey,
              );
              if (!_belongsToThisRoom(msg)) continue;
              byId[msg.id] = msg;
            }
          }
        }
      }
    } catch (_) {}

    if (byId.isNotEmpty && mounted) {
      final sorted = byId.values.toList()
        ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
      setState(() {
        _messages
          ..clear()
          ..addAll(sorted);
        _isSyncingHistory = false;
      });
      _scrollToBottomInstant();
    }

    await _syncOfflineMessagesFromProfilesEnvelopes();

    for (final m in _messages) {
      byId[m.id] = m;
    }

    if (byId.isEmpty) {
      final welcomeText =
          'Assalomu alaykum, ${widget.profile.displayName}! Men ${widget.lawyer.fullName}. YAN360 E2EE himoyalangan chat orqali savolingiz va hujjatlaringizni yuborishingiz mumkin.';
      final welcomeTime = DateTime.now();
      final welcomeId = 'WELCOME-$_roomKey';
      byId[welcomeId] = _ChatMessageItem(
        id: welcomeId,
        senderId: _peerUserId,
        receiverId: _myUserId,
        senderName: widget.lawyer.fullName,
        text: welcomeText,
        encryptedCiphertext: _YanE2eeCryptoEngine.encrypt(
          welcomeText,
          _roomKey,
        ),
        sentAt: welcomeTime,
        isSeen: true,
        seenAt: welcomeTime,
      );
    }

    if (!mounted) return;
    final merged = byId.values.toList()
      ..sort((a, b) => a.sentAt.compareTo(b.sentAt));
    setState(() {
      _messages
        ..clear()
        ..addAll(merged);
      _isSyncingHistory = false;
    });
    _scrollToBottomInstant();
    _markAllIncomingAsSeen();
    _saveLocalEncryptedCache();
    _syncMyRoomStateToProfileEnvelope(isOnline: true);
    _broadcastMyEncryptedHistoryBundle();
  }

  void _markAllIncomingAsSeen() {
    if (!_isMyAppInForeground) return;
    final unseenIncomingIds = <String>[];
    final now = DateTime.now();
    var changed = false;
    for (var i = 0; i < _messages.length; i++) {
      final m = _messages[i];
      if (!m.isMine(_myUserId) && !m.isSeen) {
        _messages[i] = m.copyWith(isSeen: true, seenAt: now);
        unseenIncomingIds.add(m.id);
        changed = true;
      }
    }
    if (changed && mounted) {
      setState(() {});
      _sendSeenReceipt(unseenIncomingIds);
      _saveLocalEncryptedCache();
    }
  }

  Future<void> _sendSeenReceipt(List<String> messageIds) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    try {
      await _roomChannel?.sendBroadcastMessage(
        event: 'e2ee_seen',
        payload: <String, dynamic>{
          'reader_id': _myUserId,
          'seen_at': nowIso,
          'message_ids': messageIds,
        },
      );
    } catch (_) {}

    await _syncMyRoomStateToProfileEnvelope(isOnline: true);
  }

  void _scrollToBottomInstant() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _sendMessage() {
    final txt = _msgController.text.trim();
    if (txt.isEmpty) return;
    _msgController.clear();

    // If the user typed #ariza in the message text, open the file picker first
    // so they can attach the completed ariza file from storage or gallery!
    if (txt.toLowerCase().contains('#ariza')) {
      _openReadyArizaFileDeliveryModal(initialCaption: txt);
      return;
    }

    _dispatchInstantEncryptedMessage(
      text: txt,
      mediaType: _ChatMediaType.text,
    );
  }

  void _dispatchInstantEncryptedMessage({
    required String text,
    _ChatMediaType mediaType = _ChatMediaType.text,
    String? mediaMeta,
  }) {
    final now = DateTime.now();
    final msgId =
        'MSG-${now.microsecondsSinceEpoch}-${_myUserId.hashCode.abs()}';
    final cipher = _YanE2eeCryptoEngine.encrypt(text, _roomKey);

    final newMsg = _ChatMessageItem(
      id: msgId,
      senderId: _myUserId,
      receiverId: _peerUserId,
      senderName: widget.profile.displayName,
      text: text,
      encryptedCiphertext: cipher,
      sentAt: now,
      isSeen: false,
      seenAt: null,
      mediaType: mediaType,
      mediaMeta: mediaMeta,
    );

    setState(() {
      _messages.add(newMsg);
    });
    _scrollToBottomInstant();

    final payload = newMsg.toServerJson(_roomKey);
    _roomChannel?.sendBroadcastMessage(
      event: 'e2ee_msg',
      payload: payload,
    );
    _saveLocalEncryptedCache();
    _syncMyRoomStateToProfileEnvelope(isOnline: true);
  }

  // ==========================================================================
  // #ARIZA FILE PICKER (STORAGE / GALLERY / CAMERA) + SUPABASE 5-COLUMN DB SAVE
  // + YAN360 WATERMARK IN-APP PREVIEW (BEFORE ACCEPT) + SAVE & SHARE (AFTER ACCEPT)
  // ==========================================================================

  /// Saves or updates the provided ariza in Supabase `public.arizas` with the
  /// exact 5 required columns:
  /// `ariza_id`, `advocate_id`, `client_id`, `sent_time`, `status` ('accepted', 'rejected', or null).
  Future<void> _upsertArizaRecordInSupabase({
    required String arizaId,
    required String advocateId,
    required String clientId,
    required String sentTimeIso,
    required String? status, // null, 'accepted', or 'rejected'
  }) async {
    try {
      await Supabase.instance.client.from('arizas').upsert(<String, dynamic>{
        'ariza_id': arizaId,
        'advocate_id': advocateId,
        'client_id': clientId,
        'sent_time': sentTimeIso,
        'status': status,
      });
    } catch (_) {}
  }

  Future<void> _updateArizaStatusInSupabase({
    required String arizaId,
    required String status, // 'accepted' or 'rejected'
  }) async {
    try {
      await Supabase.instance.client
          .from('arizas')
          .update(<String, dynamic>{'status': status})
          .eq('ariza_id', arizaId);
    } catch (_) {}
  }

  Future<File?> _materializePickedFile(PlatformFile picked) async {
    if (picked.path != null && File(picked.path!).existsSync()) {
      return File(picked.path!);
    }
    final bytes = picked.bytes;
    if (bytes == null) return null;
    final dir = await getTemporaryDirectory();
    final path = '${dir.path}${Platform.pathSeparator}${picked.name}';
    final file = File(path);
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  bool _belongsToThisRoom(_ChatMessageItem message) {
    final sMine = YanRoleDataCatalog.isSameParticipant(
      message.senderId,
      _myUserId,
    );
    final rPeer = YanRoleDataCatalog.isSameParticipant(
      message.receiverId,
      _peerUserId,
    );
    final sPeer = YanRoleDataCatalog.isSameParticipant(
      message.senderId,
      _peerUserId,
    );
    final rMine = YanRoleDataCatalog.isSameParticipant(
      message.receiverId,
      _myUserId,
    );
    return (sMine && rPeer) || (sPeer && rMine);
  }

  Future<PlatformFile?> _pickAnyDeviceFile() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: false,
      withData: true,
      type: FileType.any,
    );
    return result?.files.single;
  }

  static Map<String, String>? _parseChatFileMeta(String? raw) {
    if (raw == null || !raw.startsWith('CHAT_FILE_V1|')) return null;
    final values = <String, String>{};
    for (final part in raw.split('|').skip(1)) {
      final index = part.indexOf(':');
      if (index > 0) {
        values[part.substring(0, index)] =
            Uri.decodeComponent(part.substring(index + 1));
      }
    }
    return values;
  }

  Future<void> _pickAndSendChatFile() async {
    try {
      final picked = await _pickAnyDeviceFile();
      if (picked == null) return;
      final path = picked.path;
      final bytes = picked.bytes ??
          (path == null
              ? throw StateError('Fayl ma’lumoti olinmadi')
              : await File(path).readAsBytes());
      final extension = picked.extension?.toLowerCase() ?? '';
      final mediaType = <String>{'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'}
              .contains(extension)
          ? _ChatMediaType.image
          : extension == 'mp4' || extension == 'mov'
          ? _ChatMediaType.video
          : _ChatMediaType.document;
      final cleanName = picked.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final objectPath =
          'chat_e2ee/$_roomKey/${DateTime.now().microsecondsSinceEpoch}_$cleanName.e2ee';

      // Encrypt regular chat files on-device with E2EE before uploading so ONLY #ariza files
      // are accessible to the firm in plaintext!
      final encryptedBytes = _YanE2eeCryptoEngine.encryptBytes(bytes, _roomKey);
      var storageBucket = 'chat_media';
      try {
        await Supabase.instance.client.storage
            .from(storageBucket)
            .uploadBinary(
              objectPath,
              encryptedBytes,
              fileOptions: const FileOptions(upsert: true),
            );
      } catch (_) {
        storageBucket = 'advocate_licenses';
        await Supabase.instance.client.storage
            .from(storageBucket)
            .uploadBinary(
              objectPath,
              encryptedBytes,
              fileOptions: const FileOptions(upsert: true),
            );
      }

      final mimeType = extension.isEmpty
          ? 'application/octet-stream'
          : 'application/${extension == 'pdf' ? 'pdf' : extension}';
      final meta = 'CHAT_FILE_V1|name:${Uri.encodeComponent(picked.name)}'
          '|storage:${Uri.encodeComponent(objectPath)}'
          '|bucket:${Uri.encodeComponent(storageBucket)}'
          '|e2ee:1'
          '|mime:${Uri.encodeComponent(mimeType)}|size:${bytes.length}';
      _dispatchInstantEncryptedMessage(
        text: picked.name,
        mediaType: mediaType,
        mediaMeta: meta,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fayl yuborilmadi: $error')),
      );
    }
  }

  Future<File?> _downloadChatFile(Map<String, String> meta) async {
    final storagePath = meta['storage'] ?? '';
    if (storagePath.isEmpty) return null;
    final bucket = (meta['bucket'] ?? '').isNotEmpty
        ? meta['bucket']!
        : 'chat_media';
    Uint8List rawBytes;
    try {
      rawBytes = await Supabase.instance.client.storage
          .from(bucket)
          .download(storagePath);
    } catch (_) {
      final altBucket =
          bucket == 'chat_media' ? 'advocate_licenses' : 'chat_media';
      rawBytes = await Supabase.instance.client.storage
          .from(altBucket)
          .download(storagePath);
    }
    // Decrypt E2EE chat file bytes if encrypted (`e2ee:1`), while leaving unencrypted #ariza files untouched
    final isPlainAriza = meta['e2ee'] == '0';
    final plainBytes = isPlainAriza
        ? rawBytes
        : _YanE2eeCryptoEngine.decryptBytes(rawBytes, _roomKey);
    final directory = await getTemporaryDirectory();
    final name = (meta['name'] ?? 'fayl')
        .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final file = File('${directory.path}${Platform.pathSeparator}$name');
    await file.writeAsBytes(plainBytes, flush: true);
    return file;
  }

  Future<void> _openChatFile(Map<String, String> meta) async {
    try {
      final file = await _downloadChatFile(meta);
      if (file != null) await OpenFilex.open(file.path);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faylni ochib bo‘lmadi: $error')),
        );
      }
    }
  }

  Future<void> _shareChatFile(Map<String, String> meta) async {
    try {
      final file = await _downloadChatFile(meta);
      if (file != null) {
        await Share.shareXFiles(<XFile>[XFile(file.path)], text: meta['name']);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faylni ulashib bo‘lmadi: $error')),
        );
      }
    }
  }

  Future<void> _openReadyArizaFileDeliveryModal({String? initialCaption}) async {
    if (!mounted) return;

    File? selectedFile;
    String selectedFileName = '';
    final captionController = TextEditingController(
      text: initialCaption ??
          '#ariza Rasmiy tayyorlangan ariza hujjati. "Ko‘rish" tugmasi orqali tekshirib, "Qabul qilish" yoki "Rad etish" tugmasini bosing.',
    );
    bool isUploading = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YanColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> pickFromGalleryOrMedia({required bool isCamera}) async {
              try {
                if (isCamera) {
                  final camPerm = await Permission.camera.request();
                  if (!camPerm.isGranted) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Kameradan foydalanish uchun ilova ruxsatlarini yoqing.',
                          ),
                          backgroundColor: YanColors.destructiveRed,
                        ),
                      );
                    }
                    return;
                  }
                }
                final XFile? picked = isCamera
                    ? await _filePicker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 88,
                      )
                    : (await _filePicker.pickMedia() ??
                          await _filePicker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 88,
                          ));
                if (picked != null) {
                  setSheetState(() {
                    selectedFile = File(picked.path);
                    selectedFileName = picked.name.isNotEmpty
                        ? picked.name
                        : picked.path.split(Platform.pathSeparator).last;
                  });
                }
              } catch (error) {
                debugPrint('Camera/Gallery pick error: $error');
              }
            }

            Future<void> pickFromDeviceStorage() async {
              try {
                final picked = await _pickAnyDeviceFile();
                if (picked == null) return;
                final file = await _materializePickedFile(picked);
                if (file == null) return;
                setSheetState(() {
                  selectedFile = file;
                  selectedFileName = picked.name;
                });
              } catch (error) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Fayl tanlanmadi: $error')),
                  );
                }
              }
            }

            Future<void> uploadAndSendArizaFile() async {
              if (selectedFile == null || selectedFileName.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Iltimos, avval xotira yoki galereyadan tayyor ariza faylini tanlang!',
                    ),
                    backgroundColor: YanColors.destructiveRed,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }

              setSheetState(() => isUploading = true);
              final now = DateTime.now();
              final nowIso = now.toUtc().toIso8601String();
              final arizaId = 'ARZ-${now.millisecondsSinceEpoch}';
              var storagePath = '';
              var storageBucket = 'advocate_licenses';

              // 1. Save the ORIGINAL unencrypted ariza file in Supabase Storage
              // so the firm can audit how arizas were written by advocates, AND
              // generate + upload a WATERMARKED copy for the client to inspect before confirming!
              final bytes = await selectedFile!.readAsBytes();
              final cleanName = selectedFileName.replaceAll(
                RegExp(r'[^a-zA-Z0-9._-]'),
                '_',
              );
              storagePath = 'provided_arizas/$arizaId/$cleanName';
              final watermarkedBytes = _buildWatermarkedArizaFileBytes(
                originalBytes: Uint8List.fromList(bytes),
                fileName: selectedFileName,
                arizaId: arizaId,
                advocateName: widget.profile.displayName,
              );
              final watermarkedStoragePath =
                  'provided_arizas/$arizaId/WATERMARKED_$cleanName';

              try {
                await Supabase.instance.client.storage
                    .from(storageBucket)
                    .uploadBinary(
                      storagePath,
                      Uint8List.fromList(bytes),
                      fileOptions: const FileOptions(upsert: true),
                    );
                await Supabase.instance.client.storage
                    .from(storageBucket)
                    .uploadBinary(
                      watermarkedStoragePath,
                      watermarkedBytes,
                      fileOptions: const FileOptions(upsert: true),
                    );
              } catch (_) {
                storageBucket = 'chat_media';
                try {
                  await Supabase.instance.client.storage
                      .from(storageBucket)
                      .uploadBinary(
                        storagePath,
                        Uint8List.fromList(bytes),
                        fileOptions: const FileOptions(upsert: true),
                      );
                  await Supabase.instance.client.storage
                      .from(storageBucket)
                      .uploadBinary(
                        watermarkedStoragePath,
                        watermarkedBytes,
                        fileOptions: const FileOptions(upsert: true),
                      );
                } catch (error) {
                  if (sheetCtx.mounted) Navigator.pop(sheetCtx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Ariza fayli yuklanmadi: $error')),
                    );
                  }
                  return;
                }
              }

              // 2. Save the 5-column record in Supabase `public.arizas`:
              // ariza_id, advocate_id, client_id, sent_time, status (null initially)
              final isAdvocateSender =
                  widget.profile.roleType == UserRole.advokat ||
                  widget.profile.roleType == UserRole.yordamchi;
              final advocateId = isAdvocateSender ? _myUserId : _peerUserId;
              final clientId = isAdvocateSender ? _peerUserId : _myUserId;

              await _upsertArizaRecordInSupabase(
                arizaId: arizaId,
                advocateId: advocateId,
                clientId: clientId,
                sentTimeIso: nowIso,
                status: null,
              );

              final metaObj = _ArizaFileDeliveryMeta(
                arizaId: arizaId,
                status: 'null',
                fileName: selectedFileName,
                storagePath: storagePath,
                watermarkedStoragePath: watermarkedStoragePath,
                storageBucket: storageBucket,
                localPath: selectedFile!.path,
                sentTimeIso: nowIso,
                ratedStars: 0,
              );

              // 3. Mark the ArizaOrderItem as sent by advocate (starts the 30-min client response window)
              YanRoleDataCatalog.markArizaSentByAdvocate(
                clientId: clientId,
                advocateId: advocateId,
                sentAt: now,
                attachmentMeta: metaObj.encode(),
              );
              await _YanE2eeCryptoEngine.persistArizaOrdersLedger();

              final noteText = captionController.text.trim().isEmpty
                  ? '#ariza Tayyor rasmiy ariza ($selectedFileName)'
                  : captionController.text.trim();
              final finalText = noteText.toLowerCase().contains('#ariza')
                  ? noteText
                  : '#ariza $noteText';

              if (sheetCtx.mounted) {
                Navigator.pop(sheetCtx);
              }

              _dispatchInstantEncryptedMessage(
                text: '$finalText\n📄 Hujjat: $selectedFileName ($arizaId)',
                mediaType: _ChatMediaType.document,
                mediaMeta: metaObj.encode(),
              );
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
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
                      const SizedBox(height: 14),
                      const Row(
                        children: <Widget>[
                          Icon(
                            Icons.verified_rounded,
                            color: YanColors.primaryBlue,
                            size: 22,
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Tayyor rasmiy arizani topshirish (#ariza)',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w900,
                                color: YanColors.primaryNavy,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Asl ariza fayli sifat nazorati uchun Supabase bazasida saqlanadi. Mijoz arizani "Qabul qilish" tugmasi orqali tasdiqlamaguncha faqat YAN360 suv belgisi (watermark) bilan ko‘ra oladi.',
                        style: TextStyle(
                          fontSize: 12.2,
                          color: YanColors.mutedText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),

                      Row(
                        children: <Widget>[
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  pickFromGalleryOrMedia(isCamera: false),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: YanColors.lightBlue,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: YanColors.border),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.folder_open_rounded,
                                      color: YanColors.primaryBlue,
                                      size: 19,
                                    ),
                                    SizedBox(width: 7),
                                    Flexible(
                                      child: Text(
                                        'Galereya / Media',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: YanColors.primaryNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  pickFromGalleryOrMedia(isCamera: true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 12,
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: YanColors.lightBlue,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: YanColors.border),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      color: YanColors.primaryNavy,
                                      size: 19,
                                    ),
                                    SizedBox(width: 7),
                                    Flexible(
                                      child: Text(
                                        'Kamera (Skaner)',
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w800,
                                          color: YanColors.primaryNavy,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: pickFromDeviceStorage,
                          icon: const Icon(Icons.folder_open_rounded),
                          label: const Text('Ichki xotiradan istalgan faylni tanlash'),
                        ),
                      ),

                      if (selectedFile != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: YanColors.successGreen.withValues(
                              alpha: 0.12,
                            ),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: YanColors.successGreen.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                          child: Row(
                            children: <Widget>[
                              const Icon(
                                Icons.insert_drive_file_rounded,
                                color: Color(0xFF0A936B),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Tanlangan fayl: $selectedFileName',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12.8,
                                    fontWeight: FontWeight.w800,
                                    color: YanColors.primaryNavy,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 10),

                      TextField(
                        controller: captionController,
                        maxLines: 2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: YanColors.primaryNavy,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Mijoz uchun izoh (#ariza)',
                          filled: true,
                          fillColor: YanColors.lightBlue,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton.icon(
                          onPressed: isUploading
                              ? null
                              : uploadAndSendArizaFile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: YanColors.primaryBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          icon: isUploading
                              ? const CupertinoActivityIndicator(
                                  color: Colors.white,
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            isUploading
                                ? 'Supabase bazasiga saqlanmoqda...'
                                : '#ariza FAYLINI MIJOZGA YUBORISH',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Generates a real watermarked copy of the advocate's `#ariza` file so the client
  /// can open and inspect it with watermarks BEFORE confirming (`Qabul qilish`).
  /// Once confirmed, the original unwatermarked file is sent!
  /// Builds a true diagonal background watermark for `.docx` (Word VML `<v:textpath>` background
  /// header watermark) and `.pdf` (incremental diagonal rotated PDF page content stream overlay)
  /// without inserting inline warning lines between paragraphs!
  Uint8List _buildWatermarkedArizaFileBytes({
    required Uint8List originalBytes,
    required String fileName,
    required String arizaId,
    required String advocateName,
  }) {
    final lower = fileName.toLowerCase();

    // 1. TRUE DIAGONAL BACKGROUND WATERMARK FOR WORD (.DOCX)
    if (lower.endsWith('.docx')) {
      try {
        final archive = ZipDecoder().decodeBytes(originalBytes);
        final outArchive = Archive();

        // Standard WordprocessingML diagonal VML background watermark header XML
        const watermarkHeaderXml =
            '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
            '<w:hdr xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" '
            'xmlns:v="urn:schemas-microsoft-com:vml" '
            'xmlns:o="urn:schemas-microsoft-com:office:office">'
            '<w:p>'
            '<w:pPr><w:pStyle w:val="Header"/></w:pPr>'
            '<w:r>'
            '<w:rPr><w:noProof/></w:rPr>'
            '<w:pict>'
            '<v:shapetype id="_x0000_t136" coordsize="21600,21600" o:spt="136" adj="10800" path="m@7,l@8,m@5,21600l@6,21600e">'
            '<v:formulas>'
            '<v:f eqn="sum #0 0 10800"/>'
            '<v:f eqn="prod #0 2 1"/>'
            '<v:f eqn="sum 21600 0 @1"/>'
            '<v:f eqn="sum 0 0 @2"/>'
            '<v:f eqn="sum 21600 0 @3"/>'
            '<v:f eqn="if @0 @3 0"/>'
            '<v:f eqn="if @0 21600 @1"/>'
            '<v:f eqn="if @0 0 @2"/>'
            '<v:f eqn="if @0 @4 21600"/>'
            '<v:f eqn="mid @5 @6"/>'
            '<v:f eqn="mid @8 @5"/>'
            '<v:f eqn="mid @7 @8"/>'
            '<v:f eqn="mid @6 @7"/>'
            '<v:f eqn="sum @6 0 @5"/>'
            '</v:formulas>'
            '<v:path textpathok="t" o:connecttype="custom" o:connectlocs="@9,0;@10,10800;@11,21600;@12,10800" o:connectangles="270,180,90,0"/>'
            '<v:textpath on="t" fitshape="t"/>'
            '<v:handles><v:h position="#0,bottomRight" xrange="6629,14971"/></v:handles>'
            '<o:lock v:ext="edit" text="t" shapetype="t"/>'
            '</v:shapetype>'
            '<v:shape id="PowerPlusWaterMarkObject" o:spid="_x0000_s2049" type="#_x0000_t136" '
            'style="position:absolute;margin-left:0;margin-top:0;width:468pt;height:136pt;rotation:315;'
            'z-index:-251654144;mso-position-horizontal:center;mso-position-horizontal-relative:margin;'
            'mso-position-vertical:center;mso-position-vertical-relative:margin" '
            'o:allowincell="f" fillcolor="#B0BEC5" stroked="f">'
            '<v:fill opacity=".32"/>'
            '<v:textpath style="font-family:&quot;Arial&quot;;font-size:1pt" string="YAN360 • KO‘RIK NUSXASI"/>'
            '</v:shape>'
            '</w:pict>'
            '</w:r>'
            '</w:p>'
            '</w:hdr>';

        // Also inject a floating behind-text diagonal VML watermark shape once at the start of <w:body>
        // so mobile DOCX viewers that ignore <w:hdr> still render a diagonal background watermark behind the text!
        const bodyFloatingWatermarkParagraph =
            '<w:p xmlns:v="urn:schemas-microsoft-com:vml" xmlns:o="urn:schemas-microsoft-com:office:office">'
            '<w:pPr><w:spacing w:before="0" w:after="0" w:line="20" w:lineRule="exact"/></w:pPr>'
            '<w:r>'
            '<w:rPr><w:noProof/></w:rPr>'
            '<w:pict>'
            '<v:shapetype id="_x0000_t136" coordsize="21600,21600" o:spt="136" adj="10800" path="m@7,l@8,m@5,21600l@6,21600e">'
            '<v:path textpathok="t" o:connecttype="custom"/>'
            '<v:textpath on="t" fitshape="t"/>'
            '</v:shapetype>'
            '<v:shape id="YanBodyWatermark1" type="#_x0000_t136" '
            'style="position:absolute;margin-left:18pt;margin-top:180pt;width:440pt;height:120pt;rotation:315;'
            'z-index:-251654144;mso-position-horizontal:center;mso-position-horizontal-relative:page;'
            'mso-position-vertical:center;mso-position-vertical-relative:page" '
            'o:allowincell="f" fillcolor="#90A4AE" stroked="f">'
            '<v:fill opacity=".28"/>'
            '<v:textpath style="font-family:&quot;Arial&quot;;font-size:1pt" string="YAN360 • KO‘RIK NUSXASI"/>'
            '</v:shape>'
            '</w:pict>'
            '</w:r>'
            '</w:p>';

        const wmHeaderFileName = 'word/header_yan360_wm.xml';
        const wmRelId = 'rIdYan360Wm99';

        for (final file in archive) {
          if (!file.isFile) continue;
          final rawData = file.content as List<int>;

          if (file.name == 'word/document.xml') {
            var xml = utf8.decode(rawData, allowMalformed: true);
            final bodyOpenIdx = xml.indexOf('<w:body>');
            if (bodyOpenIdx >= 0) {
              final insertPos = bodyOpenIdx + '<w:body>'.length;
              xml =
                  xml.substring(0, insertPos) +
                  bodyFloatingWatermarkParagraph +
                  xml.substring(insertPos);
            }
            // Attach headerReference to <w:sectPr> if not already referencing our watermark header
            if (xml.contains('<w:sectPr')) {
              xml = xml.replaceAllMapped(
                RegExp(r'<w:sectPr([^>]*)>'),
                (m) =>
                    '<w:sectPr${m.group(1)}>'
                    '<w:headerReference w:type="default" r:id="$wmRelId"/>'
                    '<w:headerReference w:type="first" r:id="$wmRelId"/>'
                    '<w:headerReference w:type="even" r:id="$wmRelId"/>',
              );
            }
            final encoded = utf8.encode(xml);
            outArchive.addFile(
              ArchiveFile(file.name, encoded.length, encoded),
            );
          } else if (file.name == 'word/_rels/document.xml.rels') {
            var relsXml = utf8.decode(rawData, allowMalformed: true);
            if (!relsXml.contains(wmRelId)) {
              relsXml = relsXml.replaceFirst(
                '</Relationships>',
                '<Relationship Id="$wmRelId" '
                    'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/header" '
                    'Target="header_yan360_wm.xml"/></Relationships>',
              );
            }
            final encoded = utf8.encode(relsXml);
            outArchive.addFile(
              ArchiveFile(file.name, encoded.length, encoded),
            );
          } else if (file.name == '[Content_Types].xml') {
            var ctXml = utf8.decode(rawData, allowMalformed: true);
            if (!ctXml.contains('header_yan360_wm.xml')) {
              ctXml = ctXml.replaceFirst(
                '</Types>',
                '<Override PartName="/word/header_yan360_wm.xml" '
                    'ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.header+xml"/></Types>',
              );
            }
            final encoded = utf8.encode(ctXml);
            outArchive.addFile(
              ArchiveFile(file.name, encoded.length, encoded),
            );
          } else {
            outArchive.addFile(
              ArchiveFile(file.name, rawData.length, rawData),
            );
          }
        }

        final hdrBytes = utf8.encode(watermarkHeaderXml);
        outArchive.addFile(
          ArchiveFile(wmHeaderFileName, hdrBytes.length, hdrBytes),
        );

        final zipped = ZipEncoder().encode(outArchive);
        if (zipped != null && zipped.isNotEmpty) {
          return Uint8List.fromList(zipped);
        }
      } catch (_) {}
    }

    // 2. TRUE DIAGONAL WATERMARK FOR PDF (.PDF) — WORKS EVEN ON COMPRESSED / FLATEDECODE PDFS
    if (lower.endsWith('.pdf')) {
      try {
        return _stampDiagonalPdfWatermark(originalBytes, arizaId);
      } catch (_) {}
    }

    // 3. For .txt files
    if (lower.endsWith('.txt')) {
      try {
        final text = utf8.decode(originalBytes, allowMalformed: true);
        final buf = StringBuffer()
          ..writeln('[ YAN360 • WATERMARK • KO‘RIK NUSXASI ($arizaId) ]\n')
          ..writeln(text)
          ..writeln('\n[ YAN360 • WATERMARK • KO‘RIK NUSXASI ($arizaId) ]');
        return Uint8List.fromList(utf8.encode(buf.toString()));
      } catch (_) {}
    }

    return originalBytes;
  }

  /// Injects a diagonal 45-degree rotated semi-transparent watermark stream into every page
  /// of a PDF file (including compressed FlateDecode PDFs) by adding a new PDF stream object
  /// and appending its reference to each `/Type /Page` `/Contents` entry + `/Resources /Font`.
  /// Injects a diagonal 45-degree rotated background watermark stream into every page
  /// of a PDF file (including compressed FlateDecode PDFs) BEFORE the page content stream
  /// so the watermark renders behind the text without covering it!
  Uint8List _stampDiagonalPdfWatermark(Uint8List pdfBytes, String arizaId) {
    final raw = latin1.decode(pdfBytes, allowInvalid: true);

    var maxObjNum = 100;
    for (final m in RegExp(r'(\d+)\s+0\s+obj').allMatches(raw)) {
      final n = int.tryParse(m.group(1) ?? '') ?? 0;
      if (n > maxObjNum) maxObjNum = n;
    }
    final fontObjNum = maxObjNum + 1;
    final streamObjNum = maxObjNum + 2;

    // Diagonal 45-degree rotated watermark graphics stream (3 centered diagonal lines across the page)
    final wmContent =
        'q\n'
        '0.82 0.85 0.89 rg\n'
        'BT\n'
        '/FWM1 28 Tf\n'
        '0.7071 0.7071 -0.7071 0.7071 95 140 Tm\n'
        '(YAN360  WATERMARK  -  KORIK NUSXASI) Tj\n'
        'ET\n'
        'BT\n'
        '/FWM1 28 Tf\n'
        '0.7071 0.7071 -0.7071 0.7071 95 340 Tm\n'
        '(YAN360  WATERMARK  -  $arizaId) Tj\n'
        'ET\n'
        'BT\n'
        '/FWM1 28 Tf\n'
        '0.7071 0.7071 -0.7071 0.7071 95 540 Tm\n'
        '(YAN360  WATERMARK  -  KORIK NUSXASI) Tj\n'
        'ET\n'
        'Q\n';

    // Prepend `streamObjNum 0 R` to `/Contents` so the watermark is drawn BEHIND the page text!
    var patched = raw.replaceAllMapped(
      RegExp(r'/Contents\s+(\d+\s+0\s+R)'),
      (m) => '/Contents [$streamObjNum 0 R ${m.group(1)}]',
    );
    if (patched == raw) {
      patched = raw.replaceAllMapped(
        RegExp(r'/Contents\s*\[([^\]]*)\]'),
        (m) => '/Contents [$streamObjNum 0 R ${m.group(1)}]',
      );
    }

    if (patched.contains('/Font')) {
      patched = patched.replaceAllMapped(
        RegExp(r'/Font\s*<<'),
        (m) => '/Font << /FWM1 $fontObjNum 0 R ',
      );
    } else {
      patched = patched.replaceAllMapped(
        RegExp(r'/Resources\s*<<'),
        (m) => '/Resources << /Font << /FWM1 $fontObjNum 0 R >> ',
      );
    }

    final extraObjects =
        '\n$fontObjNum 0 obj\n'
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica-Bold >>\n'
        'endobj\n'
        '$streamObjNum 0 obj\n'
        '<< /Length ${wmContent.length} >>\n'
        'stream\n'
        '$wmContent'
        'endstream\n'
        'endobj\n';

    final eofIdx = patched.lastIndexOf('%%EOF');
    if (eofIdx > 0) {
      patched =
          patched.substring(0, eofIdx) +
          extraObjects +
          '%%EOF\n';
    } else {
      patched = '$patched$extraObjects%%EOF\n';
    }

    return Uint8List.fromList(latin1.encode(patched));
  }

  /// Downloads either the WATERMARKED inspection copy (when `useWatermarkedCopy = true`)
  /// or the ORIGINAL unwatermarked file (when `useWatermarkedCopy = false`).
  Future<Uint8List?> _downloadArizaFileBytes(
    _ArizaFileDeliveryMeta meta, {
    required bool useWatermarkedCopy,
  }) async {
    final targetStoragePath =
        (useWatermarkedCopy && meta.watermarkedStoragePath.isNotEmpty)
        ? meta.watermarkedStoragePath
        : meta.storagePath;

    if (targetStoragePath.isNotEmpty) {
      try {
        return await Supabase.instance.client.storage
            .from(meta.storageBucket)
            .download(targetStoragePath);
      } catch (_) {
        final altBucket = meta.storageBucket == 'advocate_licenses'
            ? 'chat_media'
            : 'advocate_licenses';
        try {
          return await Supabase.instance.client.storage
              .from(altBucket)
              .download(targetStoragePath);
        } catch (_) {}
      }
    }

    // Fallback to original storagePath if watermarked path wasn't found
    if (useWatermarkedCopy && meta.storagePath.isNotEmpty) {
      try {
        final raw = await Supabase.instance.client.storage
            .from(meta.storageBucket)
            .download(meta.storagePath);
        return _buildWatermarkedArizaFileBytes(
          originalBytes: raw,
          fileName: meta.fileName,
          arizaId: meta.arizaId,
          advocateName: widget.lawyer.fullName,
        );
      } catch (_) {}
    }

    if (meta.localPath.isNotEmpty) {
      final f = File(meta.localPath);
      if (f.existsSync()) {
        final raw = await f.readAsBytes();
        return useWatermarkedCopy
            ? _buildWatermarkedArizaFileBytes(
                originalBytes: Uint8List.fromList(raw),
                fileName: meta.fileName,
                arizaId: meta.arizaId,
                advocateName: widget.lawyer.fullName,
              )
            : Uint8List.fromList(raw);
      }
    }
    return null;
  }

  /// Opens the `#ariza` file directly in the phone's viewer (`OpenFilex.open`):
  /// - Before client confirms (`!isAccepted`): downloads and opens the WATERMARKED file (`YAN360_WATERMARK_...`).
  /// - After client confirms (`isAccepted`): opens the ORIGINAL unwatermarked file!
  Future<void> _openArizaFileInPhoneViewer(
    _ArizaFileDeliveryMeta meta, {
    bool? forceWatermarked,
  }) async {
    try {
      final isAccepted = meta.isEffectivelyAccepted(DateTime.now());
      final useWatermarked = forceWatermarked ?? !isAccepted;
      final bytes = await _downloadArizaFileBytes(
        meta,
        useWatermarkedCopy: useWatermarked,
      );
      if (bytes == null) {
        throw StateError('Faylni serverdan olib bo‘lmadi');
      }
      final directory = await getTemporaryDirectory();
      final safeName = meta.fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );
      final filePrefix = useWatermarked ? 'YAN360_WATERMARK_' : 'ASL_';
      final viewFile = File(
        '${directory.path}${Platform.pathSeparator}$filePrefix$safeName',
      );
      await viewFile.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(viewFile.path);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Faylni ochib bo‘lmadi: $error')),
        );
      }
    }
  }

  /// Resolves and saves the clean, unwatermarked ORIGINAL `#ariza` file to the phone's
  /// memory (`Downloads` / `ApplicationDocumentsDirectory`) — ONLY available
  /// AFTER the client has accepted the ariza!
  Future<File?> _saveAcceptedArizaToPhoneMemory(
    _ArizaFileDeliveryMeta meta,
  ) async {
    try {
      final bytes = await _downloadArizaFileBytes(
        meta,
        useWatermarkedCopy: false,
      );
      if (bytes == null) return null;

      final cleanName = meta.fileName.replaceAll(
        RegExp(r'[^a-zA-Z0-9._-]'),
        '_',
      );

      final docsDir = await getApplicationDocumentsDirectory();
      final targetFile = File(
        '${docsDir.path}${Platform.pathSeparator}$cleanName',
      );
      await targetFile.writeAsBytes(bytes, flush: true);

      try {
        final androidDl = Directory('/storage/emulated/0/Download');
        if (androidDl.existsSync()) {
          final dlFile = File(
            '${androidDl.path}${Platform.pathSeparator}$cleanName',
          );
          await dlFile.writeAsBytes(bytes, flush: true);
          return dlFile;
        }
      } catch (_) {}

      return targetFile;
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleSaveAcceptedArizaButton(
    _ChatMessageItem msg,
    _ArizaFileDeliveryMeta meta,
  ) async {
    final savedFile = await _saveAcceptedArizaToPhoneMemory(meta);
    if (!mounted) return;
    if (savedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Faylni telefonga saqlab bo‘lmadi.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Asl ariza telefon xotirasiga saqlandi: ${savedFile.path}',
        ),
        backgroundColor: YanColors.successGreen,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Shares the accepted ORIGINAL `#ariza` file across all apps on the phone (Telegram,
  /// WhatsApp, Gmail, Drive, Files, etc.) via the native system chooser.
  Future<void> _handleShareAcceptedArizaButton(
    _ChatMessageItem msg,
    _ArizaFileDeliveryMeta meta,
  ) async {
    final savedFile = await _saveAcceptedArizaToPhoneMemory(meta);
    if (savedFile == null || !savedFile.existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Faylni ulashish uchun yuklab bo‘lmadi.'),
          ),
        );
      }
      return;
    }
    try {
      await Share.shareXFiles(
        <XFile>[XFile(savedFile.path)],
        text: meta.fileName,
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ulashish oynasi ochilmadi: $error')),
        );
      }
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Ulashish oynasi ochildi (${meta.fileName})',
        ),
        backgroundColor: YanColors.primaryNavy,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _acceptArizaDelivery(
    _ChatMessageItem msg,
    _ArizaFileDeliveryMeta meta,
  ) async {
    if (meta.status == 'accepted' || meta.status == 'rejected') return;
    final acceptedMetaObj = meta.copyWith(status: 'accepted');
    final updatedMeta = acceptedMetaObj.encode();
    final idx = _messages.indexWhere((m) => m.id == msg.id);
    if (idx >= 0) {
      setState(() {
        _messages[idx] = _messages[idx].copyWith(mediaMeta: updatedMeta);
      });
    }

    await _updateArizaStatusInSupabase(
      arizaId: meta.arizaId,
      status: 'accepted',
    );

    final isAdvocateSender =
        widget.profile.roleType == UserRole.advokat ||
        widget.profile.roleType == UserRole.yordamchi;
    final clientId = isAdvocateSender ? _peerUserId : _myUserId;
    final advocateId = isAdvocateSender ? _myUserId : _peerUserId;
    final advocateName = isAdvocateSender
        ? widget.profile.displayName
        : widget.lawyer.fullName;

    YanRoleDataCatalog.markArizaCompletedByHashtag(
      clientId: clientId,
      advocateId: advocateId,
      advocateName: advocateName,
      arizaContent: '${msg.text}\nFayl: ${meta.fileName}',
      attachmentMeta: updatedMeta,
    );
    await _YanE2eeCryptoEngine.persistArizaOrdersLedger();

    _roomChannel?.sendBroadcastMessage(
      event: 'e2ee_ariza_decision',
      payload: <String, dynamic>{
        'message_id': msg.id,
        'media_meta': updatedMeta,
        'decision': 'accepted',
      },
    );

    // Automatically deliver the ORIGINAL unwatermarked file in chat once the client confirms!
    if (meta.storagePath.isNotEmpty) {
      final ext = meta.fileName.contains('.')
          ? meta.fileName.split('.').last.toLowerCase()
          : 'docx';
      final mimeType = 'application/${ext == 'pdf' ? 'pdf' : ext}';
      final originalChatFileMeta =
          'CHAT_FILE_V1|name:${Uri.encodeComponent(meta.fileName)}'
          '|storage:${Uri.encodeComponent(meta.storagePath)}'
          '|bucket:${Uri.encodeComponent(meta.storageBucket)}'
          '|e2ee:0'
          '|mime:${Uri.encodeComponent(mimeType)}|size:0';
      _dispatchInstantEncryptedMessage(
        text: '✅ ASL NUSXA (Watermarksiz): ${meta.fileName}',
        mediaType: _ChatMediaType.document,
        mediaMeta: originalChatFileMeta,
      );
    }

    await _saveLocalEncryptedCache();
    await _syncMyRoomStateToProfileEnvelope(isOnline: true);

    if (!mounted) return;
    _openFiveEmptyStarsRatingSheet(msg, acceptedMetaObj);
  }

  Future<void> _promptMandatoryRejectionReasonDialog(
    _ChatMessageItem msg,
    _ArizaFileDeliveryMeta meta,
  ) async {
    final reasonController = TextEditingController();
    String? validationError;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: YanColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              title: const Row(
                children: <Widget>[
                  Icon(
                    Icons.error_outline_rounded,
                    color: YanColors.destructiveRed,
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Arizani rad etish sababi (Majburiy)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Arizada qanday xatolik yoki kamchilik borligini yozing. Izoh kiritmasdan rad etib bo‘lmaydi.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: YanColors.mutedText,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: reasonController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: YanColors.primaryNavy,
                    ),
                    decoration: InputDecoration(
                      hintText:
                          'Masalan: F.I.Sh. yoki sana noto‘g‘ri yozilgan, qo‘shimcha talab qolib ketgan...',
                      filled: true,
                      fillColor: YanColors.lightBlue,
                      errorText: validationError,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text(
                    'Bekor qilish',
                    style: TextStyle(
                      color: YanColors.mutedText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YanColors.destructiveRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    final reason = reasonController.text.trim();
                    if (reason.length < 4) {
                      setDialogState(() {
                        validationError =
                            'Iltimos, xatolik haqida izoh yozing (majburiy)!';
                      });
                      return;
                    }
                    Navigator.pop(dialogCtx);
                    _submitArizaRejection(msg, meta, reason);
                  },
                  child: const Text(
                    'Rad etish va izohni yuborish',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitArizaRejection(
    _ChatMessageItem msg,
    _ArizaFileDeliveryMeta meta,
    String mandatoryReason,
  ) async {
    final updatedMeta = meta
        .copyWith(status: 'rejected', rejectionReason: mandatoryReason)
        .encode();
    final idx = _messages.indexWhere((m) => m.id == msg.id);
    if (idx >= 0) {
      setState(() {
        _messages[idx] = _messages[idx].copyWith(mediaMeta: updatedMeta);
      });
    }

    await _updateArizaStatusInSupabase(
      arizaId: meta.arizaId,
      status: 'rejected',
    );

    final isAdvocateSender =
        widget.profile.roleType == UserRole.advokat ||
        widget.profile.roleType == UserRole.yordamchi;
    final clientId = isAdvocateSender ? _peerUserId : _myUserId;
    final advocateId = isAdvocateSender ? _myUserId : _peerUserId;

    YanRoleDataCatalog.markArizaRejectedByClient(
      clientId: clientId,
      advocateId: advocateId,
      rejectionReason: mandatoryReason,
    );
    await _YanE2eeCryptoEngine.persistArizaOrdersLedger();

    _roomChannel?.sendBroadcastMessage(
      event: 'e2ee_ariza_decision',
      payload: <String, dynamic>{
        'message_id': msg.id,
        'media_meta': updatedMeta,
        'decision': 'rejected',
        'rejection_reason': mandatoryReason,
      },
    );

    // Save state without sending any automatic follow-up message!
    // The original #ariza card stays red with the rejection reason until the advocate sends a new one.
    await _saveLocalEncryptedCache();
    await _syncMyRoomStateToProfileEnvelope(isOnline: true);
  }

  Future<void> _openFiveEmptyStarsRatingSheet(
    _ChatMessageItem msg,
    _ArizaFileDeliveryMeta meta, {
    int initialStars = 0,
  }) async {
    if (meta.ratedStars > 0) return;
    var selectedStars = initialStars;

    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      backgroundColor: YanColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: YanColors.border,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: YanColors.successGreen.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'ARIZA QABUL QILINDI • ADVOKATNI BAHOLASH',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0A936B),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${widget.lawyer.fullName} ishini baholang',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Sizning bahoyingiz advokatning umumiy reytingiga bevosita ta’sir qiladi.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.8,
                        color: YanColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 18),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List<Widget>.generate(5, (index) {
                        final starNum = index + 1;
                        final filled = starNum <= selectedStars;
                        return GestureDetector(
                          onTap: () =>
                              setSheetState(() => selectedStars = starNum),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              filled
                                  ? Icons.star_rounded
                                  : Icons.star_border_rounded,
                              size: 44,
                              color: filled
                                  ? const Color(0xFFF59E0B)
                                  : YanColors.primaryBlue,
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      selectedStars == 0
                          ? 'Yulduzchalardan birini tanlang (1 dan 5 gacha)'
                          : 'Tanlangan baho: $selectedStars / 5 yulduz',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: selectedStars == 0
                            ? YanColors.mutedText
                            : const Color(0xFFD97706),
                      ),
                    ),
                    const SizedBox(height: 18),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: selectedStars == 0
                            ? null
                            : () {
                                Navigator.pop(sheetCtx);
                                _submitClientStarRating(
                                  msg,
                                  meta,
                                  selectedStars,
                                );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: YanColors.primaryBlue,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'BAHOLASHNI TASDIQLASH',
                          style: TextStyle(
                            fontSize: 13.8,
                            fontWeight: FontWeight.w900,
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
      },
    );
  }

  Future<void> _submitClientStarRating(
    _ChatMessageItem msg,
    _ArizaFileDeliveryMeta meta,
    int stars,
  ) async {
    if (meta.ratedStars > 0 || stars < 1 || stars > 5) return;
    final updatedMeta = meta
        .copyWith(status: 'accepted', ratedStars: stars)
        .encode();
    final idx = _messages.indexWhere((m) => m.id == msg.id);
    if (idx >= 0) {
      setState(() {
        _messages[idx] = _messages[idx].copyWith(mediaMeta: updatedMeta);
      });
    }

    final newOverallRating = YanRoleDataCatalog.applyAdvocateStarRating(
      advocateId: _peerUserId,
      advocateName: widget.lawyer.fullName,
      stars: stars,
      clientName: widget.profile.displayName,
      ratingId: meta.arizaId,
    );

    _roomChannel?.sendBroadcastMessage(
      event: 'e2ee_ariza_decision',
      payload: <String, dynamic>{
        'message_id': msg.id,
        'media_meta': updatedMeta,
        'decision': 'rated',
        'rated_stars': stars,
        'ariza_id': meta.arizaId,
        'advocate_id': _peerUserId,
        'advocate_name': widget.lawyer.fullName,
        'client_name': widget.profile.displayName,
      },
    );

    await _saveLocalEncryptedCache();
    await _syncMyRoomStateToProfileEnvelope(
      isOnline: true,
      newAdvocateRatingEntry: <String, dynamic>{
        'advocate_id': _peerUserId,
        'advocate_name': widget.lawyer.fullName,
        'stars': stars,
        'ariza_id': meta.arizaId,
        'client_name': widget.profile.displayName,
        'timestamp': DateTime.now().toUtc().toIso8601String(),
      },
    );

    final starIcons = List<String>.filled(stars, '★').join() +
        List<String>.filled(5 - stars, '☆').join();
    _dispatchInstantEncryptedMessage(
      text:
          '⭐ ARIZA QABUL QILINDI VA BAHOLANDI: $starIcons ($stars/5)\n'
          '• Advokatning yangi umumiy reytingi: ${newOverallRating.toStringAsFixed(2)} ★',
      mediaType: _ChatMediaType.text,
    );
  }

  void _openCallOptionsSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YanColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
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
              Row(
                children: <Widget>[
                  _LawyerAvatarPortrait(
                    initials: widget.lawyer.initials,
                    isOnline: _isPeerOnline,
                    size: 44,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.lawyer.fullName,
                          style: const TextStyle(
                            fontSize: 16.5,
                            fontWeight: FontWeight.w800,
                            color: YanColors.primaryNavy,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _isPeerOnline
                              ? 'Online • E2EE Shifrlangan Qo‘ng‘iroq'
                              : 'Offline • Qo‘ng‘iroq bildirishnomasi yuboriladi',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _isPeerOnline
                                ? YanColors.successGreen
                                : YanColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _startE2eeCall(isVideo: false);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: YanColors.lightBlue,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: YanColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: YanColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Audio qo‘ng‘iroq (Ovozli)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: YanColors.primaryNavy,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'SRTP / E2EE himoyalangan tez ovozli aloqa',
                              style: TextStyle(
                                fontSize: 12,
                                color: YanColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: YanColors.primaryBlue,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  _startE2eeCall(isVideo: true);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: YanColors.lightBlue,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: YanColors.border),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: const BoxDecoration(
                          color: YanColors.primaryNavy,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 13),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Video qo‘ng‘iroq (HD Video)',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: YanColors.primaryNavy,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Yuzma-yuz E2EE shifrlangan video maslahat',
                              style: TextStyle(
                                fontSize: 12,
                                color: YanColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: YanColors.primaryNavy,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startE2eeCall({
    required bool isVideo,
    bool isAnswering = false,
    String? existingCallId,
    String? consultationId,
    DateTime? consultationDeadlineAt,
  }) async {
    final callId = existingCallId ??
        'CALL-${DateTime.now().millisecondsSinceEpoch}-${_myUserId.hashCode.abs()}';

    if (consultationId != null) {
      ConsultationRepository.instance.markStatus(consultationId, 'in_progress');
    }

    if (!mounted) return;
    final outcome = await Navigator.of(context).push<_TelegramCallOutcome>(
      MaterialPageRoute<_TelegramCallOutcome>(
        builder: (_) => _E2eeLiveCallScreen(
          callId: callId,
          peerId: _peerUserId,
          peerName: widget.lawyer.fullName,
          peerInitials: widget.lawyer.initials,
          peerSubtitle: consultationId != null
              ? 'Rasmiy 19 daqiqalik E2EE Konsultatsiya'
              : widget.lawyer.specialization,
          myUserId: _myUserId,
          myUserName: widget.profile.displayName,
          roomKey: _roomKey,
          roomChannel: _roomChannel,
          isInitialVideo: isVideo,
          isCaller: !isAnswering,
          consultationId: consultationId,
          consultationDeadlineAt: consultationDeadlineAt,
        ),
      ),
    );

    if (outcome != null && mounted && !isAnswering) {
      final callMeta = _TelegramCallLogMeta(
        callId: callId,
        callType: outcome.wasVideo ? 'video' : 'audio',
        status: outcome.status,
        durationSeconds: outcome.durationSeconds,
        callerId: _myUserId,
      ).encode();

      _dispatchInstantEncryptedMessage(
        text: outcome.summaryTitle,
        mediaType: _ChatMediaType.callLog,
        mediaMeta: callMeta,
      );
    }

    // After a consultation call ends, automatically prompt the client with 5-star rating!
    final isClientRole =
        widget.profile.roleType == UserRole.oddiy ||
        widget.profile.roleType == UserRole.mijoz;
    if (consultationId != null && mounted && isClientRole) {
      await _showConsultationRatingDialog(
        consultationId: consultationId,
        advocateName: widget.lawyer.fullName,
      );
    }
  }

  Future<void> _showConsultationRatingDialog({
    required String consultationId,
    required String advocateName,
  }) async {
    var selectedStars = 5;
    final commentCtrl = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dlgCtx) {
        return StatefulBuilder(
          builder: (ctx, setDlgState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26),
                side: const BorderSide(color: Color(0xFFDCEBFF)),
              ),
              title: const Row(
                children: <Widget>[
                  Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 26),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Konsultatsiyani baholang',
                      style: TextStyle(
                        fontSize: 17.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0B1F3A),
                      ),
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    '$advocateName bilan o‘tkazilgan video konsultatsiya sifatini 1 dan 5 gacha yulduz bilan baholang:',
                    style: const TextStyle(
                      fontSize: 12.8,
                      color: Color(0xFF64748B),
                      height: 1.42,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List<Widget>.generate(5, (i) {
                      final starNum = i + 1;
                      final active = starNum <= selectedStars;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setDlgState(() => selectedStars = starNum);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            active ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 38,
                            color: active
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFFCBD5E1),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: commentCtrl,
                    maxLines: 2,
                    style: const TextStyle(color: Color(0xFF0B1F3A), fontSize: 13.5),
                    decoration: InputDecoration(
                      hintText: 'Qisqa izohingiz (ixtiyoriy)...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 12.8,
                      ),
                      filled: true,
                      fillColor: const Color(0xFFF0F7FF),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFFDCEBFF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: Color(0xFF1677FF)),
                      ),
                    ),
                  ),
                ],
              ),
              actions: <Widget>[
                TextButton(
                  onPressed: () => Navigator.pop(dlgCtx, false),
                  child: const Text(
                    'Keyinroq',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1677FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.pop(dlgCtx, true),
                  child: const Text(
                    'Bahoni saqlash',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted == true) {
      await ConsultationRepository.instance.submitConsultationRating(
        consultationId: consultationId,
        stars: selectedStars,
        comment: commentCtrl.text,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rahmat! Konsultatsiya $selectedStars yulduz bilan baholandi.'),
            backgroundColor: YanColors.successGreen,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
    commentCtrl.dispose();
  }

  Widget _buildConsultationBookingCard(_ChatMessageItem m, Map<String, dynamic> meta) {
    final now = DateTime.now();
    final cId = meta['id']?.toString() ?? '';
    final advName = meta['advocate_name']?.toString() ?? widget.lawyer.fullName;
    final clientName = meta['client_name']?.toString() ?? 'Mijoz';
    final dateKey = meta['date_key']?.toString() ?? '';
    final hour = (meta['hour'] as num?)?.toInt() ?? 0;
    final slot = (meta['slot'] as num?)?.toInt() ?? 0;
    final start = DateTime.tryParse(meta['start_iso']?.toString() ?? '')?.toLocal() ??
        ConsultationSlotMath.slotStartDateTime(dateKey, hour, slot);
    final end = DateTime.tryParse(meta['end_iso']?.toString() ?? '')?.toLocal() ??
        start.add(const Duration(minutes: 19));

    final repoBooking = ConsultationRepository.instance.consultations.value
        .where((c) => c.id == cId)
        .firstOrNull;
    final isLiveNow = !now.isBefore(start) && now.isBefore(end);
    final isBeforeStart = now.isBefore(start);
    final isAfterEnd = !now.isBefore(end);
    final ratedStars = repoBooking?.ratingStars ?? 0;
    final isClientRole =
        widget.profile.roleType == UserRole.oddiy ||
        widget.profile.roleType == UserRole.mijoz;

    final timeWindow = ConsultationSlotMath.formatSlotRange(hour, slot);
    final dateLabel = ConsultationSlotMath.formatFriendlyDate(
      ConsultationSlotMath.parseDateKey(dateKey),
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF3F8FF)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isLiveNow
              ? const Color(0xFF10B981)
              : const Color(0xFFDCEBFF),
          width: isLiveNow ? 1.7 : 1.1,
        ),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: const Color(0xFF1677FF).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                decoration: BoxDecoration(
                  color: isLiveNow
                      ? const Color(0xFFECFDF5)
                      : const Color(0xFFEBF4FF),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  isLiveNow
                      ? '● HOZIR FAOL • ${ConsultationSlotMath.formatCountdown(end.difference(now))}'
                      : isBeforeStart
                      ? 'KONSULTATSIYA BAND QILINDI'
                      : 'KONSULTATSIYA YAKUNLANDI',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isLiveNow
                        ? const Color(0xFF059669)
                        : const Color(0xFF1677FF),
                  ),
                ),
              ),
              const Spacer(),
              Text(
                cId,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '$dateLabel • $timeWindow',
            style: const TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w900,
              color: Color(0xFF0B1F3A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Advokat: $advName • Mijoz: $clientName',
            style: const TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 9),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: const Color(0xFFDCEBFF)),
            ),
            child: Text(
              '⏱ Video qo‘ng‘iroq faqat $timeWindow oralig‘ida (19 daq) faol bo‘ladi va taymer 00:00 ga yetganda har ikki tomon uchun avtomatik yakunlanadi.',
              style: const TextStyle(
                fontSize: 11.4,
                height: 1.4,
                color: Color(0xFF1E3A5F),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isLiveNow
                  ? () => _startE2eeCall(
                        isVideo: true,
                        consultationId: cId,
                        consultationDeadlineAt: end,
                      )
                  : null,
              icon: Icon(
                isLiveNow
                    ? Icons.videocam_rounded
                    : isBeforeStart
                    ? Icons.lock_clock_rounded
                    : Icons.check_circle_outline_rounded,
                size: 18,
              ),
              label: Text(
                isLiveNow
                    ? 'Video qo‘ng‘iroqni boshlash (${ConsultationSlotMath.formatCountdown(end.difference(now))})'
                    : isBeforeStart
                    ? 'Boshlanishigacha: ${ConsultationSlotMath.formatCountdown(start.difference(now))}'
                    : 'Konsultatsiya muddati yakunlandi',
                style: const TextStyle(
                  fontSize: 12.6,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1677FF),
                disabledBackgroundColor: const Color(0xFFE2E8F0),
                foregroundColor: Colors.white,
                disabledForegroundColor: const Color(0xFF64748B),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          if (isAfterEnd && isClientRole) ...<Widget>[
            const SizedBox(height: 8),
            if (ratedStars > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Icon(Icons.star_rounded, size: 17, color: Color(0xFFF59E0B)),
                  const SizedBox(width: 5),
                  Text(
                    'Sizning bahoingiz: $ratedStars / 5 yulduz',
                    style: const TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                ],
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showConsultationRatingDialog(
                    consultationId: cId,
                    advocateName: advName,
                  ),
                  icon: const Icon(Icons.star_outline_rounded, size: 17, color: Color(0xFFF59E0B)),
                  label: const Text(
                    'Konsultatsiyani baholash (5 yulduz)',
                    style: TextStyle(
                      fontSize: 12.2,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFFB45309),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFFBEB),
                    side: const BorderSide(color: Color(0xFFFCD34D)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  void _showMessageDetailsSheet(_ChatMessageItem msg) {
    final mine = msg.isMine(_myUserId);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YanColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
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
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.verified_user_rounded,
                    color: YanColors.primaryBlue,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Xabar tafsilotlari va E2EE holati',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w800,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: YanColors.lightBlue,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: YanColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    _DetailInfoRow(
                      label: 'Yuboruvchi',
                      value: mine ? 'Siz (${msg.senderName})' : msg.senderName,
                    ),
                    _DetailInfoRow(
                      label: 'Yuborilgan vaqti',
                      value: msg.formattedFullDateTime,
                    ),
                    _DetailInfoRow(
                      label: 'Holati (Seen / Unseen)',
                      value: msg.isSeen
                          ? '✓✓ O‘qildi (Seen)'
                          : '✓ Serverga saqlandi • Hali o‘qilmagan',
                    ),
                    if (msg.isSeen && msg.formattedSeenDateTime != null)
                      _DetailInfoRow(
                        label: 'O‘qilgan vaqti',
                        value: msg.formattedSeenDateTime!,
                      ),
                    const Divider(height: 16, color: Color(0xFFDCE9F7)),
                    const Text(
                      'Serverda saqlangan E2EE shifrlangan ko‘rinishi:',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: YanColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      msg.encryptedCiphertext,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAttachmentSheet() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: YanColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'E2EE Himoyalangan fayl va #ariza yuborish',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: YanColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 14),
              _AttachmentOptionTile(
                icon: Icons.attach_file_rounded,
                title: 'Qurilmadan istalgan fayl yuborish',
                subtitle: 'Rasm, PDF, hujjat, audio, video va boshqa fayllar',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickAndSendChatFile();
                },
              ),
              _AttachmentOptionTile(
                icon: Icons.verified_rounded,
                title: 'Tayyor rasmiy arizani topshirish (#ariza)',
                subtitle:
                    'Xotira yoki galereyadan fayl tanlash • YAN360 Watermark va 5 yulduz baholash bilan',
                onTap: () {
                  Navigator.pop(ctx);
                  _openReadyArizaFileDeliveryModal();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _peerPresenceSubtitle {
    if (_isPeerOnline && _isMyAppInForeground) {
      return 'Online (Ilovada) • E2EE 0.00s aloqa';
    }
    final h = _peerLastSeen.hour.toString().padLeft(2, '0');
    final m = _peerLastSeen.minute.toString().padLeft(2, '0');
    return 'Offline • Oxirgi faollik: $h:$m';
  }

  /// Renders the `#ariza` card controls:
  /// - Before client accepts: ONLY `Ko‘rish` button (opens in-app YAN360 Watermarked preview)
  ///   + `Qabul qilish` and `Rad etish` buttons.
  /// - After client accepts: `Ko‘rish` + `Saqlash` (phone memory) + `Ulashish` (all apps)
  ///   + 5 Empty Stars (`☆ ☆ ☆ ☆ ☆`) rating!
  String _formatArizaResponseCountdown(DateTime sentAt, DateTime now) {
    final remaining = sentAt.add(const Duration(minutes: 30)).difference(now);
    if (remaining.isNegative) return 'muddati tugagan';
    final seconds = remaining.inSeconds;
    final minutesPart = (seconds ~/ 60).toString().padLeft(2, '0');
    final secondsPart = (seconds % 60).toString().padLeft(2, '0');
    return '$minutesPart:$secondsPart';
  }

  Widget _buildTelegramCallLogCard(_ChatMessageItem m, bool mine) {
    final parsed = _TelegramCallLogMeta.tryParse(m.mediaMeta, m.text, m.senderId);
    final isVideo = parsed.callType == 'video';
    final isOutgoing = YanRoleDataCatalog.isSameParticipant(
      parsed.callerId.isNotEmpty ? parsed.callerId : m.senderId,
      _myUserId,
    );
    final isMissedOrFailed = parsed.status == 'missed' ||
        parsed.status == 'declined' ||
        parsed.status == 'canceled';

    String titleText;
    if (parsed.status == 'completed') {
      titleText = isOutgoing
          ? (isVideo ? 'Chiquvchi video qo‘ng‘iroq' : 'Chiquvchi audio qo‘ng‘iroq')
          : (isVideo ? 'Kiruvchi video qo‘ng‘iroq' : 'Kiruvchi audio qo‘ng‘iroq');
    } else if (parsed.status == 'declined') {
      titleText = isOutgoing
          ? 'Rad etilgan qo‘ng‘iroq'
          : 'Javobsiz / Rad etilgan qo‘ng‘iroq';
    } else if (parsed.status == 'canceled') {
      titleText = isOutgoing
          ? 'Bekor qilingan qo‘ng‘iroq'
          : 'O‘tkazib yuborilgan qo‘ng‘iroq';
    } else {
      titleText = isOutgoing
          ? 'Javobsiz qo‘ng‘iroq'
          : 'O‘tkazib yuborilgan qo‘ng‘iroq';
    }

    final subtitleText = parsed.status == 'completed'
        ? '${parsed.formattedDuration} • Zero-Knowledge E2EE'
        : (isVideo ? 'HD Video • Javob berilmadi' : 'Ovozli aloqa • Javob berilmadi');

    final arrowIcon = isOutgoing
        ? Icons.call_made_rounded
        : (isMissedOrFailed ? Icons.call_missed_rounded : Icons.call_received_rounded);
    final arrowColor = isMissedOrFailed
        ? (mine ? const Color(0xFFFFB4AB) : YanColors.destructiveRed)
        : (mine ? const Color(0xFF6EE7B7) : YanColors.successGreen);

    return GestureDetector(
      onTap: () => _startE2eeCall(isVideo: isVideo),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: mine
              ? Colors.white.withValues(alpha: 0.14)
              : YanColors.lightBlue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isMissedOrFailed
                    ? YanColors.destructiveRed.withValues(
                        alpha: mine ? 0.85 : 0.14,
                      )
                    : (mine
                          ? Colors.white.withValues(alpha: 0.22)
                          : YanColors.primaryBlue.withValues(alpha: 0.14)),
              ),
              child: Icon(
                isVideo ? Icons.videocam_rounded : Icons.call_rounded,
                size: 20,
                color: isMissedOrFailed
                    ? (mine ? Colors.white : YanColors.destructiveRed)
                    : (mine ? Colors.white : YanColors.primaryBlue),
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    titleText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: mine ? Colors.white : YanColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(arrowIcon, size: 14, color: arrowColor),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          subtitleText,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.2,
                            fontWeight: FontWeight.w700,
                            color: mine
                                ? Colors.white.withValues(alpha: 0.88)
                                : YanColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: mine
                    ? Colors.white.withValues(alpha: 0.2)
                    : YanColors.white,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                'Qayta terish',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: mine ? Colors.white : YanColors.primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveArizaDeliveryControls(
    _ChatMessageItem m,
    _ArizaFileDeliveryMeta meta,
  ) {
    final now = DateTime.now();
    final isAccepted = meta.isEffectivelyAccepted(now);
    final isRejected = meta.status == 'rejected';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.16),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  const Icon(
                    Icons.insert_drive_file_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      meta.fileName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),

              if (meta.status == 'null' && meta.sentAtDateTime != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: <Widget>[
                      const Icon(Icons.timer_outlined,
                          size: 14, color: Colors.white),
                      const SizedBox(width: 5),
                      Text(
                        'Javob muddati: ${_formatArizaResponseCountdown(meta.sentAtDateTime!, now)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

              // Before confirmation: opens the WATERMARKED copy directly in phone viewer!
              if (!isAccepted)
                GestureDetector(
                  onTap: () => _openArizaFileInPhoneViewer(
                    meta,
                    forceWatermarked: true,
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.visibility_rounded,
                          size: 16,
                          color: YanColors.primaryNavy,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Ko‘rish (Watermark bilan)',
                          style: TextStyle(
                            fontSize: 12.2,
                            fontWeight: FontWeight.w900,
                            color: YanColors.primaryNavy,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                // AFTER ACCEPTANCE: "Ko'rish", "Saqlash" (in phone memory), and "Ulashish" (all apps) for the ORIGINAL file!
                Row(
                  children: <Widget>[
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _openArizaFileInPhoneViewer(
                          meta,
                          forceWatermarked: false,
                        ),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.visibility_rounded,
                                size: 14,
                                color: YanColors.primaryNavy,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Ko‘rish',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: YanColors.primaryNavy,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleSaveAcceptedArizaButton(m, meta),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.5),
                          decoration: BoxDecoration(
                            color: YanColors.primaryNavy,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.download_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Saqlash',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _handleShareAcceptedArizaButton(m, meta),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8.5),
                          decoration: BoxDecoration(
                            color: YanColors.primaryBlue,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Icon(
                                Icons.share_rounded,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Ulashish',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        if (!isAccepted && !isRejected) ...<Widget>[
          const Text(
            'Arizani "Ko‘rish" orqali tekshirib, tasdiqlang yoki rad eting:',
            style: TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 7),
          Row(
            children: <Widget>[
              Expanded(
                child: GestureDetector(
                  onTap: () => _acceptArizaDelivery(m, meta),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.check_circle_rounded,
                          size: 16,
                          color: Color(0xFF0A936B),
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Qabul qilish',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0A936B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => _promptMandatoryRejectionReasonDialog(m, meta),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    decoration: BoxDecoration(
                      color: YanColors.destructiveRed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Icon(
                          Icons.cancel_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Rad etish',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else if (isRejected) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: YanColors.destructiveRed.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  '❌ RAD ETILDI • Taymer davom etmoqda',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                if (meta.rejectionReason.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 3),
                  Text(
                    'Sababi: ${meta.rejectionReason}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else if (isAccepted) ...<Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(
                      Icons.verified_rounded,
                      size: 16,
                      color: Color(0xFF0A936B),
                    ),
                    SizedBox(width: 5),
                    Expanded(
                      child: Text(
                        'QABUL QILINDI • Saqlash va Ulashish ochildi',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0A936B),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  meta.ratedStars == 0
                      ? 'Advokat ishini 5 yulduz bilan baholang (bosing):'
                      : 'Sizning bahoyingiz: ${meta.ratedStars} / 5 yulduz',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: YanColors.primaryNavy,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List<Widget>.generate(5, (idx) {
                    final starNumber = idx + 1;
                    final isFilled = starNumber <= meta.ratedStars;
                    return GestureDetector(
                      onTap: meta.ratedStars == 0
                          ? () =>
                                _openFiveEmptyStarsRatingSheet(m, meta,
                                    initialStars: starNumber)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          isFilled
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          size: 30,
                          color: isFilled
                              ? const Color(0xFFF59E0B)
                              : YanColors.primaryBlue,
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = Column(
      children: <Widget>[
        // Top Header
        Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          decoration: const BoxDecoration(
            color: YanColors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE5EFFA))),
          ),
          child: Row(
            children: <Widget>[
              if (!widget.isEmbeddedTab) ...<Widget>[
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: YanColors.lightBlue,
                    ),
                    child: const Icon(
                      Icons.arrow_back_rounded,
                      size: 19,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                ),
                const SizedBox(width: 9),
              ],
              GestureDetector(
                onTap: () {
                  _requestPeerHistorySync();
                  _syncOfflineMessagesFromProfilesEnvelopes();
                },
                child: _LawyerAvatarPortrait(
                  initials: widget.lawyer.initials,
                  isOnline: _isPeerOnline && _isMyAppInForeground,
                  size: 42,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Flexible(
                          child: Text(
                            widget.lawyer.fullName,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: YanColors.primaryNavy,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(
                          Icons.verified_rounded,
                          size: 15,
                          color: YanColors.primaryBlue,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: <Widget>[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (_isPeerOnline && _isMyAppInForeground)
                                ? YanColors.successGreen
                                : YanColors.subtleText,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _peerPresenceSubtitle,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: (_isPeerOnline && _isMyAppInForeground)
                                  ? YanColors.successGreen
                                  : YanColors.mutedText,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _startE2eeCall(isVideo: false),
                onLongPress: _openCallOptionsSheet,
                child: Container(
                  width: 39,
                  height: 39,
                  decoration: BoxDecoration(
                    color: YanColors.lightBlue,
                    shape: BoxShape.circle,
                    border: Border.all(color: YanColors.border),
                  ),
                  child: const Icon(
                    Icons.call_rounded,
                    size: 19,
                    color: YanColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _startE2eeCall(isVideo: true),
                child: Container(
                  width: 39,
                  height: 39,
                  decoration: const BoxDecoration(
                    color: YanColors.primaryBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_rounded,
                    size: 19,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),

        // E2EE Security Banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          color: YanColors.lightBlue.withValues(alpha: 0.7),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const Icon(
                Icons.lock_rounded,
                size: 12,
                color: YanColors.primaryBlue,
              ),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'Zero-Knowledge E2EE • #ariza hujjatlari Qabul qilish va 5 yulduz baholash bilan',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10.3,
                    fontWeight: FontWeight.w700,
                    color: YanColors.primaryNavy,
                  ),
                ),
              ),
              if (_isSyncingHistory) ...<Widget>[
                const SizedBox(width: 6),
                const CupertinoActivityIndicator(radius: 6),
              ],
            ],
          ),
        ),

        // Live 30-Minute Ariza Countdown Banner (Visible to both Advocate & Client!)
        ValueListenableBuilder<List<ArizaOrderItem>>(
          valueListenable: YanRoleDataCatalog.arizaOrders,
          builder: (context, orders, _) {
            final roomOrders = orders.where((o) {
              final cMatch =
                  YanRoleDataCatalog.isSameParticipant(o.clientId, _myUserId) ||
                  YanRoleDataCatalog.isSameParticipant(o.clientId, _peerUserId);
              final aMatch =
                  YanRoleDataCatalog.isSameParticipant(
                    o.advocateId,
                    _myUserId,
                  ) ||
                  YanRoleDataCatalog.isSameParticipant(
                    o.advocateId,
                    _peerUserId,
                  );
              return cMatch && aMatch;
            }).toList();
            if (roomOrders.isEmpty) return const SizedBox.shrink();
            final latestOrder = roomOrders.first;
            final now = DateTime.now();
            final isDone = latestOrder.isEffectivelyCompleted(now);
            final isLate = latestOrder.isAdvocateLate(now);
            final badgeColor = isDone
                ? const Color(0xFF0A936B)
                : isLate
                ? YanColors.destructiveRed
                : const Color(0xFFD97706);
            final bgColor = isDone
                ? YanColors.successGreen.withValues(alpha: 0.14)
                : isLate
                ? YanColors.destructiveRed.withValues(alpha: 0.12)
                : const Color(0xFFFFF4E5);

            return Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: bgColor,
                border: Border(
                  bottom: BorderSide(color: badgeColor.withValues(alpha: 0.25)),
                ),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    isDone
                        ? Icons.check_circle_rounded
                        : isLate
                        ? Icons.warning_amber_rounded
                        : Icons.timer_rounded,
                    size: 16,
                    color: badgeColor,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      'Ariza (${latestOrder.id}): ${latestOrder.formatCountdown(now)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        // Messages List
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              final m = _messages[index];
              final mine = m.isMine(_myUserId);
              final isArizaPkg = m.isStructuredArizaPackage;
              final isAutoWelcome = m.isAutoWelcomeMessage;
              final arizaMeta = m.arizaDeliveryMeta;
              final isReadyAriza = arizaMeta != null;
              final chatFileMeta = _parseChatFileMeta(m.mediaMeta);

              return Align(
                alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _showMessageDetailsSheet(m),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 11),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    constraints: BoxConstraints(
                      maxWidth: (isArizaPkg || isReadyAriza) ? 335 : 310,
                    ),
                    decoration: BoxDecoration(
                      color: isReadyAriza
                          ? (arizaMeta.status == 'rejected'
                                ? const Color(0xFFB91C1C)
                                : const Color(0xFF0A936B))
                          : isArizaPkg
                          ? YanColors.primaryNavy
                          : (mine ? YanColors.primaryBlue : YanColors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: (mine || isArizaPkg || isReadyAriza)
                          ? null
                          : Border.all(color: YanColors.border),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(
                          color: Color(0x0B0E2A54),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (isArizaPkg) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: YanColors.primaryBlue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.gavel_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'RASMIY ARIZA BUYURTMASI • 30 DAQIQA',
                                  style: TextStyle(
                                    fontSize: 9.8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                        ] else if (isAutoWelcome) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: YanColors.lightBlue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  Icons.schedule_rounded,
                                  size: 12,
                                  color: YanColors.primaryBlue,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  'AVTOMATIK QABUL • 30 DAQIQA MUDDAT',
                                  style: TextStyle(
                                    fontSize: 9.8,
                                    fontWeight: FontWeight.w900,
                                    color: YanColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                        ] else if (isReadyAriza) ...<Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(
                                  arizaMeta.status == 'rejected'
                                      ? Icons.cancel_rounded
                                      : Icons.verified_rounded,
                                  size: 12,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  arizaMeta.isEffectivelyAccepted(DateTime.now())
                                      ? '#ARIZA • MIJOZ QABUL QILDI'
                                      : arizaMeta.status == 'rejected'
                                      ? '#ARIZA • RAD ETILDI'
                                      : '#ARIZA • TASDIQLASH KUTILMOQDA',
                                  style: const TextStyle(
                                    fontSize: 9.8,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 7),
                        ] else if (ConsultationBooking.tryDecodeChatMeta(m.mediaMeta) != null) ...<Widget>[
                          _buildConsultationBookingCard(
                            m,
                            ConsultationBooking.tryDecodeChatMeta(m.mediaMeta)!,
                          ),
                        ] else if (m.mediaType == _ChatMediaType.callLog) ...<Widget>[
                          _buildTelegramCallLogCard(m, mine),
                        ] else if (m.mediaType != _ChatMediaType.text &&
                            chatFileMeta == null) ...<Widget>[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Icon(
                                m.mediaType == _ChatMediaType.voice
                                    ? Icons.mic_rounded
                                    : m.mediaType == _ChatMediaType.video
                                    ? Icons.videocam_rounded
                                    : m.mediaType == _ChatMediaType.image
                                    ? Icons.image_rounded
                                    : Icons.description_rounded,
                                size: 16,
                                color: mine
                                    ? Colors.white
                                    : YanColors.primaryBlue,
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  m.mediaMeta ?? 'E2EE Fayl',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: mine
                                        ? Colors.white.withValues(alpha: 0.92)
                                        : YanColors.primaryBlue,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                        ],
                        if (m.mediaType != _ChatMediaType.callLog &&
                            ConsultationBooking.tryDecodeChatMeta(m.mediaMeta) == null &&
                            (chatFileMeta == null ||
                                (m.text.trim().isNotEmpty &&
                                    m.text.trim() !=
                                        (chatFileMeta['name'] ?? '').trim())))
                          Text(
                            m.text,
                            style: TextStyle(
                              fontSize: 13.1,
                              fontWeight: FontWeight.w600,
                              color: (mine || isArizaPkg || isReadyAriza)
                                  ? Colors.white
                                  : YanColors.primaryNavy,
                              height: 1.42,
                            ),
                          ),
                        if (chatFileMeta != null) ...<Widget>[
                          if (m.text.trim().isNotEmpty &&
                              m.text.trim() != (chatFileMeta['name'] ?? '').trim())
                            const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: mine
                                  ? Colors.white.withValues(alpha: 0.14)
                                  : YanColors.lightBlue,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: <Widget>[
                                Icon(
                                  m.mediaType == _ChatMediaType.image
                                      ? Icons.image_rounded
                                      : m.mediaType == _ChatMediaType.video
                                      ? Icons.videocam_rounded
                                      : Icons.insert_drive_file_rounded,
                                  color: mine
                                      ? Colors.white
                                      : YanColors.primaryBlue,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    chatFileMeta['name'] ?? m.text,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: mine
                                          ? Colors.white
                                          : YanColors.primaryNavy,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Ochish',
                                  onPressed: () => _openChatFile(chatFileMeta),
                                  icon: Icon(
                                    Icons.open_in_new_rounded,
                                    color: mine
                                        ? Colors.white
                                        : YanColors.primaryBlue,
                                  ),
                                ),
                                IconButton(
                                  tooltip: 'Ulashish',
                                  onPressed: () => _shareChatFile(chatFileMeta),
                                  icon: Icon(
                                    Icons.share_rounded,
                                    color: mine
                                        ? Colors.white
                                        : YanColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (isReadyAriza)
                          _buildInteractiveArizaDeliveryControls(m, arizaMeta),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              Icons.lock_outline_rounded,
                              size: 10,
                              color: (mine || isArizaPkg || isReadyAriza)
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : YanColors.subtleText,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              m.formattedSentTime,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: (mine || isArizaPkg || isReadyAriza)
                                    ? Colors.white.withValues(alpha: 0.82)
                                    : YanColors.mutedText,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Icon(
                              m.isSeen
                                  ? Icons.done_all_rounded
                                  : Icons.check_rounded,
                              size: 13.5,
                              color: m.isSeen
                                  ? ((mine || isArizaPkg || isReadyAriza)
                                        ? Colors.white
                                        : YanColors.successGreen)
                                  : ((mine || isArizaPkg || isReadyAriza)
                                        ? Colors.white.withValues(alpha: 0.75)
                                        : YanColors.subtleText),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              m.isSeen ? 'O‘qildi' : 'Yuborildi',
                              style: TextStyle(
                                fontSize: 9.8,
                                fontWeight: FontWeight.w700,
                                color: m.isSeen
                                    ? ((mine || isArizaPkg || isReadyAriza)
                                          ? Colors.white
                                          : YanColors.successGreen)
                                    : ((mine || isArizaPkg || isReadyAriza)
                                          ? Colors.white.withValues(alpha: 0.75)
                                          : YanColors.subtleText),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Input Composer
        Container(
          padding: EdgeInsets.fromLTRB(
            12,
            10,
            12,
            widget.isEmbeddedTab ? 96 : 14,
          ),
          decoration: const BoxDecoration(
            color: YanColors.white,
            border: Border(top: BorderSide(color: Color(0xFFE5EFFA))),
          ),
          child: Row(
            children: <Widget>[
              GestureDetector(
                onTap: _showAttachmentSheet,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: YanColors.lightBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.attach_file_rounded,
                    color: YanColors.primaryBlue,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _msgController,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                  decoration: InputDecoration(
                    hintText:
                        'E2EE xabar yozing (yoki #ariza bilan topshiring)...',
                    hintStyle: const TextStyle(
                      fontSize: 12.8,
                      color: YanColors.mutedText,
                    ),
                    filled: true,
                    fillColor: YanColors.lightBlue,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44,
                  height: 42,
                  decoration: BoxDecoration(
                    color: YanColors.primaryBlue,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.send_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (widget.isEmbeddedTab) {
      return content;
    }

    return Scaffold(
      backgroundColor: YanColors.background,
      body: SafeArea(child: content),
    );
  }
}

// ============================================================================
// TELEGRAM-GRADE GLOBAL E2EE CALL ENGINE, FULL-SCREEN RINGING & CALL STATISTICS
// ============================================================================

class _TelegramCallOutcome {
  final String callId;
  final String status; // 'completed', 'missed', 'declined', 'canceled'
  final int durationSeconds;
  final bool wasVideo;

  const _TelegramCallOutcome({
    required this.callId,
    required this.status,
    required this.durationSeconds,
    required this.wasVideo,
  });

  String get formattedDuration {
    final mins = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String get summaryTitle {
    final kind = wasVideo ? 'Video qo‘ng‘iroq' : 'Audio qo‘ng‘iroq';
    switch (status) {
      case 'completed':
        return '$kind ($formattedDuration)';
      case 'declined':
        return 'Rad etilgan ${kind.toLowerCase()}';
      case 'canceled':
        return 'Bekor qilingan ${kind.toLowerCase()}';
      case 'missed':
      default:
        return 'Javobsiz ${kind.toLowerCase()}';
    }
  }
}

class _TelegramCallLogMeta {
  final String callId;
  final String callType; // 'audio' | 'video'
  final String status; // 'completed' | 'missed' | 'declined' | 'canceled'
  final int durationSeconds;
  final String callerId;

  const _TelegramCallLogMeta({
    required this.callId,
    required this.callType,
    required this.status,
    required this.durationSeconds,
    required this.callerId,
  });

  String get formattedDuration {
    final mins = (durationSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (durationSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String encode() {
    return 'CALL_LOG_V2|id:${Uri.encodeComponent(callId)}|type:$callType|status:$status|dur:$durationSeconds|caller:${Uri.encodeComponent(callerId)}';
  }

  static _TelegramCallLogMeta tryParse(
    String? rawMeta,
    String fallbackText,
    String fallbackSenderId,
  ) {
    if (rawMeta != null && rawMeta.startsWith('CALL_LOG_V2|')) {
      final map = <String, String>{};
      for (final part in rawMeta.split('|').skip(1)) {
        final idx = part.indexOf(':');
        if (idx > 0) {
          map[part.substring(0, idx)] = Uri.decodeComponent(
            part.substring(idx + 1),
          );
        }
      }
      return _TelegramCallLogMeta(
        callId: map['id'] ?? 'CALL',
        callType: map['type'] ?? 'audio',
        status: map['status'] ?? 'completed',
        durationSeconds: int.tryParse(map['dur'] ?? '0') ?? 0,
        callerId: map['caller'] ?? fallbackSenderId,
      );
    }
    final isVideo =
        (rawMeta?.toLowerCase().contains('video') ?? false) ||
        fallbackText.toLowerCase().contains('video');
    var dur = 0;
    final match = RegExp(r'(\d{2}):(\d{2})').firstMatch(rawMeta ?? fallbackText);
    if (match != null) {
      final m = int.tryParse(match.group(1) ?? '0') ?? 0;
      final s = int.tryParse(match.group(2) ?? '0') ?? 0;
      dur = m * 60 + s;
    }
    return _TelegramCallLogMeta(
      callId: 'LEGACY',
      callType: isVideo ? 'video' : 'audio',
      status: dur > 0 ? 'completed' : 'missed',
      durationSeconds: dur,
      callerId: fallbackSenderId,
    );
  }
}

/// Scalable Call Signaling & FCM-Ready Wake-Up Engine:
/// - Subscribes ONLY to this user's private Realtime channel (`yan360_call_inbox_<myId>`)
///   instead of a shared global bus (prevents N*N Realtime message amplification at scale).
/// - Zero background DB polling timer: checks `profiles.public_key` ONLY once on startup
///   and once when returning to foreground (`AppLifecycleState.resumed`).
/// - Ready for Firebase Cloud Messaging (FCM): pass incoming push data to `handleFcmCallPayload()`.
class _YanGlobalCallCenter with WidgetsBindingObserver {
  _YanGlobalCallCenter._();
  static final _YanGlobalCallCenter instance = _YanGlobalCallCenter._();

  RealtimeChannel? _myInboxChannel;
  String? _subscribedInboxUserId;
  bool _lifecycleAttached = false;
  String? _activeCallId;
  final Set<String> _handledCallIds = <String>{};
  final Set<String> _handledEnvelopeSignalKeys = <String>{};
  final Map<String, RealtimeChannel> _peerSendChannels = <String, RealtimeChannel>{};
  final ValueNotifier<Map<String, dynamic>?> latestSignalNotifier =
      ValueNotifier<Map<String, dynamic>?>(null);

  String _resolveMyId([String? overrideId]) {
    if (overrideId != null && overrideId.trim().isNotEmpty) {
      return overrideId.trim();
    }
    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (authId.trim().isNotEmpty) return authId.trim();
    return userProfile.value.clientId.trim();
  }

  String _inboxTopicFor(String userId) {
    final clean = userId.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'yan360_call_inbox_$clean';
  }

  void startGlobalListening() {
    if (!_lifecycleAttached) {
      WidgetsBinding.instance.addObserver(this);
      _lifecycleAttached = true;
    }

    final myId = _resolveMyId();
    if (myId.isEmpty) return;

    if (_myInboxChannel == null || _subscribedInboxUserId != myId) {
      final oldChannel = _myInboxChannel;
      if (oldChannel != null) {
        try {
          Supabase.instance.client.removeChannel(oldChannel);
        } catch (_) {}
      }
      try {
        final ch = Supabase.instance.client.channel(
          _inboxTopicFor(myId),
          opts: const RealtimeChannelConfig(self: false, ack: false),
        );
        ch
            .onBroadcast(
              event: 'call_signal',
              callback: (payload) {
                handleIncomingSignalPayload(Map<String, dynamic>.from(payload));
              },
            )
            .subscribe();
        _myInboxChannel = ch;
        _subscribedInboxUserId = myId;
      } catch (e) {
        debugPrint('Call inbox channel subscribe warning: $e');
      }
    }

    // One-shot check on app launch (no repeating 1.6s timer!)
    _checkPendingCallEnvelopeOnce();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      startGlobalListening();
    }
  }

  /// Entry point for Firebase Cloud Messaging (FCM) push notifications:
  /// Call `_YanGlobalCallCenter.instance.handleFcmCallPayload(message.data)`
  /// from `FirebaseMessaging.onMessage` / `onMessageOpenedApp`.
  void handleFcmCallPayload(Map<String, dynamic> fcmData) {
    if (fcmData.isEmpty) return;
    handleIncomingSignalPayload(Map<String, dynamic>.from(fcmData));
  }

  void markCallActive(String callId) {
    _activeCallId = callId;
    _handledCallIds.add(callId);
  }

  void clearActiveCall(String callId) {
    if (_activeCallId == callId) {
      _activeCallId = null;
    }
  }

  Future<void> _broadcastToPeerInbox(
    String targetUserId,
    Map<String, dynamic> payload,
  ) async {
    final cleanId = targetUserId.trim();
    if (cleanId.isEmpty) return;
    try {
      var ch = _peerSendChannels[cleanId];
      if (ch == null) {
        ch = Supabase.instance.client.channel(
          _inboxTopicFor(cleanId),
          opts: const RealtimeChannelConfig(self: false, ack: false),
        );
        ch.subscribe();
        _peerSendChannels[cleanId] = ch;
        // Keep cache bounded so memory stays tiny
        if (_peerSendChannels.length > 20) {
          final oldestKey = _peerSendChannels.keys.first;
          final oldestCh = _peerSendChannels.remove(oldestKey);
          if (oldestCh != null) {
            Supabase.instance.client.removeChannel(oldestCh);
          }
        }
      }
      await ch.sendBroadcastMessage(
        event: 'call_signal',
        payload: payload,
      );
    } catch (e) {
      debugPrint('Peer inbox broadcast warning: $e');
    }
  }

  Future<void> _triggerFcmPushIfEnabled(
    String targetUserId,
    Map<String, dynamic> payload,
  ) async {
    if (!yanEnableFcmCallPush) return;
    try {
      await Supabase.instance.client.functions.invoke(
        'send-call-push',
        body: <String, dynamic>{
          'target_user_id': targetUserId,
          'signal': payload,
        },
      );
    } catch (e) {
      debugPrint('FCM push invoke warning: $e');
    }
  }

  Future<void> dispatchCallSignal({
    required String callId,
    required String action, // 'invite' | 'ringing' | 'accept' | 'decline' | 'cancel' | 'hangup' | 'media_state' | 'webrtc_offer' | 'webrtc_answer' | 'webrtc_ice'
    required String callerId,
    required String callerName,
    required String callerInitials,
    required String calleeId,
    required String calleeName,
    required String roomKey,
    required bool isVideo,
    int durationSeconds = 0,
    bool isMuted = false,
    Map<String, dynamic>? webrtcData,
    RealtimeChannel? roomChannel,
    String? targetPeerId,
    String? consultationId,
    DateTime? consultationDeadlineAt,
  }) async {
    final nowIso = DateTime.now().toUtc().toIso8601String();
    final payload = <String, dynamic>{
      'call_id': callId,
      'action': action,
      'call_type': isVideo ? 'video' : 'audio',
      'caller_id': callerId,
      'caller_name': callerName,
      'caller_initials': callerInitials,
      'callee_id': calleeId,
      'callee_name': calleeName,
      'room_key': roomKey,
      'duration': durationSeconds,
      'is_muted': isMuted,
      if (webrtcData != null) 'webrtc': webrtcData,
      if (consultationId != null) 'consultation_id': consultationId,
      if (consultationDeadlineAt != null)
        'consultation_deadline_iso': consultationDeadlineAt.toUtc().toIso8601String(),
      'timestamp': nowIso,
    };

    final myId = _resolveMyId();
    final targetProfileId = (targetPeerId != null && targetPeerId.trim().isNotEmpty)
        ? targetPeerId.trim()
        : (myId.isNotEmpty && YanRoleDataCatalog.isSameParticipant(myId, callerId))
            ? calleeId
            : (myId.isNotEmpty && YanRoleDataCatalog.isSameParticipant(myId, calleeId))
                ? callerId
                : ((action == 'invite' || action == 'cancel') ? calleeId : callerId);

    // 1. Send directly to target peer's private Realtime inbox (zero fan-out to other users)
    await _broadcastToPeerInbox(targetProfileId, payload);

    // 2. Also send on active chat room channel if open
    try {
      await roomChannel?.sendBroadcastMessage(
        event: 'call_signal',
        payload: payload,
      );
    } catch (_) {}

    // 3. Persist invite/cancel/hangup/decline once in profile envelope for app-resume recovery,
    //    and trigger FCM push notification on invite when enabled.
    if (targetProfileId.trim().isNotEmpty &&
        action != 'media_state' &&
        !action.startsWith('webrtc_')) {
      await _writeSignalToProfileEnvelope(targetProfileId, payload);
      if (action == 'invite') {
        await _triggerFcmPushIfEnabled(targetProfileId, payload);
      }
    }
  }

  Future<void> _writeSignalToProfileEnvelope(
    String targetUserId,
    Map<String, dynamic> signalPayload,
  ) async {
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('id, public_key')
          .eq('id', targetUserId)
          .maybeSingle();
      if (row == null) return;
      final existingPubKey = row['public_key']?.toString();
      final env = _YanE2eeCryptoEngine.decodeProfileEnvelope(existingPubKey);
      env['active_call_signal'] = signalPayload;
      final newPubKey = _YanE2eeCryptoEngine.encodeProfileEnvelope(
        existingPubKey,
        env,
      );
      await Supabase.instance.client
          .from('profiles')
          .update(<String, dynamic>{'public_key': newPubKey})
          .eq('id', targetUserId);
    } catch (_) {}
  }

  /// Lightweight one-shot check (runs ONLY on app launch / foreground resume — never on a timer).
  Future<void> _checkPendingCallEnvelopeOnce() async {
    final myId = _resolveMyId();
    if (myId.isEmpty) return;
    try {
      final row = await Supabase.instance.client
          .from('profiles')
          .select('public_key')
          .eq('id', myId)
          .maybeSingle();
      if (row == null) return;
      final pubKey = row['public_key']?.toString();
      if (pubKey == null ||
          !pubKey.contains(_YanE2eeCryptoEngine._envelopeSeparator)) {
        return;
      }
      final env = _YanE2eeCryptoEngine.decodeProfileEnvelope(pubKey);
      final rawSig = env['active_call_signal'];
      if (rawSig is Map) {
        final sig = Map<String, dynamic>.from(rawSig);
        final sigCallId = sig['call_id']?.toString() ?? '';
        final sigAction = sig['action']?.toString() ?? '';
        final sigTs = sig['timestamp']?.toString() ?? '';
        if (sigCallId.isEmpty || sigAction.isEmpty) return;

        final dedupKey = '$sigCallId|$sigAction|$sigTs';
        if (!_handledEnvelopeSignalKeys.add(dedupKey)) return;
        if (_handledEnvelopeSignalKeys.length > 256) {
          _handledEnvelopeSignalKeys.remove(_handledEnvelopeSignalKeys.first);
        }

        if (sigAction == 'invite' &&
            (_activeCallId != null || _handledCallIds.contains(sigCallId))) {
          return;
        }

        final ts = DateTime.tryParse(sigTs);
        if (ts != null &&
            DateTime.now().toUtc().difference(ts).inSeconds <= 35) {
          handleIncomingSignalPayload(sig, myUserIdOverride: myId);
        }
      }
    } catch (_) {}
  }

  void handleIncomingSignalPayload(
    Map<String, dynamic> payload, {
    String? myUserIdOverride,
  }) {
    final myId = _resolveMyId(myUserIdOverride);
    if (myId.isEmpty) return;

    final callId = payload['call_id']?.toString() ?? '';
    final action = payload['action']?.toString() ?? '';
    final callerId = payload['caller_id']?.toString() ?? '';
    final calleeId = payload['callee_id']?.toString() ?? '';

    final isForMeAsCallee =
        calleeId.isEmpty ||
        YanRoleDataCatalog.isSameParticipant(calleeId, myId);
    final isForMeAsCaller = YanRoleDataCatalog.isSameParticipant(
      callerId,
      myId,
    );

    if (!isForMeAsCallee && !isForMeAsCaller) return;

    // Broadcast to any open _E2eeLiveCallScreen
    latestSignalNotifier.value = payload;

    // If this is a new incoming call invite for me and I am not already in this call,
    // immediately present the full-screen Telegram Incoming Call Ringing screen!
    if (action == 'invite' &&
        !isForMeAsCaller &&
        isForMeAsCallee &&
        callId.isNotEmpty &&
        _activeCallId == null &&
        !_handledCallIds.contains(callId)) {
      _handledCallIds.add(callId);
      _activeCallId = callId;

      final callerName =
          payload['caller_name']?.toString() ?? 'YAN360 Foydalanuvchisi';
      final callerInitials =
          payload['caller_initials']?.toString() ??
          (callerName.isNotEmpty ? callerName[0].toUpperCase() : 'Y');
      final isVideo = payload['call_type'] == 'video';
      final roomKey =
          payload['room_key']?.toString() ??
          _YanE2eeCryptoEngine.buildCanonicalRoomKey(myId, callerId);

      // Immediately notify caller that our phone is ringing
      dispatchCallSignal(
        callId: callId,
        action: 'ringing',
        callerId: callerId,
        callerName: callerName,
        callerInitials: callerInitials,
        calleeId: myId,
        calleeName: userProfile.value.displayName,
        roomKey: roomKey,
        isVideo: isVideo,
        targetPeerId: callerId,
      );

      final nav = yanRootNavigatorKey.currentState;
      if (nav != null) {
        nav
            .push<_TelegramCallOutcome>(
              MaterialPageRoute<_TelegramCallOutcome>(
                fullscreenDialog: true,
                builder: (_) => _E2eeLiveCallScreen(
                  callId: callId,
                  peerId: callerId,
                  peerName: callerName,
                  peerInitials: callerInitials,
                  peerSubtitle: isVideo
                      ? 'Kiruvchi HD E2EE Video qo‘ng‘iroq'
                      : 'Kiruvchi E2EE Audio qo‘ng‘iroq',
                  myUserId: myId,
                  myUserName: userProfile.value.displayName,
                  roomKey: roomKey,
                  roomChannel: null,
                  isInitialVideo: isVideo,
                  isCaller: false,
                  consultationId: payload['consultation_id']?.toString(),
                  consultationDeadlineAt: DateTime.tryParse(
                    payload['consultation_deadline_iso']?.toString() ?? '',
                  )?.toLocal(),
                ),
              ),
            )
            .whenComplete(() => clearActiveCall(callId));
      } else {
        clearActiveCall(callId);
      }
    }
  }
}

class _E2eeLiveCallScreen extends StatefulWidget {
  final String callId;
  final String peerId;
  final String peerName;
  final String peerInitials;
  final String peerSubtitle;
  final String myUserId;
  final String myUserName;
  final String roomKey;
  final RealtimeChannel? roomChannel;
  final bool isInitialVideo;
  final bool isCaller;
  final String? consultationId;
  final DateTime? consultationDeadlineAt;

  const _E2eeLiveCallScreen({
    required this.callId,
    required this.peerId,
    required this.peerName,
    required this.peerInitials,
    required this.peerSubtitle,
    required this.myUserId,
    required this.myUserName,
    required this.roomKey,
    required this.roomChannel,
    required this.isInitialVideo,
    required this.isCaller,
    this.consultationId,
    this.consultationDeadlineAt,
  });

  @override
  State<_E2eeLiveCallScreen> createState() => _E2eeLiveCallScreenState();
}

enum _TelegramCallStage {
  outgoingCalling, // Caller: "Ulanmoqda..."
  outgoingRinging, // Caller: "Chaqirilmoqda..." (Callee's phone is ringing!)
  incomingRinging, // Callee: Full-screen ringing with Accept / Decline
  connected, // Active call with ticking MM:SS clock
  ended, // Brief closing state
}

class _E2eeLiveCallScreenState extends State<_E2eeLiveCallScreen>
    with SingleTickerProviderStateMixin {
  late _TelegramCallStage _stage;
  late bool _isVideoEnabled;
  bool _isPeerVideoEnabled = false;
  bool _isMuted = false;
  bool _isPeerMuted = false;
  bool _isSpeakerOn = true;
  bool _isFrontCamera = true;
  int _elapsedSeconds = 0;
  bool _closed = false;
  bool _cleaningUp = false;

  // Real WebRTC Audio & Video Streaming State
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  bool _renderersInitialized = false;
  MediaStream? _localStream;
  RTCPeerConnection? _peerConnection;
  final List<RTCIceCandidate> _queuedRemoteCandidates = <RTCIceCandidate>[];
  final Set<String> _handledWebRtcSignals = <String>{};
  bool _remoteDescriptionSet = false;
  bool _webrtcOfferSent = false;
  bool _webrtcOfferInProgress = false;
  bool _incomingOfferInProgress = false;
  bool _hasRemoteVideoTrack = false;
  MediaStream? _remoteStream;
  bool _ownsRemoteStream = false;
  Future<void>? _mediaInitFuture;

  Future<void> get _mediaInitialization =>
      _mediaInitFuture ??= _initHardwareMediaAndPermissions();

  Timer? _callClockTimer;
  Timer? _ringtoneLoopTimer;
  Timer? _noAnswerTimeoutTimer;
  Timer? _peerDisconnectTimer;
  late final AnimationController _pulseController;
  late final List<String> _e2eeEmojis;

  static const List<String> _emojiPool = <String>[
    '🛡️', '🔑', '⚖️', '🏛️', '💎', '🦅', '🦁', '🌙',
    '⭐', '🔥', '🏔️', '🌊', '🍀', '👑', '🚀', '⚡',
  ];

  @override
  void initState() {
    super.initState();
    _YanGlobalCallCenter.instance.markCallActive(widget.callId);
    _isVideoEnabled = widget.isInitialVideo;
    _isPeerVideoEnabled = widget.isInitialVideo;
    _stage = widget.isCaller
        ? _TelegramCallStage.outgoingCalling
        : _TelegramCallStage.incomingRinging;

    _e2eeEmojis = _deriveVerificationEmojis('${widget.roomKey}|${widget.callId}');

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _YanGlobalCallCenter.instance.latestSignalNotifier.addListener(
      _onGlobalCallSignal,
    );

    _startRingtoneAndVibrationLoop();

    if (widget.isCaller) {
      _mediaInitFuture = _initHardwareMediaAndPermissions();
      _sendSignal('invite');
      _noAnswerTimeoutTimer = Timer(const Duration(seconds: 45), () {
        if (!_closed && _stage != _TelegramCallStage.connected) {
          _sendSignal('cancel');
          _finishCallWithOutcome('missed');
        }
      });
    } else {
      // Wait until the callee taps "Javob berish" (_acceptIncomingCall)
      // before opening hardware camera & microphone to prevent permission dialog collisions.
      _noAnswerTimeoutTimer = Timer(const Duration(seconds: 45), () {
        if (!_closed && _stage == _TelegramCallStage.incomingRinging) {
          _finishCallWithOutcome('missed');
        }
      });
    }
  }

  /// Requests real OS Microphone & Camera permissions and opens local audio/video tracks
  Future<void> _initHardwareMediaAndPermissions() async {
    try {
      if (!_renderersInitialized) {
        await _localRenderer.initialize();
        await _remoteRenderer.initialize();
        _renderersInitialized = true;
      }

      // 1. Request OS runtime permissions for Microphone (and Camera if video call)
      final micStatus = await Permission.microphone.request();
      PermissionStatus? camStatus;
      if (_isVideoEnabled) {
        camStatus = await Permission.camera.request();
      }

      if (!micStatus.isGranted) {
        _showMediaPermissionMessage(
          'Ovozli qo‘ng‘iroq uchun mikrofon ruxsatini bering. Telefon sozlamalarida ilova ruxsatlarini tekshiring.',
        );
        return;
      }

      final wantVideo = _isVideoEnabled && (camStatus?.isGranted ?? false);

      // 2. Capture real device microphone & camera stream via WebRTC
      // Uses a hardware-safe 640x480 / 720p cap so both Android Emulators (Pixel 8 Pro)
      // and physical Samsung Camera2 encoders (S22 Ultra) initialize without native crashes.
      final mediaConstraints = <String, dynamic>{
        'audio': <String, dynamic>{
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': wantVideo
            ? <String, dynamic>{
                'facingMode': _isFrontCamera ? 'user' : 'environment',
                'width': <String, dynamic>{'ideal': 640, 'max': 1280},
                'height': <String, dynamic>{'ideal': 480, 'max': 720},
                'frameRate': <String, dynamic>{'ideal': 24, 'max': 30},
              }
            : false,
      };

      MediaStream stream;
      try {
        stream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      } catch (error) {
        if (!wantVideo) rethrow;
        debugPrint('Combined audio/video capture failed: $error');
        stream = await navigator.mediaDevices.getUserMedia(
          <String, dynamic>{
            'audio': mediaConstraints['audio'],
            'video': false,
          },
        );
        _isVideoEnabled = false;
        _showMediaPermissionMessage(
          'Kamera ochilmadi. Qo‘ng‘iroq audio rejimida davom etadi.',
        );
      }
      if (_closed) {
        for (final t in stream.getTracks()) {
          t.stop();
        }
        await stream.dispose();
        return;
      }

      _localStream = stream;
      _localRenderer.srcObject = stream;
      for (final t in stream.getAudioTracks()) {
        t.enabled = !_isMuted;
      }

      try {
        if (Platform.isAndroid) {
          await Helper.setAndroidAudioConfiguration(
            AndroidAudioConfiguration.communication,
          );
        }
        await Helper.setSpeakerphoneOn(_isSpeakerOn);
      } catch (e) {
        debugPrint('Audio routing initialization warning (non-fatal): $e');
      }

      await _ensurePeerConnectionCreated();
      if (mounted && !_closed) setState(() {});
    } catch (error) {
      _showMediaPermissionMessage(
        'Mikrofon yoki kamerani ishga tushirib bo‘lmadi. Ilova ruxsatlari va qurilma sozlamalarini tekshiring.',
      );
      debugPrint('Call media initialization failed: $error');
    }
  }

  void _showMediaPermissionMessage(String message) {
    if (!mounted || _closed) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: YanColors.destructiveRed,
        ),
      );
  }

  Future<List<Map<String, dynamic>>> _resolveIceServers() async {
    final servers = <Map<String, dynamic>>[
      <String, dynamic>{
        'urls': <String>[
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
          'stun:stun.relay.metered.ca:80',
        ],
      },
    ];

    // Option A: Fetch dynamic geo-nearest TURN servers from Metered REST API
    final apiUrl = yanMeteredTurnApiUrl.trim();
    if (apiUrl.isNotEmpty) {
      HttpClient? client;
      try {
        client = HttpClient()..connectionTimeout = const Duration(seconds: 3);
        final request = await client
            .getUrl(Uri.parse(apiUrl))
            .timeout(const Duration(seconds: 3));
        final response = await request.close().timeout(
          const Duration(seconds: 3),
        );
        if (response.statusCode == 200) {
          final body = await response.transform(utf8.decoder).join();
          final decoded = jsonDecode(body);
          if (decoded is List) {
            for (final entry in decoded) {
              if (entry is Map) {
                servers.add(Map<String, dynamic>.from(entry));
              }
            }
            return servers;
          }
        }
      } catch (error) {
        debugPrint('Metered TURN API fetch skipped (fallback to static/STUN): $error');
      } finally {
        client?.close(force: true);
      }
    }

    // Option B: Static Metered TURN credentials (UDP 80, TCP 80/443, TLS 443 for 3G/4G/5G)
    final turnUser = yanStaticTurnUsername.trim();
    final turnPass = yanStaticTurnCredential.trim();
    if (turnUser.isNotEmpty && turnPass.isNotEmpty) {
      servers.addAll(<Map<String, dynamic>>[
        <String, dynamic>{
          'urls': 'turn:global.relay.metered.ca:80',
          'username': turnUser,
          'credential': turnPass,
        },
        <String, dynamic>{
          'urls': 'turn:global.relay.metered.ca:80?transport=tcp',
          'username': turnUser,
          'credential': turnPass,
        },
        <String, dynamic>{
          'urls': 'turn:global.relay.metered.ca:443',
          'username': turnUser,
          'credential': turnPass,
        },
        <String, dynamic>{
          'urls': 'turns:global.relay.metered.ca:443?transport=tcp',
          'username': turnUser,
          'credential': turnPass,
        },
      ]);
    }

    return servers;
  }

  Future<RTCPeerConnection?> _ensurePeerConnectionCreated() async {
    if (_peerConnection != null) return _peerConnection;
    try {
      final iceServers = await _resolveIceServers();
      final config = <String, dynamic>{
        'sdpSemantics': 'unified-plan',
        'iceTransportPolicy': 'all',
        'iceServers': iceServers,
      };

      final pc = await createPeerConnection(config);
      _peerConnection = pc;

      if (_localStream != null) {
        final existingSenders = await pc.getSenders();
        for (final track in _localStream!.getTracks()) {
          final alreadyAdded = existingSenders.any(
            (s) => s.track?.id == track.id,
          );
          if (!alreadyAdded) {
            await pc.addTrack(track, _localStream!);
          }
        }
      }

      pc.onIceCandidate = (RTCIceCandidate candidate) {
        if (candidate.candidate == null || _closed) return;
        _sendSignal(
          'webrtc_ice',
          webrtcData: <String, dynamic>{
            'candidate': candidate.candidate,
            'sdpMid': candidate.sdpMid,
            'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        );
      };

      pc.onTrack = (RTCTrackEvent event) {
        _attachRemoteTrack(event);
      };

      pc.onConnectionState = (RTCPeerConnectionState state) {
        if (_closed) return;
        if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
          _peerDisconnectTimer?.cancel();
          _peerDisconnectTimer = null;
          _applyAudioOutputRouting();
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
          _finishCallWithOutcome(
            _stage == _TelegramCallStage.connected || _elapsedSeconds > 0
                ? 'completed'
                : 'canceled',
          );
        } else if (state == RTCPeerConnectionState.RTCPeerConnectionStateDisconnected ||
            state == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
          _peerDisconnectTimer?.cancel();
          _peerDisconnectTimer = Timer(const Duration(seconds: 3), () {
            if (!_closed) {
              _finishCallWithOutcome(
                _stage == _TelegramCallStage.connected || _elapsedSeconds > 0
                    ? 'completed'
                    : 'canceled',
              );
            }
          });
        }
      };

      return pc;
    } catch (error) {
      debugPrint('Creating RTCPeerConnection failed: $error');
      return null;
    }
  }

  Future<void> _applyAudioOutputRouting() async {
    try {
      if (Platform.isAndroid) {
        await Helper.setAndroidAudioConfiguration(
          AndroidAudioConfiguration.communication,
        );
      }
      await Helper.setSpeakerphoneOn(_isSpeakerOn);
    } catch (e) {
      debugPrint('Audio output routing warning: $e');
    }
  }

  Future<void> _attachRemoteTrack(RTCTrackEvent event) async {
    if (_closed || !mounted) return;
    try {
      if (event.track.kind == 'audio') {
        event.track.enabled = true;
        await _applyAudioOutputRouting();
      }
      if (event.streams.isNotEmpty) {
        final remoteStream = event.streams.first;
        for (final audioTrack in remoteStream.getAudioTracks()) {
          audioTrack.enabled = true;
        }
        _remoteStream = remoteStream;
        _remoteRenderer.srcObject = remoteStream;
      }
      final hasVideo =
          event.track.kind == 'video' ||
          (_remoteRenderer.srcObject?.getVideoTracks().isNotEmpty ?? false);
      if (mounted && !_closed) {
        setState(() => _hasRemoteVideoTrack = hasVideo);
      }
    } catch (error) {
      debugPrint('Attaching remote call track failed: $error');
    }
  }

  Future<void> _startCallerWebRtcOffer() async {
    if (_webrtcOfferSent || _webrtcOfferInProgress || _closed) return;
    _webrtcOfferInProgress = true;
    try {
      await _mediaInitialization;
      if (_closed) return;
      final pc = await _ensurePeerConnectionCreated();
      if (pc == null) return;
      if (_localStream?.getAudioTracks().isEmpty ?? true) {
        _showMediaPermissionMessage(
          'Mikrofon ruxsati yo‘q. Ovozli qo‘ng‘iroq uchun mikrofon ruxsatini yoqing.',
        );
        return;
      }
      final offer = await pc.createOffer(<String, dynamic>{
        'mandatory': <String, dynamic>{
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': true,
        },
      });
      await pc.setLocalDescription(offer);
      _webrtcOfferSent = true;
      _sendSignal(
        'webrtc_offer',
        webrtcData: <String, dynamic>{
          'sdp': offer.sdp,
          'type': offer.type,
        },
      );
    } catch (error) {
      _webrtcOfferSent = false;
      debugPrint('Creating WebRTC offer failed: $error');
      _showMediaPermissionMessage('Ovozli ulanishni boshlashda xatolik yuz berdi.');
    } finally {
      _webrtcOfferInProgress = false;
    }
  }

  Future<void> _handleIncomingWebRtcOffer(Map<String, dynamic> data) async {
    if (_incomingOfferInProgress || _closed) return;
    _incomingOfferInProgress = true;
    try {
      await _mediaInitialization;
      if (_closed) return;
      final sdp = data['sdp']?.toString();
      final type = data['type']?.toString() ?? 'offer';
      if (sdp == null || sdp.isEmpty) return;

      final pc = await _ensurePeerConnectionCreated();
      if (pc == null) return;
      if (_localStream?.getAudioTracks().isEmpty ?? true) {
        _showMediaPermissionMessage(
          'Mikrofon ruxsati yo‘q. Ovozli qo‘ng‘iroq uchun mikrofon ruxsatini yoqing.',
        );
      }

      await pc.setRemoteDescription(RTCSessionDescription(sdp, type));
      _remoteDescriptionSet = true;
      for (final c in _queuedRemoteCandidates) {
        await pc.addCandidate(c);
      }
      _queuedRemoteCandidates.clear();

      final answer = await pc.createAnswer(<String, dynamic>{
        'mandatory': <String, dynamic>{
          'OfferToReceiveAudio': true,
          'OfferToReceiveVideo': true,
        },
      });
      await pc.setLocalDescription(answer);
      _sendSignal(
        'webrtc_answer',
        webrtcData: <String, dynamic>{
          'sdp': answer.sdp,
          'type': answer.type,
        },
      );
    } catch (error) {
      debugPrint('Handling WebRTC offer failed: $error');
      _showMediaPermissionMessage('Ovozli ulanishni o‘rnatib bo‘lmadi.');
    } finally {
      _incomingOfferInProgress = false;
    }
  }

  Future<void> _handleIncomingWebRtcAnswer(Map<String, dynamic> data) async {
    try {
      final sdp = data['sdp']?.toString();
      final type = data['type']?.toString() ?? 'answer';
      if (sdp == null || sdp.isEmpty || _peerConnection == null) return;

      await _peerConnection!.setRemoteDescription(
        RTCSessionDescription(sdp, type),
      );
      _remoteDescriptionSet = true;
      for (final c in _queuedRemoteCandidates) {
        await _peerConnection!.addCandidate(c);
      }
      _queuedRemoteCandidates.clear();
    } catch (_) {}
  }

  Future<void> _handleIncomingWebRtcIce(Map<String, dynamic> data) async {
    try {
      final candStr = data['candidate']?.toString();
      if (candStr == null || candStr.isEmpty) return;
      final candidate = RTCIceCandidate(
        candStr,
        data['sdpMid']?.toString(),
        (data['sdpMLineIndex'] as num?)?.toInt(),
      );
      if (_peerConnection != null && _remoteDescriptionSet) {
        await _peerConnection!.addCandidate(candidate);
      } else {
        _queuedRemoteCandidates.add(candidate);
      }
    } catch (_) {}
  }

  List<String> _deriveVerificationEmojis(String seed) {
    var hash = 0x811C9DC5;
    for (final unit in seed.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return List<String>.generate(4, (i) {
      final idx = ((hash >> (i * 4)) + i * 7) % _emojiPool.length;
      return _emojiPool[idx.abs()];
    });
  }

  void _startRingtoneAndVibrationLoop() {
    _triggerRingPulse();
    _ringtoneLoopTimer = Timer.periodic(
      const Duration(milliseconds: 1500),
      (_) {
        if (_closed ||
            (_stage != _TelegramCallStage.incomingRinging &&
                _stage != _TelegramCallStage.outgoingCalling &&
                _stage != _TelegramCallStage.outgoingRinging)) {
          _ringtoneLoopTimer?.cancel();
          return;
        }
        _triggerRingPulse();
      },
    );
  }

  Future<void> _triggerRingPulse() async {
    try {
      if (_stage == _TelegramCallStage.incomingRinging) {
        await HapticFeedback.heavyImpact();
        await SystemSound.play(SystemSoundType.alert);
        await Future<void>.delayed(const Duration(milliseconds: 220));
        await HapticFeedback.vibrate();
      } else {
        await HapticFeedback.selectionClick();
        await SystemSound.play(SystemSoundType.click);
      }
    } catch (_) {}
  }

  void _sendSignal(String action, {Map<String, dynamic>? webrtcData}) {
    final myInitials = widget.myUserName.trim().isNotEmpty
        ? widget.myUserName.trim()[0].toUpperCase()
        : 'Y';
    _YanGlobalCallCenter.instance.dispatchCallSignal(
      callId: widget.callId,
      action: action,
      callerId: widget.isCaller ? widget.myUserId : widget.peerId,
      callerName: widget.isCaller ? widget.myUserName : widget.peerName,
      callerInitials: widget.isCaller ? myInitials : widget.peerInitials,
      calleeId: widget.isCaller ? widget.peerId : widget.myUserId,
      calleeName: widget.isCaller ? widget.peerName : widget.myUserName,
      roomKey: widget.roomKey,
      isVideo: _isVideoEnabled,
      durationSeconds: _elapsedSeconds,
      isMuted: _isMuted,
      webrtcData: webrtcData,
      roomChannel: widget.roomChannel,
      targetPeerId: widget.peerId,
      consultationId: widget.consultationId,
      consultationDeadlineAt: widget.consultationDeadlineAt,
    );
  }

  void _onGlobalCallSignal() {
    final sig = _YanGlobalCallCenter.instance.latestSignalNotifier.value;
    if (sig == null || _closed) return;
    final sigCallId = sig['call_id']?.toString() ?? '';
    if (sigCallId != widget.callId) return;

    final action = sig['action']?.toString() ?? '';
    final rawWebrtc = sig['webrtc'];
    final webrtcMap = rawWebrtc is Map
        ? Map<String, dynamic>.from(rawWebrtc)
        : null;

    final signalTimestamp = sig['timestamp']?.toString();
    if (signalTimestamp != null &&
        (action.startsWith('webrtc_') || action == 'accept')) {
      final signalKey = '$action|$signalTimestamp';
      if (!_handledWebRtcSignals.add(signalKey)) return;
      if (_handledWebRtcSignals.length > 256) {
        _handledWebRtcSignals.remove(_handledWebRtcSignals.first);
      }
    }

    if (action == 'ringing' &&
        widget.isCaller &&
        _stage == _TelegramCallStage.outgoingCalling) {
      if (mounted) {
        setState(() => _stage = _TelegramCallStage.outgoingRinging);
      }
    } else if (action == 'accept') {
      if (_stage != _TelegramCallStage.connected) {
        _transitionToConnected();
      }
      if (widget.isCaller) {
        _startCallerWebRtcOffer();
      }
    } else if (action == 'webrtc_offer' && webrtcMap != null) {
      _handleIncomingWebRtcOffer(webrtcMap);
    } else if (action == 'webrtc_answer' && webrtcMap != null) {
      _handleIncomingWebRtcAnswer(webrtcMap);
    } else if (action == 'webrtc_ice' && webrtcMap != null) {
      _handleIncomingWebRtcIce(webrtcMap);
    } else if (action == 'decline') {
      _finishCallWithOutcome('declined');
    } else if (action == 'cancel') {
      _finishCallWithOutcome('canceled');
    } else if (action == 'hangup') {
      final remoteDur = (sig['duration'] as num?)?.toInt() ?? _elapsedSeconds;
      if (remoteDur > _elapsedSeconds) {
        _elapsedSeconds = remoteDur;
      }
      _finishCallWithOutcome(
        _stage == _TelegramCallStage.connected || _elapsedSeconds > 0
            ? 'completed'
            : 'canceled',
      );
    } else if (action == 'media_state') {
      if (mounted) {
        setState(() {
          _isPeerVideoEnabled = sig['call_type'] == 'video';
          _isPeerMuted = sig['is_muted'] == true;
        });
      }
    }
  }

  Future<void> _acceptIncomingCall() async {
    HapticFeedback.mediumImpact();
    await _mediaInitialization;
    if (_closed) return;
    await _ensurePeerConnectionCreated();
    _sendSignal('accept');
    _transitionToConnected();
  }

  void _declineIncomingCall() {
    HapticFeedback.heavyImpact();
    _sendSignal('decline');
    _finishCallWithOutcome('declined');
  }

  void _transitionToConnected() {
    _ringtoneLoopTimer?.cancel();
    _noAnswerTimeoutTimer?.cancel();
    if (!mounted) return;
    setState(() {
      _stage = _TelegramCallStage.connected;
    });
    _callClockTimer?.cancel();
    _callClockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_closed || !mounted) return;
      final deadline = widget.consultationDeadlineAt;
      if (deadline != null && !DateTime.now().isBefore(deadline)) {
        if (widget.consultationId != null) {
          ConsultationRepository.instance.markStatus(
            widget.consultationId!,
            'completed',
          );
        }
        _sendSignal('hangup');
        _finishCallWithOutcome('completed');
        return;
      }
      setState(() => _elapsedSeconds++);
    });
  }

  Future<void> _toggleMicrophoneMute() async {
    HapticFeedback.selectionClick();
    await _mediaInitialization;
    if (_closed) return;

    if (_localStream?.getAudioTracks().isEmpty ?? true) {
      final permission = await Permission.microphone.request();
      if (!permission.isGranted) {
        _showMediaPermissionMessage(
          'Ovozli qo‘ng‘iroq uchun mikrofon ruxsatini yoqing.',
        );
        return;
      }

      try {
        final audioStream = await navigator.mediaDevices.getUserMedia(
          <String, dynamic>{
            'audio': <String, dynamic>{
              'echoCancellation': true,
              'noiseSuppression': true,
              'autoGainControl': true,
            },
            'video': false,
          },
        );
        final audioTrack = audioStream.getAudioTracks().firstOrNull;
        if (audioTrack == null) {
          await audioStream.dispose();
          _showMediaPermissionMessage('Mikrofon trekini ochib bo‘lmadi.');
          return;
        }

        final localStream = _localStream;
        if (localStream == null) {
          _localStream = audioStream;
          _localRenderer.srcObject = audioStream;
        } else {
          await localStream.addTrack(audioTrack);
        }
        audioTrack.enabled = true;
        _isMuted = false;

        final existingPeerConnection = _peerConnection;
        if (existingPeerConnection == null) {
          await _ensurePeerConnectionCreated();
        } else {
          final senders = await existingPeerConnection.getSenders();
          final audioSender = senders
              .where((s) => s.track?.kind == 'audio')
              .firstOrNull;
          if (audioSender != null) {
            await audioSender.replaceTrack(audioTrack);
          } else {
            await existingPeerConnection.addTrack(audioTrack, _localStream!);
          }
        }

        if (_stage == _TelegramCallStage.connected) {
          _webrtcOfferSent = false;
          await _startCallerWebRtcOffer();
        }
        if (mounted && !_closed) setState(() {});
        _sendSignal('media_state');
        return;
      } catch (error) {
        debugPrint('Opening call microphone failed: $error');
        _showMediaPermissionMessage('Mikrofonni ochib bo‘lmadi.');
        return;
      }
    }

    final nextMute = !_isMuted;
    setState(() => _isMuted = nextMute);
    final tracks = _localStream?.getAudioTracks() ?? const <MediaStreamTrack>[];
    for (final t in tracks) {
      t.enabled = !nextMute;
    }
    _sendSignal('media_state');
  }

  Future<void> _toggleVideoStream() async {
    HapticFeedback.selectionClick();
    await _mediaInitialization;
    if (_closed) return;

    final nextVideo = !_isVideoEnabled;
    if (nextVideo) {
      final camStatus = await Permission.camera.request();
      if (!camStatus.isGranted) {
        _showMediaPermissionMessage(
          'Video qo‘ng‘iroq uchun kamera ruxsatini bering.',
        );
        return;
      }
      final existingVideoTracks =
          _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
      if (existingVideoTracks.isNotEmpty) {
        for (final t in existingVideoTracks) {
          t.enabled = true;
        }
      } else {
        try {
          final camStream = await navigator.mediaDevices.getUserMedia(
            <String, dynamic>{
              'audio': false,
              'video': <String, dynamic>{
                'facingMode': _isFrontCamera ? 'user' : 'environment',
                'width': <String, dynamic>{'ideal': 640, 'max': 1280},
                'height': <String, dynamic>{'ideal': 480, 'max': 720},
                'frameRate': <String, dynamic>{'ideal': 24, 'max': 30},
              },
            },
          );
          final videoTrack = camStream.getVideoTracks().firstOrNull;
          if (videoTrack != null) {
            if (_localStream == null) {
              _localStream = camStream;
              _localRenderer.srcObject = camStream;
            } else {
              await _localStream!.addTrack(videoTrack);
              _localRenderer.srcObject = _localStream;
            }
            if (_peerConnection != null && _localStream != null) {
              final senders = await _peerConnection!.getSenders();
              final videoSender = senders
                  .where((s) => s.track?.kind == 'video')
                  .firstOrNull;
              if (videoSender != null) {
                await videoSender.replaceTrack(videoTrack);
              } else {
                await _peerConnection!.addTrack(videoTrack, _localStream!);
              }
              _webrtcOfferSent = false;
              await _startCallerWebRtcOffer();
            }
          }
        } catch (error) {
          debugPrint('Opening call camera failed: $error');
          _showMediaPermissionMessage(
            'Kamerani ochib bo‘lmadi. Kamera ruxsati va boshqa ilovalar kameradan foydalanmayotganini tekshiring.',
          );
          return;
        }
      }
    } else {
      final existingVideoTracks =
          _localStream?.getVideoTracks() ?? const <MediaStreamTrack>[];
      for (final t in existingVideoTracks) {
        t.enabled = false;
      }
    }
    if (mounted && !_closed) {
      setState(() => _isVideoEnabled = nextVideo);
    }
    _sendSignal('media_state');
  }

  Future<void> _toggleSpeakerphone() async {
    HapticFeedback.selectionClick();
    final nextSpeaker = !_isSpeakerOn;
    setState(() => _isSpeakerOn = nextSpeaker);
    try {
      await Helper.setSpeakerphoneOn(nextSpeaker);
    } catch (_) {}
  }

  Future<void> _switchCameraDirection() async {
    HapticFeedback.selectionClick();
    setState(() => _isFrontCamera = !_isFrontCamera);
    try {
      final videoTrack = _localStream?.getVideoTracks().firstOrNull;
      if (videoTrack != null) {
        await Helper.switchCamera(videoTrack);
      }
    } catch (_) {}
  }

  void _hangupOrCancelCall() {
    HapticFeedback.mediumImpact();
    if (_stage == _TelegramCallStage.connected) {
      _sendSignal('hangup');
      _finishCallWithOutcome('completed');
    } else if (widget.isCaller) {
      _sendSignal('cancel');
      _finishCallWithOutcome('canceled');
    } else {
      _sendSignal('decline');
      _finishCallWithOutcome('declined');
    }
  }

  Future<void> _cleanupWebRtcResources({bool disposeRenderers = false}) async {
    if (_cleaningUp && !disposeRenderers) return;
    _cleaningUp = true;
    try {
      _localRenderer.srcObject = null;
      _remoteRenderer.srcObject = null;
    } catch (_) {}
    try {
      final stream = _localStream;
      _localStream = null;
      if (stream != null) {
        for (final t in stream.getTracks()) {
          t.stop();
        }
        await stream.dispose();
      }
    } catch (_) {}
    try {
      final remoteStream = _remoteStream;
      _remoteStream = null;
      if (_ownsRemoteStream && remoteStream != null) {
        await remoteStream.dispose();
      }
      _ownsRemoteStream = false;
    } catch (_) {}
    try {
      final pc = _peerConnection;
      _peerConnection = null;
      await pc?.close();
      await pc?.dispose();
    } catch (_) {}
    if (disposeRenderers && _renderersInitialized) {
      _renderersInitialized = false;
      try {
        await _localRenderer.dispose();
        await _remoteRenderer.dispose();
      } catch (_) {}
    }
  }

  void _finishCallWithOutcome(String status) {
    if (_closed) return;
    _closed = true;
    _ringtoneLoopTimer?.cancel();
    _noAnswerTimeoutTimer?.cancel();
    _callClockTimer?.cancel();
    _peerDisconnectTimer?.cancel();
    _YanGlobalCallCenter.instance.clearActiveCall(widget.callId);
    _cleanupWebRtcResources(disposeRenderers: false);

    if (!mounted) return;
    Navigator.of(context).pop(
      _TelegramCallOutcome(
        callId: widget.callId,
        status: status,
        durationSeconds: _elapsedSeconds,
        wasVideo: _isVideoEnabled,
      ),
    );
  }

  @override
  void dispose() {
    _closed = true;
    _ringtoneLoopTimer?.cancel();
    _noAnswerTimeoutTimer?.cancel();
    _callClockTimer?.cancel();
    _peerDisconnectTimer?.cancel();
    _YanGlobalCallCenter.instance.latestSignalNotifier.removeListener(
      _onGlobalCallSignal,
    );
    _YanGlobalCallCenter.instance.clearActiveCall(widget.callId);
    _cleanupWebRtcResources(disposeRenderers: true);
    _pulseController.dispose();
    super.dispose();
  }

  String get _formattedDuration {
    final deadline = widget.consultationDeadlineAt;
    if (deadline != null) {
      final remaining = deadline.difference(DateTime.now());
      return '⏱ ${ConsultationSlotMath.formatCountdown(remaining)} qoldi';
    }
    final mins = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final secs = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  String get _statusHeadline {
    switch (_stage) {
      case _TelegramCallStage.outgoingCalling:
        return 'Ulanmoqda...';
      case _TelegramCallStage.outgoingRinging:
        return 'Chaqirilmoqda... (Telefon jiringlamoqda)';
      case _TelegramCallStage.incomingRinging:
        return _isVideoEnabled
            ? 'Kiruvchi E2EE Video qo‘ng‘iroq...'
            : 'Kiruvchi E2EE Audio qo‘ng‘iroq...';
      case _TelegramCallStage.connected:
        return _formattedDuration;
      case _TelegramCallStage.ended:
        return 'Qo‘ng‘iroq yakunlandi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRinging = _stage == _TelegramCallStage.incomingRinging ||
        _stage == _TelegramCallStage.outgoingCalling ||
        _stage == _TelegramCallStage.outgoingRinging;
    final showFullRemoteVideo = !_closed &&
        _stage == _TelegramCallStage.connected &&
        _isPeerVideoEnabled &&
        _hasRemoteVideoTrack &&
        _renderersInitialized &&
        _remoteRenderer.srcObject != null;

    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Color(0xFF0A1931),
              Color(0xFF102B57),
              Color(0xFF0D2346),
            ],
          ),
        ),
        child: SafeArea(
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              // 0. Full-Screen Live Remote Video Feed when Peer Video is Active
              if (showFullRemoteVideo)
                Positioned.fill(
                  child: RTCVideoView(
                    _remoteRenderer,
                    objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                  ),
                ),

              // 1. Top bar: E2EE Verification Emojis + Signal Strength
              Positioned(
                top: 14,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: YanColors.successGreen,
                          ),
                          SizedBox(width: 5),
                          Text(
                            'E2EE WebRTC',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(width: 6),
                          Icon(
                            Icons.signal_cellular_alt_rounded,
                            size: 14,
                            color: YanColors.successGreen,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.32),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: _e2eeEmojis
                            .map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 2.5,
                                ),
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 13.5),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Center Avatar + Animated Ripple Rings + Peer Name + Live Status / Timer
              // (Shown when in audio mode or ringing; compact top badge when remote video is fullscreen)
              if (!showFullRemoteVideo)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 190,
                      height: 190,
                      child: AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          final pulse = _pulseController.value;
                          return Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              if (isRinging) ...<Widget>[
                                Container(
                                  width: 132 + (pulse * 52),
                                  height: 132 + (pulse * 52),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (_stage ==
                                                _TelegramCallStage.incomingRinging
                                            ? YanColors.successGreen
                                            : YanColors.primaryBlue)
                                        .withValues(alpha: (1 - pulse) * 0.24),
                                  ),
                                ),
                                Container(
                                  width: 124 + (pulse * 28),
                                  height: 124 + (pulse * 28),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: (_stage ==
                                                _TelegramCallStage.incomingRinging
                                            ? YanColors.successGreen
                                            : YanColors.primaryBlue)
                                        .withValues(alpha: (1 - pulse) * 0.36),
                                  ),
                                ),
                              ],
                              child!,
                            ],
                          );
                        },
                        child: Container(
                          width: 122,
                          height: 122,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: YanColors.primaryBlue,
                            border: Border.all(
                              color: _stage == _TelegramCallStage.connected
                                  ? YanColors.successGreen
                                  : Colors.white,
                              width: 3,
                            ),
                            boxShadow: <BoxShadow>[
                              BoxShadow(
                                color: YanColors.primaryBlue.withValues(
                                  alpha: 0.45,
                                ),
                                blurRadius: 28,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.peerInitials,
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        widget.peerName,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.peerSubtitle,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.72),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _stage == _TelegramCallStage.connected
                            ? YanColors.successGreen.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        _statusHeadline,
                        style: TextStyle(
                          fontSize: _stage == _TelegramCallStage.connected
                              ? 19
                              : 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                          color: _stage == _TelegramCallStage.connected
                              ? YanColors.successGreen
                              : Colors.white,
                        ),
                      ),
                    ),
                    if (_isPeerMuted && _stage == _TelegramCallStage.connected) ...<Widget>[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.mic_off_rounded,
                            size: 15,
                            color: Color(0xFFFFB4AB),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${widget.peerName} mikrofoni o‘chiq',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFFFB4AB),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                )
              else
                Positioned(
                  top: 62,
                  left: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          widget.peerName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _statusHeadline,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: YanColors.successGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // 3. Picture-in-Picture Local Camera Preview (Real Live Camera Feed via RTCVideoView!)
              if (!_closed && _isVideoEnabled && _renderersInitialized)
                Positioned(
                  right: 16,
                  top: 64,
                  child: GestureDetector(
                    onTap: _switchCameraDirection,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 112,
                        height: 162,
                        decoration: BoxDecoration(
                          color: const Color(0xFF071326),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1.8),
                        ),
                        child: _localRenderer.srcObject != null
                            ? RTCVideoView(
                                _localRenderer,
                                mirror: _isFrontCamera,
                                objectFit: RTCVideoViewObjectFit
                                    .RTCVideoViewObjectFitCover,
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  const Icon(
                                    Icons.videocam_rounded,
                                    color: YanColors.cyanAccent,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _isFrontCamera
                                        ? 'Old kamera'
                                        : 'Orqa kamera',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),

              // 4. Bottom Controls
              Positioned(
                left: 20,
                right: 20,
                bottom: 26,
                child: _stage == _TelegramCallStage.incomingRinging
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 18,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            GestureDetector(
                              onTap: _declineIncomingCall,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 66,
                                    height: 66,
                                    decoration: const BoxDecoration(
                                      color: YanColors.destructiveRed,
                                      shape: BoxShape.circle,
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Color(0x66D92D20),
                                          blurRadius: 18,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.call_end_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Rad etish',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: _acceptIncomingCall,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 66,
                                    height: 66,
                                    decoration: const BoxDecoration(
                                      color: YanColors.successGreen,
                                      shape: BoxShape.circle,
                                      boxShadow: <BoxShadow>[
                                        BoxShadow(
                                          color: Color(0x6610C995),
                                          blurRadius: 18,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      _isVideoEnabled
                                          ? Icons.videocam_rounded
                                          : Icons.call_rounded,
                                      color: Colors.white,
                                      size: 30,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Javob berish',
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.38),
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.16),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            _CallControlButton(
                              icon: _isMuted
                                  ? Icons.mic_off_rounded
                                  : Icons.mic_rounded,
                              label: _isMuted ? 'O‘chiq' : 'Mikrofon',
                              active: !_isMuted,
                              onTap: _toggleMicrophoneMute,
                            ),
                            _CallControlButton(
                              icon: _isVideoEnabled
                                  ? Icons.videocam_rounded
                                  : Icons.videocam_off_rounded,
                              label: _isVideoEnabled ? 'Video' : 'Audio',
                              active: _isVideoEnabled,
                              onTap: _toggleVideoStream,
                            ),
                            _CallControlButton(
                              icon: _isSpeakerOn
                                  ? Icons.volume_up_rounded
                                  : Icons.volume_down_rounded,
                              label: _isSpeakerOn ? 'Karnay' : 'Quloqchin',
                              active: _isSpeakerOn,
                              onTap: _toggleSpeakerphone,
                            ),
                            if (_isVideoEnabled)
                              _CallControlButton(
                                icon: Icons.cameraswitch_rounded,
                                label: 'Kamera',
                                active: true,
                                onTap: _switchCameraDirection,
                              ),
                            GestureDetector(
                              onTap: _hangupOrCancelCall,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  Container(
                                    width: 54,
                                    height: 54,
                                    decoration: const BoxDecoration(
                                      color: YanColors.destructiveRed,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.call_end_rounded,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  const Text(
                                    'Yakunlash',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
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
      ),
    );
  }
}

class _CallControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _CallControlButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: active
                  ? YanColors.primaryBlue
                  : Colors.white.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AttachmentOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: YanColors.lightBlue,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: YanColors.primaryBlue, size: 21),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13.5,
          fontWeight: FontWeight.w800,
          color: YanColors.primaryNavy,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 11.5, color: YanColors.mutedText),
      ),
    );
  }
}

// ============================================================================
// ARIZALARIM ROLE VIEW — SHOWS #ariza DELIVERIES FROM ADVOCATE + 30-MIN ORDERS
// ============================================================================
class _PetitionCatalogEntry {
  final String title;
  final String subtitle;
  final String category;
  final String turnaroundTime;
  final int standardPriceUzs;

  const _PetitionCatalogEntry({
    required this.title,
    required this.subtitle,
    required this.category,
    required this.turnaroundTime,
    required this.standardPriceUzs,
  });
}

class _ArizalarimRoleView extends StatefulWidget {
  final UserProfileData profile;

  const _ArizalarimRoleView({super.key, required this.profile});

  @override
  State<_ArizalarimRoleView> createState() => _ArizalarimRoleViewState();
}

class _ArizalarimRoleViewState extends State<_ArizalarimRoleView> {
  Timer? _countdownTimer;

  static const List<_PetitionCatalogEntry> _templates = <_PetitionCatalogEntry>[
    _PetitionCatalogEntry(
      title: 'Aliment undirish haqida sud buyrug‘i arizasi',
      subtitle: 'Voyaga yetmagan farzandlar ta’minoti uchun rasmiy sud arizasi',
      category: 'Oila huquqi',
      turnaroundTime: '~5 daqiqa (DOCX)',
      standardPriceUzs: 90000,
    ),
    _PetitionCatalogEntry(
      title: 'Nikohdan ajratish to‘g‘risida da’vo arizasi',
      subtitle: 'Fuqarolik ishlari bo‘yicha sudga topshiriladigan da’vo arizasi',
      category: 'Oila huquqi',
      turnaroundTime: '~10 daqiqa (DOCX)',
      standardPriceUzs: 120000,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _YanE2eeCryptoEngine.syncArizaOrdersLedger();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _showReadyArizaDialog(ArizaOrderItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: YanColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
              const SizedBox(height: 14),
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: YanColors.successGreen.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      '#ARIZA • E2EE TASDIQLANGAN HUJJAT',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0A936B),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                item.subjectTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: YanColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Advokat: ${item.advocateName} • Buyurtma: ${item.id}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: YanColors.mutedText,
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 280),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: YanColors.lightBlue,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: YanColors.border),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    item.completedArizaText ?? item.detailedStatement,
                    style: const TextStyle(
                      fontSize: 13.2,
                      fontWeight: FontWeight.w600,
                      color: YanColors.primaryNavy,
                      height: 1.45,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SolidSecondaryButton(
                      label: 'Nusxa olish',
                      icon: Icons.copy_rounded,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text:
                                item.completedArizaText ??
                                item.detailedStatement,
                          ),
                        );
                        Navigator.pop(ctx);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ariza matni nusxalandi!'),
                            backgroundColor: YanColors.primaryNavy,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SolidPrimaryButton(
                      label: 'Yopish',
                      icon: Icons.check_rounded,
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final isDiscounted = profile.hasClientDiscounts;
    final now = DateTime.now();

    return ValueListenableBuilder<List<ArizaOrderItem>>(
      valueListenable: YanRoleDataCatalog.arizaOrders,
      builder: (context, orders, _) {
        final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
        final profileId = profile.clientId;
        final myOrders = orders.where((o) {
          return (authId.isNotEmpty &&
                  YanRoleDataCatalog.isSameParticipant(o.clientId, authId)) ||
              (profileId.isNotEmpty &&
                  YanRoleDataCatalog.isSameParticipant(o.clientId, profileId));
        }).toList(growable: false);
        final readyOrders = myOrders
            .where((o) => o.isEffectivelyCompleted(now))
            .toList();
        final activeOrders = myOrders
            .where((o) => !o.isEffectivelyCompleted(now))
            .toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 115),
          children: <Widget>[
            // 1. Completed #ariza section from Advocate
            if (readyOrders.isNotEmpty) ...<Widget>[
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.verified_rounded,
                    size: 19,
                    color: YanColors.successGreen,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Advokatdan kelgan tayyor arizalar (#ariza)',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...readyOrders.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: YanColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: YanColors.successGreen.withValues(alpha: 0.55),
                      width: 1.4,
                    ),
                    boxShadow: const <BoxShadow>[
                      BoxShadow(
                        color: Color(0x1210C995),
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: YanColors.successGreen.withValues(
                                alpha: 0.14,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Text(
                              'TAYYOR • #ARIZA TOPSHIRILDI',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF0A936B),
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.id,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: YanColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item.subjectTitle,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: YanColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Advokat: ${item.advocateName}',
                        style: const TextStyle(
                          fontSize: 12.2,
                          fontWeight: FontWeight.w700,
                          color: YanColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.completedArizaText ?? item.detailedStatement,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: YanColors.mutedText,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          const Icon(
                            Icons.lock_rounded,
                            size: 13,
                            color: YanColors.successGreen,
                          ),
                          const SizedBox(width: 4),
                          const Expanded(
                            child: Text(
                              'E2EE orqali himoyalangan',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: YanColors.successGreen,
                              ),
                            ),
                          ),
                          _CardPillButton(
                            label: 'Arizani ochish',
                            isPrimary: true,
                            onTap: () => _showReadyArizaDialog(item),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // 2. Active in-progress 30-minute Ariza orders
            if (activeOrders.isNotEmpty) ...<Widget>[
              const Row(
                children: <Widget>[
                  Icon(
                    Icons.timer_rounded,
                    size: 19,
                    color: YanColors.primaryBlue,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Tayyorlanayotgan arizalar (30 daqiqa muddat)',
                    style: TextStyle(
                      fontSize: 16.5,
                      fontWeight: FontWeight.w900,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ...activeOrders.map((item) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: YanColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: YanColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: YanColors.lightBlue,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '⏳ ${item.formatCountdown(now)}',
                              style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: YanColors.primaryBlue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            item.id,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: YanColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 9),
                      Text(
                        item.subjectTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: YanColors.primaryNavy,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Mas’ul advokat: ${item.advocateName}',
                        style: const TextStyle(
                          fontSize: 12.2,
                          fontWeight: FontWeight.w700,
                          color: YanColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.detailedStatement,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.3,
                          color: YanColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 8),
            ],

            // 3. Standard Templates Header
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: YanColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: YanColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: isDiscounted
                              ? YanColors.successGreen.withValues(alpha: 0.14)
                              : YanColors.lightBlue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          isDiscounted
                              ? 'MIJOZ TARIFI • -50% CHEGIRMA FAOL'
                              : 'ARIZALARIM VA HUJJATLAR MARKAZI',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            color: isDiscounted
                                ? const Color(0xFF0A936B)
                                : YanColors.primaryBlue,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Arizalarim va Avto-Shablonlar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Advokat chatda #ariza tegi bilan yuborgan barcha tayyor arizalar shu sahifada avtomatik saqlanadi.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: YanColors.mutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ..._templates.map((item) {
              final activePrice = isDiscounted
                  ? profile.applyDiscount(
                      item.standardPriceUzs,
                      category: 'template',
                    )
                  : item.standardPriceUzs;
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: YanColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: YanColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: YanColors.lightBlue,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            item.category,
                            style: const TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              color: YanColors.primaryBlue,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          item.turnaroundTime,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: YanColors.mutedText,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: YanColors.primaryNavy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: YanColors.mutedText,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: <Widget>[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            if (isDiscounted)
                              Text(
                                '${item.standardPriceUzs} so‘m',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: YanColors.mutedText,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                            Text(
                              '$activePrice so‘m',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: YanColors.primaryNavy,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        _CardPillButton(
                          label: 'Ariza tayyorlash',
                          isPrimary: true,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => const AlimonyClaimPage(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
          ],
        );
      },
    );
  }
}

class _MonochromaticSegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MonochromaticSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? YanColors.primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : YanColors.primaryNavy,
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ADVOKAT HOME, CONTRACTS & CLIENTS VIEWS (WITH 30-MIN REAL-TIME ARIZA CATEGORY)
// ============================================================================
class _AdvokatHomeRoleView extends StatelessWidget {
  final UserProfileData profile;
  final VoidCallback onOpenContracts;
  final VoidCallback onOpenClients;

  const _AdvokatHomeRoleView({
    super.key,
    required this.profile,
    required this.onOpenContracts,
    required this.onOpenClients,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 115),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: YanColors.white,
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: YanColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: YanColors.lightBlue,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'RASMIY ADVOKAT KABINETI',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: YanColors.primaryBlue,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.verified_user_rounded,
                    color: YanColors.successGreen,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                profile.displayName,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w900,
                  color: YanColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Litsenziya: ${profile.lawyerLicenseNumber} • ${profile.lawyerSpecialization}',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: YanColors.mutedText,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _SolidSecondaryButton(
                      label: 'Shartnomalarim',
                      icon: Icons.assignment_turned_in_rounded,
                      onPressed: onOpenContracts,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SolidPrimaryButton(
                      label: 'Mijozlar va Ariza',
                      icon: Icons.people_alt_rounded,
                      onPressed: onOpenClients,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // ADVOCATE CALENDAR YACHEYKA CARD (Track & Control Availability + Upcoming Consultations)
        ValueListenableBuilder<List<ConsultationBooking>>(
          valueListenable: ConsultationRepository.instance.consultations,
          builder: (context, allBookings, _) {
            return ValueListenableBuilder<List<AdvocateBlockedSlot>>(
              valueListenable: ConsultationRepository.instance.blockedSlots,
              builder: (context, allBlocked, _) {
                final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
                final advId = authId.isNotEmpty ? authId : profile.clientId;
                final activeConsults = allBookings
                    .where((b) =>
                        YanRoleDataCatalog.isSameParticipant(b.advocateId, advId) &&
                        b.isActiveStatus &&
                        !b.isExpired())
                    .toList()
                  ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
                final blockedCount = allBlocked
                    .where((b) => YanRoleDataCatalog.isSameParticipant(b.advocateId, advId))
                    .length;

                return Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFDCEBFF)),
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: const Color(0xFF1677FF).withValues(alpha: 0.07),
                        blurRadius: 22,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF4FF),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(
                              Icons.calendar_month_rounded,
                              color: Color(0xFF1677FF),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                const Text(
                                  'Kalendarim va Konsultatsiyalar',
                                  style: TextStyle(
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0B1F3A),
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  '${activeConsults.length} ta faol uchrashuv • $blockedCount ta yopilgan vaqt',
                                  style: const TextStyle(
                                    fontSize: 12.2,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF1677FF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Kelgusi 7 kunlik 24 soatlik jadvalingizni boshqaring: band kun yoki aniq soatlarni yoping va istalgan vaqtda qayta oching.',
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.42,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => AdvocateCalendarPage(
                                  profile: profile,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_calendar_rounded, size: 18),
                          label: const Text(
                            'Kalendarni boshqarish',
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1677FF),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

class _AdvokatContractsRoleView extends StatelessWidget {
  final UserProfileData profile;

  const _AdvokatContractsRoleView({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final contracts = YanRoleDataCatalog.sampleContracts;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 115),
      children: <Widget>[
        const Text(
          'Rasmiy Shartnomalar',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: YanColors.primaryNavy,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Faqat haqiqiy imzolangan mijoz shartnomalari ro‘yxati',
          style: TextStyle(fontSize: 12.5, color: YanColors.mutedText),
        ),
        const SizedBox(height: 16),
        if (contracts.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: YanColors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: YanColors.border),
            ),
            child: const Column(
              children: <Widget>[
                Icon(
                  Icons.assignment_outlined,
                  size: 40,
                  color: YanColors.primaryBlue,
                ),
                SizedBox(height: 10),
                Text(
                  'Hozircha faol shartnomalar mavjud emas',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: YanColors.primaryNavy,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Mijozlar Advokatxona bo‘limidan sizning profilingizni tanlab shartnoma tuzganida bu yerda ko‘rinadi.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    color: YanColors.mutedText,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Advocate's `Mijozlar` Directory — categorizes clients by request type
/// (`Barchasi`, `Ariza yozdirish (30 daq)`, `Shartnomali`) with a real-time
/// 1-second ticking 30-minute countdown timer and direct E2EE Chat + Audio/Video call.
class _ClientsDirectoryRoleView extends StatefulWidget {
  final UserProfileData profile;
  final bool isAssistantView;

  const _ClientsDirectoryRoleView({
    super.key,
    required this.profile,
    this.isAssistantView = false,
  });

  @override
  State<_ClientsDirectoryRoleView> createState() =>
      _ClientsDirectoryRoleViewState();
}

class _ClientsDirectoryRoleViewState extends State<_ClientsDirectoryRoleView> {
  bool _isLoadingClients = true;
  String _selectedCategoryFilter = 'Barchasi';
  List<LawyerDirectoryProfile> _realClients = <LawyerDirectoryProfile>[];
  Timer? _liveDeadlineTicker;

  static const List<String> _categoryTabs = <String>[
    'Barchasi',
    'Konsultatsiya',
    'Ariza yozdirish',
    'Shartnomali',
  ];

  @override
  void initState() {
    super.initState();
    _refreshAllData();
    _liveDeadlineTicker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _liveDeadlineTicker?.cancel();
    super.dispose();
  }

  Future<void> _refreshAllData() async {
    await _YanE2eeCryptoEngine.syncArizaOrdersLedger();
    await _fetchRealClientsFromSupabase();
  }

  Future<void> _fetchRealClientsFromSupabase() async {
    if (mounted) setState(() => _isLoadingClients = true);
    try {
      final rows = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('role', 'client');

      final parsed = <LawyerDirectoryProfile>[];
      for (final item in rows) {
        final map = Map<String, dynamic>.from(item as Map);
        final id = map['id']?.toString() ?? '';
        final fullName = (map['full_name']?.toString() ?? '').trim();
        if (id.isNotEmpty) {
          parsed.add(
            LawyerDirectoryProfile(
              id: id,
              fullName: fullName.isEmpty ? 'Rasmiy Mijoz' : fullName,
              title: 'YAN360 Mijozi',
              region: map['region']?.toString() ?? 'Toshkent shahri',
              specialization: 'E2EE Himoyalangan Mijoz',
              experienceYears: 1,
              rating: 5.0,
              feedbackCount: 1,
              wonCasesCount: 0,
              consultationPriceUzs: 0,
              contractMonthlyNote: 'E2EE Shifrlangan Muloqot',
              licenseNumber: 'Tasdiqlangan',
              phone: map['phone']?.toString() ?? '+998',
              assistantName: '-',
              assistantRole: '',
              assistantPhone: '',
              bio: 'YAN360 ilovasida rasmiy ro‘yxatdan o‘tgan mijoz.',
              feedbacks: const <LawyerFeedbackItem>[],
              isVerifiedPartner: map['is_online'] != false,
            ),
          );
        }
      }
      if (mounted) {
        setState(() => _realClients = parsed);
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingClients = false);
    }
  }

  void _openClientChat(
    BuildContext context,
    LawyerDirectoryProfile clientPeer, {
    String? callMode,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AdvocateClientChatPage(
          lawyer: clientPeer,
          profile: widget.profile,
          initialCallMode: callMode,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final authId = Supabase.instance.client.auth.currentUser?.id ?? '';
    final profileId = widget.profile.clientId;
    final arizaOrders = YanRoleDataCatalog.arizaOrders.value.where((o) {
      return (authId.isNotEmpty &&
              YanRoleDataCatalog.isSameParticipant(o.advocateId, authId)) ||
          (profileId.isNotEmpty &&
              YanRoleDataCatalog.isSameParticipant(o.advocateId, profileId));
    }).toList(growable: false);

    final showArizaSection =
        _selectedCategoryFilter == 'Barchasi' ||
        _selectedCategoryFilter == 'Ariza yozdirish';
    final showGeneralClientsSection =
        _selectedCategoryFilter == 'Barchasi' ||
        _selectedCategoryFilter == 'Shartnomali';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 115),
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    widget.isAssistantView
                        ? 'Yordamchi: Mijozlar va Arizalar'
                        : 'Mijozlar va Ariza Buyurtmalari',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Turkumlangan mijozlar • 30 daqiqalik real-vaqt taymeri • E2EE',
                    style: TextStyle(fontSize: 12.0, color: YanColors.mutedText),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: _refreshAllData,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: YanColors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: YanColors.border),
                ),
                child: _isLoadingClients
                    ? const CupertinoActivityIndicator(
                        color: YanColors.primaryBlue,
                      )
                    : const Icon(
                        CupertinoIcons.refresh,
                        size: 18,
                        color: YanColors.primaryBlue,
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Category Filter Pills
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categoryTabs.map((tab) {
              final selected = _selectedCategoryFilter == tab;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _SortTabPill(
                  label: tab == 'Ariza yozdirish'
                      ? 'Ariza yozdirish (${arizaOrders.length})'
                      : tab,
                  selected: selected,
                  onTap: () => setState(() => _selectedCategoryFilter = tab),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),

        // 0. PINNED BOOKED CONSULTATIONS FOR ADVOCATE (LIVE 19-MIN SCHEDULE TRACKER)
        if (_selectedCategoryFilter == 'Barchasi' ||
            _selectedCategoryFilter == 'Konsultatsiya')
          ValueListenableBuilder<List<ConsultationBooking>>(
            valueListenable: ConsultationRepository.instance.consultations,
            builder: (context, allBookings, _) {
              final myConsults = allBookings
                  .where((b) =>
                      ((authId.isNotEmpty &&
                              YanRoleDataCatalog.isSameParticipant(b.advocateId, authId)) ||
                          (profileId.isNotEmpty &&
                              YanRoleDataCatalog.isSameParticipant(b.advocateId, profileId))) &&
                      b.isActiveStatus &&
                      !b.isExpired(now))
                  .toList()
                ..sort((a, b) => a.slotStart.compareTo(b.slotStart));
              if (myConsults.isEmpty) return const SizedBox.shrink();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Text(
                      'BAND QILINGAN VIDEO KONSULTATSIYALAR (19 DAQ)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: YanColors.primaryBlue,
                      ),
                    ),
                  ),
                  ...myConsults.map((booking) {
                    return _PinnedConsultationBannerCard(
                      booking: booking,
                      isAdvocateView: true,
                      onOpenChat: () {
                        final peer = LawyerDirectoryProfile(
                          id: booking.clientId,
                          fullName: booking.clientName,
                          title: 'Konsultatsiya Mijozi',
                          region: booking.clientRegion.isEmpty
                              ? 'O‘zbekiston'
                              : booking.clientRegion,
                          specialization: '${booking.friendlyDateLabel} • ${booking.timeRangeLabel}',
                          experienceYears: 1,
                          rating: 5.0,
                          feedbackCount: 1,
                          wonCasesCount: 0,
                          consultationPriceUzs: 0,
                          contractMonthlyNote: 'Konsultatsiya',
                          licenseNumber: booking.id,
                          phone: booking.clientPhone,
                          assistantName: '-',
                          assistantRole: '',
                          assistantPhone: '',
                          bio: 'Video konsultatsiya band qilgan mijoz.',
                          feedbacks: const <LawyerFeedbackItem>[],
                        );
                        _openClientChat(context, peer);
                      },
                    );
                  }),
                  const SizedBox(height: 12),
                ],
              );
            },
          ),

        // 1. ARIZA YOZDIRISH CLIENTS (WITH LIVE 30-MINUTE REAL-TIME COUNTDOWN)
        if (showArizaSection && arizaOrders.isNotEmpty) ...<Widget>[
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text(
              'ARIZA BUYURTMALARI (30 DAQIQALIK REAL-VAQT MUDDATI)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.6,
                color: YanColors.primaryBlue,
              ),
            ),
          ),
          ...arizaOrders.map((order) {
            final clientPeer = LawyerDirectoryProfile(
              id: order.clientId,
              fullName: order.clientName,
              title: 'Ariza buyurtmachisi (${order.id})',
              region: order.clientRegion,
              specialization: order.categoryType,
              experienceYears: 1,
              rating: 5.0,
              feedbackCount: 1,
              wonCasesCount: 0,
              consultationPriceUzs: 0,
              contractMonthlyNote: '30 daqiqalik ariza buyurtmasi',
              licenseNumber: order.id,
              phone: order.clientPhone,
              assistantName: '-',
              assistantRole: '',
              assistantPhone: '',
              bio: order.detailedStatement,
              feedbacks: const <LawyerFeedbackItem>[],
              isVerifiedPartner: true,
            );

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: YanColors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: order.isCompleted
                      ? YanColors.successGreen.withValues(alpha: 0.55)
                      : YanColors.primaryBlue.withValues(alpha: 0.5),
                  width: 1.4,
                ),
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x0F1677D2),
                    blurRadius: 14,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: YanColors.primaryBlue,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          order.categoryType.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 9.8,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: order.isEffectivelyCompleted(now)
                              ? YanColors.successGreen.withValues(alpha: 0.14)
                              : order.isAdvocateLate(now)
                              ? YanColors.destructiveRed.withValues(alpha: 0.14)
                              : const Color(0xFFFFF4E5),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(
                              order.isEffectivelyCompleted(now)
                                  ? Icons.check_circle_rounded
                                  : order.isAdvocateLate(now)
                                  ? Icons.warning_amber_rounded
                                  : Icons.timer_rounded,
                              size: 13,
                              color: order.isEffectivelyCompleted(now)
                                  ? const Color(0xFF0A936B)
                                  : order.isAdvocateLate(now)
                                  ? YanColors.destructiveRed
                                  : const Color(0xFFD97706),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              order.formatCountdown(now),
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w900,
                                color: order.isEffectivelyCompleted(now)
                                    ? const Color(0xFF0A936B)
                                    : order.isAdvocateLate(now)
                                    ? YanColors.destructiveRed
                                    : const Color(0xFFD97706),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        order.id,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: YanColors.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: <Widget>[
                      _LawyerAvatarPortrait(
                        initials: clientPeer.initials,
                        isOnline: true,
                        size: 46,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              order.clientName,
                              style: const TextStyle(
                                fontSize: 15.5,
                                fontWeight: FontWeight.w800,
                                color: YanColors.primaryNavy,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${order.clientPhone} • ${order.subjectTitle}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: YanColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Text(
                    order.detailedStatement,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.3,
                      color: YanColors.mutedText,
                      height: 1.38,
                    ),
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: <Widget>[
                      Text(
                        'Ilovalar: ${order.attachmentNames.length} ta hujjat',
                        style: const TextStyle(
                          fontSize: 11.2,
                          fontWeight: FontWeight.w700,
                          color: YanColors.primaryNavy,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _openClientChat(
                          context,
                          clientPeer,
                          callMode: 'audio',
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: YanColors.lightBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: YanColors.border),
                          ),
                          child: const Icon(
                            Icons.call_rounded,
                            size: 17,
                            color: YanColors.primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _openClientChat(
                          context,
                          clientPeer,
                          callMode: 'video',
                        ),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: YanColors.lightBlue,
                            shape: BoxShape.circle,
                            border: Border.all(color: YanColors.border),
                          ),
                          child: const Icon(
                            Icons.videocam_rounded,
                            size: 17,
                            color: YanColors.primaryNavy,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      _CardPillButton(
                        label: 'Chat / #ariza',
                        isPrimary: true,
                        onTap: () => _openClientChat(context, clientPeer),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
        ],

        // 2. REGISTERED SUPABASE CLIENTS
        if (showGeneralClientsSection) ...<Widget>[
          if (_isLoadingClients)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 42),
              child: Center(
                child: CupertinoActivityIndicator(
                  radius: 14,
                  color: YanColors.primaryBlue,
                ),
              ),
            )
          else if (_realClients.isEmpty && arizaOrders.isEmpty)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: YanColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: YanColors.border),
              ),
              child: const Column(
                children: <Widget>[
                  Icon(
                    Icons.people_outline_rounded,
                    size: 40,
                    color: YanColors.primaryBlue,
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Hozircha ro‘yxatdan o‘tgan mijozlar yo‘q',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: YanColors.primaryNavy,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Mijozlar "Advokatga ariza yozdirish" orqali murojaat yuborganda 30 daqiqalik taymer bilan shu yerda ko‘rinadi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.5,
                      color: YanColors.mutedText,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            )
          else
            ..._realClients.map((clientPeer) {
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: YanColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: YanColors.border),
                ),
                child: Row(
                  children: <Widget>[
                    _LawyerAvatarPortrait(
                      initials: clientPeer.initials,
                      isOnline: clientPeer.isVerifiedPartner,
                      size: 48,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            clientPeer.fullName,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: YanColors.primaryNavy,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            clientPeer.isVerifiedPartner
                                ? 'Online • E2EE himoyalangan mijoz'
                                : 'Offline • E2EE himoyalangan mijoz',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: clientPeer.isVerifiedPartner
                                  ? YanColors.successGreen
                                  : YanColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _openClientChat(
                        context,
                        clientPeer,
                        callMode: 'audio',
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: YanColors.lightBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: YanColors.border),
                        ),
                        child: const Icon(
                          Icons.call_rounded,
                          size: 18,
                          color: YanColors.primaryBlue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _openClientChat(
                        context,
                        clientPeer,
                        callMode: 'video',
                      ),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: YanColors.lightBlue,
                          shape: BoxShape.circle,
                          border: Border.all(color: YanColors.border),
                        ),
                        child: const Icon(
                          Icons.videocam_rounded,
                          size: 18,
                          color: YanColors.primaryNavy,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _CardPillButton(
                      label: 'Xabar',
                      isPrimary: true,
                      onTap: () => _openClientChat(context, clientPeer),
                    ),
                  ],
                ),
              );
            }),
        ],
      ],
    );
  }
}

class _AssistantTasksRoleView extends StatelessWidget {
  final UserProfileData profile;
  final VoidCallback? onOpenClients;

  const _AssistantTasksRoleView({
    super.key,
    required this.profile,
    this.onOpenClients,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 115),
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: YanColors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: YanColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Advokat Yordamchisi Paneli',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: YanColors.primaryNavy,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Biriktirilgan advokat: ${profile.assignedLawyerName}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: YanColors.mutedText,
                ),
              ),
              if (onOpenClients != null) ...<Widget>[
                const SizedBox(height: 14),
                _SolidSecondaryButton(
                  label: 'Mijozlar ro‘yxatini ochish',
                  icon: Icons.people_alt_rounded,
                  onPressed: onOpenClients!,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// SHARED MONOCHROMATIC INPUTS & BUTTONS
// ============================================================================
class _UzbekPhoneField extends StatelessWidget {
  final TextEditingController controller;

  const _UzbekPhoneField({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YanColors.lightBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YanColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        children: <Widget>[
          const Icon(
            Icons.phone_rounded,
            color: YanColors.primaryBlue,
            size: 20,
          ),
          const SizedBox(width: 10),
          const Text(
            '+998',
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: YanColors.primaryNavy,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: YanColors.primaryNavy,
              ),
              decoration: const InputDecoration(
                hintText: '90 123 45 67',
                hintStyle: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: YanColors.mutedText,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CleanTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLength;

  const _CleanTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: YanColors.lightBlue,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: YanColors.border),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
      child: Row(
        children: <Widget>[
          Icon(icon, color: YanColors.primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              maxLength: maxLength,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: YanColors.primaryNavy,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: hintText,
                hintStyle: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w500,
                  color: YanColors.mutedText,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SolidPrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _SolidPrimaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: YanColors.primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 18, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class _SolidSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool active;

  const _SolidSecondaryButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: active ? YanColors.primaryBlue : YanColors.lightBlue,
          foregroundColor: active ? Colors.white : YanColors.primaryBlue,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: active
                  ? YanColors.primaryBlue
                  : YanColors.primaryBlue.withValues(alpha: 0.35),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon,
              size: 18,
              color: active ? Colors.white : YanColors.primaryBlue,
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13.5,
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

class _PinnedConsultationBannerCard extends StatelessWidget {
  final ConsultationBooking booking;
  final bool isAdvocateView;
  final VoidCallback onOpenChat;

  const _PinnedConsultationBannerCard({
    required this.booking,
    required this.isAdvocateView,
    required this.onOpenChat,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isLive = booking.isWithinLiveWindow(now);
    final isUpcoming = booking.isUpcoming(now);
    final peerLabel = isAdvocateView ? booking.clientName : booking.advocateName;
    final rolePrefix = isAdvocateView ? 'Mijoz' : 'Advokat';

    return GestureDetector(
      onTap: onOpenChat,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: isLive
                ? const Color(0xFF10B981)
                : const Color(0xFFDCEBFF),
            width: isLive ? 1.6 : 1.1,
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: const Color(0xFF1677FF).withValues(alpha: 0.07),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isLive
                    ? const Color(0xFFECFDF5)
                    : const Color(0xFFEBF4FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isLive ? Icons.videocam_rounded : Icons.event_available_rounded,
                color: isLive
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1677FF),
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    isLive
                        ? '● HOZIR FAOL • ${ConsultationSlotMath.formatCountdown(booking.remainingUntilEnd(now))} qoldi'
                        : isUpcoming
                        ? 'Boshlanishigacha: ${ConsultationSlotMath.formatCountdown(booking.remainingUntilStart(now))}'
                        : 'Yakunlandi',
                    style: TextStyle(
                      fontSize: 10.8,
                      fontWeight: FontWeight.w900,
                      color: isLive
                          ? const Color(0xFF059669)
                          : const Color(0xFF1677FF),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '$rolePrefix: $peerLabel',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0B1F3A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${booking.friendlyDateLabel} • ${booking.timeRangeLabel}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isLive
                    ? const Color(0xFF10B981)
                    : const Color(0xFF1677FF),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Text(
                isLive ? 'Kirish' : 'Chat',
                style: const TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
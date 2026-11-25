import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_callkit_incoming/entities/android_params.dart';
import 'package:flutter_callkit_incoming/entities/call_event.dart';
import 'package:flutter_callkit_incoming/entities/call_kit_params.dart';
import 'package:flutter_callkit_incoming/entities/ios_params.dart';
import 'package:flutter_callkit_incoming/entities/notification_params.dart';
import 'package:flutter_callkit_incoming/flutter_callkit_incoming.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Displays the native Android/iOS full-screen incoming call UI (works even
/// when the app is terminated or the phone screen is locked).
Future<void> showNativeIncomingCallUi(Map<String, dynamic> data) async {
  final callId = (data['call_id']?.toString() ?? '').trim();
  if (callId.isEmpty) return;

  final callerName =
      (data['caller_name']?.toString() ?? 'YAN360').trim().isEmpty
          ? 'YAN360'
          : data['caller_name'].toString().trim();
  final isVideo =
      (data['call_type']?.toString() ?? '').toLowerCase() == 'video';

  final params = CallKitParams(
    id: callId,
    nameCaller: callerName,
    appName: 'YAN360',
    handle: isVideo
        ? 'Kiruvchi video qo‘ng‘iroq'
        : 'Kiruvchi ovozli qo‘ng‘iroq',
    type: isVideo ? 1 : 0,
    duration: 45000,
    textAccept: 'Javob berish',
    textDecline: 'Rad etish',
    missedCallNotification: const NotificationParams(
      showNotification: true,
      isShowCallback: false,
      subtitle: 'O‘tkazib yuborilgan qo‘ng‘iroq',
      callbackText: 'Qayta qo‘ng‘iroq',
    ),
    extra: Map<String, dynamic>.from(data),
    android: const AndroidParams(
      isCustomNotification: true,
      isShowLogo: false,
      ringtonePath: 'system_ringtone_default',
      backgroundColor: '#102B50',
      actionColor: '#10B981',
      textColor: '#FFFFFF',
      incomingCallNotificationChannelName: 'Kiruvchi qo‘ng‘iroqlar',
      missedCallNotificationChannelName: 'O‘tkazib yuborilgan qo‘ng‘iroqlar',
      isShowCallID: false,
      isShowFullLockedScreen: true,
    ),
    ios: const IOSParams(
      iconName: 'AppIcon',
      handleType: 'generic',
      supportsVideo: true,
      maximumCallGroups: 1,
      maximumCallsPerCallGroup: 1,
      audioSessionMode: 'default',
      audioSessionActive: true,
      audioSessionPreferredSampleRate: 44100.0,
      audioSessionPreferredIOBufferDuration: 0.005,
      supportsDTMF: false,
      supportsHolding: false,
      supportsGrouping: false,
      supportsUngrouping: false,
      ringtonePath: 'system_ringtone_default',
    ),
  );

  await FlutterCallkitIncoming.showCallkitIncoming(params);
}

/// Top-level background handler required by Firebase Messaging when the app is
/// in the background or completely closed.
@pragma('vm:entry-point')
Future<void> yanFirebaseBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}

  final type = (message.data['type']?.toString() ?? '').trim();
  if (type == 'incoming_call') {
    await showNativeIncomingCallUi(message.data);
  } else if (type == 'call_cancel') {
    final callId = (message.data['call_id']?.toString() ?? '').trim();
    if (callId.isNotEmpty) {
      await FlutterCallkitIncoming.endCall(callId);
    } else {
      await FlutterCallkitIncoming.endAllCalls();
    }
  }
}

/// Manages Firebase Cloud Messaging (FCM) tokens, Android 13+/iOS permissions,
/// foreground heads-up notifications, native lock-screen CallKit ringing, and
/// authenticated Supabase Edge Function push delivery.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  static const String _androidChannelId = 'yan360_updates';
  static const String _androidChannelName = 'YAN360 bildirishnomalari';
  static const String _androidChannelDesc =
      'Yangi xabarlar, shartnomalar, konsultatsiyalar va ish jarayoni yangilanishlari';

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _firebaseReady = false;
  String? _currentToken;
  StreamSubscription<String>? _tokenRefreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;
  StreamSubscription<CallEvent?>? _callkitSub;

  /// Callbacks wired by `_YanGlobalCallCenter` in `main.dart`.
  void Function(Map<String, dynamic> callData)? onCallKitAccept;
  void Function(Map<String, dynamic> callData)? onCallKitDecline;
  Map<String, dynamic>? _pendingAcceptedCall;

  /// Returns and clears any call that was accepted from the lock screen while
  /// the app was cold-starting.
  Future<Map<String, dynamic>?> consumePendingAcceptedCall() async {
    if (_pendingAcceptedCall != null) {
      final data = _pendingAcceptedCall;
      _pendingAcceptedCall = null;
      return data;
    }
    try {
      final active = await FlutterCallkitIncoming.activeCalls();
      if (active is List && active.isNotEmpty) {
        final first = active.first;
        if (first is Map) {
          final extra = first['extra'];
          if (extra is Map && (extra['call_id']?.toString() ?? '').isNotEmpty) {
            return Map<String, dynamic>.from(extra);
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> endCallKitCall(String? callId) async {
    try {
      if (callId != null && callId.trim().isNotEmpty) {
        await FlutterCallkitIncoming.endCall(callId.trim());
      } else {
        await FlutterCallkitIncoming.endAllCalls();
      }
    } catch (_) {}
  }

  /// Call once during app startup (after `WidgetsFlutterBinding.ensureInitialized()`
  /// and `Supabase.initialize(...)`). Safe even if Firebase isn't configured yet.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    await _initLocalNotifications();
    _initCallKitListeners();

    try {
      await Firebase.initializeApp();
      _firebaseReady = true;
    } catch (e) {
      debugPrint(
        'PushNotificationService: Firebase not configured yet ($e). '
        'Add android/app/google-services.json to enable background push.',
      );
      return;
    }

    try {
      FirebaseMessaging.onBackgroundMessage(yanFirebaseBackgroundHandler);

      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _foregroundSub?.cancel();
      _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
        final type = (message.data['type']?.toString() ?? '').trim();
        if (type == 'incoming_call') {
          // While app is open, _YanGlobalCallCenter already opens the in-app
          // incoming call screen via Realtime; skip duplicate CallKit sheet.
          return;
        }
        if (type == 'call_cancel') {
          endCallKitCall(message.data['call_id']?.toString());
          return;
        }
        final notif = message.notification;
        final title =
            notif?.title ?? message.data['title']?.toString() ?? 'YAN360';
        final body = notif?.body ?? message.data['body']?.toString() ?? '';
        if (body.isNotEmpty) {
          showLocalBanner(title: title, body: body);
        }
      });

      _tokenRefreshSub?.cancel();
      _tokenRefreshSub = FirebaseMessaging.instance.onTokenRefresh.listen(
        (newToken) {
          _currentToken = newToken;
          syncCurrentUserToken();
        },
      );

      await syncCurrentUserToken();
    } catch (e) {
      debugPrint('PushNotificationService setup warning: $e');
    }
  }

  void _initCallKitListeners() {
    try {
      _callkitSub?.cancel();
      _callkitSub = FlutterCallkitIncoming.onEvent.listen((event) {
        if (event == null) return;
        final body = event.body;
        Map<String, dynamic> callData = <String, dynamic>{};
        if (body is Map) {
          final extra = body['extra'];
          if (extra is Map) {
            callData = Map<String, dynamic>.from(extra);
          } else {
            callData = Map<String, dynamic>.from(body);
          }
        }
        if (callData.isEmpty) return;

        if (event.event == Event.actionCallAccept) {
          if (onCallKitAccept != null) {
            onCallKitAccept!(callData);
          } else {
            _pendingAcceptedCall = callData;
          }
        } else if (event.event == Event.actionCallDecline ||
            event.event == Event.actionCallTimeout) {
          onCallKitDecline?.call(callData);
        }
      });
    } catch (e) {
      debugPrint('CallKit listener warning: $e');
    }
  }

  Future<void> _initLocalNotifications() async {
    try {
      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      await _localNotifications.initialize(
        const InitializationSettings(android: androidInit, iOS: iosInit),
      );

      if (Platform.isAndroid) {
        final androidPlugin = _localNotifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>();
        await androidPlugin?.requestNotificationsPermission();
        await androidPlugin?.createNotificationChannel(
          const AndroidNotificationChannel(
            _androidChannelId,
            _androidChannelName,
            description: _androidChannelDesc,
            importance: Importance.max,
            playSound: true,
            enableVibration: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Local notifications init warning: $e');
    }
  }

  /// Displays a heads-up notification banner on the current device.
  Future<void> showLocalBanner({
    required String title,
    required String body,
  }) async {
    try {
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch.remainder(100000),
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _androidChannelId,
            _androidChannelName,
            channelDescription: _androidChannelDesc,
            importance: Importance.max,
            priority: Priority.high,
            playSound: true,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
      );
    } catch (e) {
      debugPrint('showLocalBanner warning: $e');
    }
  }

  /// Upserts the signed-in user's FCM token to `public.user_push_tokens`.
  Future<void> syncCurrentUserToken() async {
    if (!_firebaseReady) return;
    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) return;

    try {
      final token =
          _currentToken ?? await FirebaseMessaging.instance.getToken();
      if (token == null || token.trim().isEmpty) return;
      _currentToken = token.trim();

      await Supabase.instance.client.from('user_push_tokens').upsert(
        <String, dynamic>{
          'user_id': authUser.id,
          'fcm_token': _currentToken,
          'platform': Platform.isIOS ? 'ios' : 'android',
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'user_id,fcm_token',
      );
    } catch (e) {
      debugPrint('syncCurrentUserToken warning: $e');
    }
  }

  /// Removes the current device's FCM token from Supabase on logout.
  Future<void> clearCurrentUserToken() async {
    if (!_firebaseReady) return;
    final authUser = Supabase.instance.client.auth.currentUser;
    final token = _currentToken;
    if (authUser == null || token == null || token.isEmpty) return;

    try {
      await Supabase.instance.client
          .from('user_push_tokens')
          .delete()
          .eq('user_id', authUser.id)
          .eq('fcm_token', token);
    } catch (_) {}
  }

  /// Returns auth headers for the currently signed-in Supabase user.
  /// Returns null when unauthenticated so we never make unauthenticated calls.
  Map<String, String>? _authHeaders() {
    final accessToken =
        Supabase.instance.client.auth.currentSession?.accessToken.trim() ?? '';
    if (accessToken.isEmpty) return null;
    return <String, String>{'Authorization': 'Bearer $accessToken'};
  }

  /// Sends a standard notification push via the hardened `send-push` Edge Function.
  Future<void> notifyUser({
    required String targetUserId,
    required String title,
    required String body,
    Map<String, String>? data,
  }) async {
    final cleanTarget = targetUserId.trim();
    if (cleanTarget.isEmpty) return;

    final myId = Supabase.instance.client.auth.currentUser?.id ?? '';
    if (myId.isNotEmpty && myId == cleanTarget) return;

    final headers = _authHeaders();
    if (headers == null) return;

    try {
      await Supabase.instance.client.functions.invoke(
        'send-push',
        headers: headers,
        body: <String, dynamic>{
          'target_user_id': cleanTarget,
          'title': title,
          'body': body,
          'data': data ?? const <String, String>{},
        },
      );
    } catch (e) {
      debugPrint('notifyUser Edge Function warning: $e');
    }
  }

  /// Sends a HIGH-PRIORITY DATA-ONLY push that wakes up the target phone even
  /// when YAN360 is closed or locked, launching the native CallKit ringing screen.
  Future<void> sendIncomingCallPush({
    required String targetUserId,
    required Map<String, dynamic> callSignal,
  }) async {
    final cleanTarget = targetUserId.trim();
    if (cleanTarget.isEmpty) return;

    final headers = _authHeaders();
    if (headers == null) return;

    final dataMap = <String, String>{
      'type': 'incoming_call',
      'call_id': (callSignal['call_id']?.toString() ?? '').trim(),
      'call_type': (callSignal['call_type']?.toString() ?? 'audio').trim(),
      'caller_id': (callSignal['caller_id']?.toString() ?? '').trim(),
      'caller_name': (callSignal['caller_name']?.toString() ?? 'YAN360').trim(),
      'caller_initials':
          (callSignal['caller_initials']?.toString() ?? 'Y').trim(),
      'callee_id': (callSignal['callee_id']?.toString() ?? cleanTarget).trim(),
      'room_key': (callSignal['room_key']?.toString() ?? '').trim(),
      if (callSignal['consultation_id'] != null)
        'consultation_id': callSignal['consultation_id'].toString(),
      if (callSignal['consultation_deadline_iso'] != null)
        'consultation_deadline_iso':
            callSignal['consultation_deadline_iso'].toString(),
    };

    try {
      await Supabase.instance.client.functions.invoke(
        'send-push',
        headers: headers,
        body: <String, dynamic>{
          'target_user_id': cleanTarget,
          'data_only': true,
          'data': dataMap,
        },
      );
    } catch (e) {
      debugPrint('sendIncomingCallPush warning: $e');
    }
  }

  /// Dismisses the native CallKit ringing screen on the target phone if the
  /// caller hangs up before the callee answers.
  Future<void> sendCallCancelPush({
    required String targetUserId,
    required String callId,
  }) async {
    final cleanTarget = targetUserId.trim();
    if (cleanTarget.isEmpty || callId.trim().isEmpty) return;

    final headers = _authHeaders();
    if (headers == null) return;

    try {
      await Supabase.instance.client.functions.invoke(
        'send-push',
        headers: headers,
        body: <String, dynamic>{
          'target_user_id': cleanTarget,
          'data_only': true,
          'data': <String, String>{
            'type': 'call_cancel',
            'call_id': callId.trim(),
          },
        },
      );
    } catch (e) {
      debugPrint('sendCallCancelPush warning: $e');
    }
  }
}
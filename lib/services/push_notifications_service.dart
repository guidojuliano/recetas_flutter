import 'dart:async';
import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:recetas_flutter/config/env_config.dart';
import 'package:recetas_flutter/providers/recipes_providers.dart';
import 'package:recetas_flutter/screens/recipe_detail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationsService {
  PushNotificationsService._();

  static final PushNotificationsService instance = PushNotificationsService._();
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static const AndroidNotificationChannel _androidChannel =
      AndroidNotificationChannel(
        'cookly_recipes_channel',
        'Cookly Notifications',
        description: 'New recipes from followed users',
        importance: Importance.high,
      );

  bool _initialized = false;
  String? _lastToken;
  StreamSubscription<String>? _tokenSubscription;
  StreamSubscription<AuthState>? _authSubscription;

  Future<void> initialize(GlobalKey<NavigatorState> navigatorKey) async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _initializeLocalNotifications(navigatorKey);

      await _messaging.requestPermission(alert: true, badge: true, sound: true);

      await _syncTokenWithBackend();
      _tokenSubscription = _messaging.onTokenRefresh.listen((token) {
        _lastToken = token;
        unawaited(_syncTokenWithBackend(tokenOverride: token));
      });

      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((authState) {
            if (authState.session == null) {
              if (_lastToken != null) {
                unawaited(_deactivateToken(_lastToken!));
              }
            } else {
              unawaited(_syncTokenWithBackend());
            }
          });

      FirebaseMessaging.onMessage.listen((message) {
        unawaited(_showForegroundNotification(message));
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        unawaited(_handleRecipeNavigationFromData(message.data, navigatorKey));
      });

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        await _handleRecipeNavigationFromData(
          initialMessage.data,
          navigatorKey,
        );
      }
    } catch (_) {
      // Keep app running if notification setup fails on current platform/config.
    }
  }

  Future<void> _initializeLocalNotifications(
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _localNotificationsPlugin.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        final dynamic decoded = jsonDecode(payload);
        if (decoded is Map<String, dynamic>) {
          unawaited(_handleRecipeNavigationFromData(decoded, navigatorKey));
        }
      },
    );

    final androidNotifications = _localNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidNotifications?.createNotificationChannel(_androidChannel);
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'cookly_recipes_channel',
      'Cookly Notifications',
      channelDescription: 'New recipes from followed users',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final payload = jsonEncode(message.data);
    await _localNotificationsPlugin.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> _syncTokenWithBackend({String? tokenOverride}) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final token = tokenOverride ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    _lastToken = token;

    final uri = Uri.parse('${EnvConfig.apiUrl}/me/push-token');
    try {
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'device_token': token, 'platform': _platformName}),
      );
    } catch (_) {
      // Best effort sync.
    }
  }

  Future<void> _deactivateToken(String token) async {
    final session = Supabase.instance.client.auth.currentSession;
    if (session == null) return;

    final uri = Uri.parse('${EnvConfig.apiUrl}/me/push-token');
    try {
      await http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${session.accessToken}',
        },
        body: jsonEncode({'device_token': token}),
      );
    } catch (_) {
      // Best effort sync.
    }
  }

  Future<void> unregisterCurrentToken() async {
    final token = _lastToken ?? await _messaging.getToken();
    if (token == null || token.isEmpty) return;
    await _deactivateToken(token);
  }

  Future<void> _handleRecipeNavigationFromData(
    Map<String, dynamic> data,
    GlobalKey<NavigatorState> navigatorKey,
  ) async {
    final recipeId = data['recipe_id'];
    if (recipeId is! String || recipeId.isEmpty) return;

    final context = navigatorKey.currentContext;
    if (context == null) return;

    final recipesProvider = Provider.of<RecipesProvider>(
      context,
      listen: false,
    );
    if (recipesProvider.recipes.isEmpty) {
      await recipesProvider.fetchRecipes();
    }

    final candidates = recipesProvider.recipes.where(
      (recipe) => recipe.id == recipeId,
    );
    if (candidates.isEmpty) return;

    final recipe = candidates.first;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => RecipeDetail(recipe: recipe)),
    );
  }

  String get _platformName {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      default:
        return 'android';
    }
  }

  Future<void> dispose() async {
    await _tokenSubscription?.cancel();
    await _authSubscription?.cancel();
  }
}

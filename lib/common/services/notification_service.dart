import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

// 1. Mandatory Top-Level Background Message Handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('NotificationService: Handling background message ${message.messageId}');
}

class NotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // --- CONFIGURATION ---
  // IMPORTANT: Enable "Cloud Messaging API (Legacy)" in Google Cloud Console to get this key.
  static const String _serverKey = 'PASTE_YOUR_FIREBASE_SERVER_KEY_HERE';

  static Future<void> initialize() async {
    // 2. Request Permissions
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true, 
      badge: true, 
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('NotificationService: User granted permission');

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Foreground handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('NotificationService: Foreground message received: ${message.notification?.title}');
      });

      // Handle notification when app is opened from background/terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        debugPrint('NotificationService: App opened from notification. Data: ${message.data}');
      });

      // 3. Get and Log Token for Testing
      try {
        String? token = await _messaging.getToken();
        if (token != null) {
          debugPrint('FCM_TOKEN_FOR_TESTING: $token'); 
          await saveTokenToFirestore(token);
        }
      } catch (e) {
        debugPrint('NotificationService: Error getting token: $e');
      }

      _messaging.onTokenRefresh.listen(saveTokenToFirestore);
    }
  }

  /// Sends a push notification to the partner user in the group.
  static Future<void> sendNotificationToPartner({
    required String groupId,
    required String senderName,
    required String verseRef,
    String? verseContent,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // 1. Find the partner's UID from the group members in Firestore
      final groupSnap = await FirebaseFirestore.instance.collection('groups_sharing').doc(groupId).get();
      if (!groupSnap.exists) return;

      final memberUids = List<String>.from(groupSnap.data()?['memberUids'] ?? []);
      
      // Identify the partner UID (the one that isn't me)
      final partnerUid = memberUids.firstWhere((uid) => uid != user.uid, orElse: () => "");
      if (partnerUid.isEmpty) return;

      // 2. Fetch partner's FCM token from their user profile
      final partnerSnap = await FirebaseFirestore.instance.collection('users').doc(partnerUid).get();
      final partnerToken = partnerSnap.data()?['fcm_token'];

      if (partnerToken == null) {
        debugPrint('NotificationService: Partner has no token saved in Firestore.');
        return;
      }

      final String bodyText = verseContent != null 
          ? '$senderName shared a verse: "$verseContent" ($verseRef)' 
          : '$senderName shared $verseRef with you!';

      // 3. POST the notification payload to FCM Legacy API
      final response = await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'key=$_serverKey',
        },
        body: jsonEncode({
          'to': partnerToken,
          'notification': {
            'title': 'New Bible Verse Shared! 🔥',
            'body': bodyText,
            'sound': 'default',
            'image': 'https://cdn-icons-png.flaticon.com/512/426/426833.png',
          },
          'data': {
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'groupId': groupId,
          },
          'priority': 'high',
        }),
      );

      if (response.statusCode == 200) {
        debugPrint('Notification sent successfully to partner.');
      } else {
        debugPrint('Failed to send notification: ${response.body}');
      }
    } catch (e) {
      debugPrint('Error in sendNotificationToPartner: $e');
    }
  }

  /// Logic called by Workmanager to check streaks and sync activity
  static Future<void> checkStreaksAndNotify() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Update activity timestamp to help determine "inactivity" for notifications
    await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
      'last_active_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    debugPrint('NotificationService: Activity synced to Firestore');
  }

  static Future<void> saveTokenToFirestore(String token) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'fcm_token': token,
        'last_active_at': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCM Token synced for user: ${user.uid}');
    }
  }
}

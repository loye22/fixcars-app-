// Add these methods to your ApiService class
import 'package:onesignal_flutter/onesignal_flutter.dart';

import 'api_service.dart';

class OneSignalService {
  static final ApiService _apiService = ApiService();

  static Future<void> initializeOneSignal() async {
    try {
      // Initialize with your App ID only


    //  await OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize("ac3a9463-87dc-4dda-becd-fb4d0c4382cc");

      // Request notification permission
      OneSignal.Notifications.requestPermission(true);


      // Handle notification clicks
      OneSignal.Notifications.addClickListener((event) {
        final data = event.notification.jsonRepresentation();
        print('Notification clicked: $data');
        // Handle navigation based on notification data
      });


      // Get player ID and register with backend
      OneSignal.User.pushSubscription.addObserver((state) {
        if (state.current.id != null) {

          _registerDevice(state.current.id!);
        }
      });

      print('OneSignal initialized successfully');
    } catch (e) {
      print('Error initializing OneSignal: $e');
    }
  }

  static Future<void> _registerDevice(String playerId) async {
    try {
      // Use your existing authenticatedPost method

      final response = await _apiService.authenticatedPost(
        '${ApiService.baseUrl}/register-device/',
        {'player_id': playerId},
      );



      if (response.statusCode == 200) {
        print('Device registered successfully with backend');
      } else {
        print('Failed to register device: ${response.body}');
      }
    } catch (e) {
      print('Error registering device: $e');
    }
  }

  static Future<bool> sendNotification({
    required String userId,
    required String message,
    String heading = 'Notification',
    Map<String, dynamic>? data,
  }) async {
    try {
      // Use your existing authenticatedPost method
      final response = await _apiService.authenticatedPost(
        '${ApiService.baseUrl}/send-notification/',
        {
          'user_id': userId,
          'message': message,
          'heading': heading,
          'data': data ?? {},
        },
      );

      // print("==================================================================================================");
      // print('Backend Response Status: ${response.statusCode}');
      // print('Backend Response Body: ${response.body}');

      return response.statusCode == 200;
    } catch (e) {
      print('Error sending notification: $e');
      return false;
    }
  }
}
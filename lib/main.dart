import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pooja_pasal/app/app.dart';
import 'package:pooja_pasal/core/services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Firebase is only used for push notifications; everything else talks
  // to the Laravel API (core/network/api_client.dart).
  await PushNotificationService.bootstrap();
  runApp(const ProviderScope(child: App()));
}

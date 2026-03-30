import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:cropsense_ai/main.dart';
import 'package:cropsense_ai/services/app_settings.dart';
import 'package:cropsense_ai/data/rwanda_locations.dart';
import 'package:cropsense_ai/l10n/app_localizations.dart';
import 'package:cropsense_ai/screens/login_screen.dart';
import 'package:cropsense_ai/screens/register_screen.dart';
import 'package:cropsense_ai/screens/forgot_password_screen.dart';
import 'package:cropsense_ai/screens/season_screen.dart';

/// Wraps a widget with MaterialApp + localization delegates for testing.
Widget _testApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: child,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  // ── 1. App boot ───────────────────────────────────────────────────────────

  testWidgets('1. App shows login screen when not authenticated', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.init();
    await tester.pumpWidget(const CropSenseApp());
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('CropSense AI'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('2. Main navigator has four bottom tabs', (tester) async {
    await tester.pumpWidget(_testApp(const MainNavigator()));
    await tester.pump();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Process'), findsOneWidget);
    expect(find.text('Season'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
  });

  // ── 2. Login screen ──────────────────────────────────────────────────────

  testWidgets('3. Login screen has email and password fields', (tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
  });

  testWidgets('4. Login screen has forgot password link', (tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('5. Login screen has register link', (tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    expect(find.text("Don't have an account? "), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Register'), findsOneWidget);
  });

  // ── 3. Register screen ───────────────────────────────────────────────────

  testWidgets('6. Register screen has all required fields', (tester) async {
    await tester.pumpWidget(_testApp(const RegisterScreen()));
    await tester.pump();

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Full Name'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Email'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Phone Number'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Password'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });

  testWidgets('7. Register screen has province and district dropdowns', (tester) async {
    await tester.pumpWidget(_testApp(const RegisterScreen()));
    await tester.pump();

    expect(find.widgetWithText(DropdownButtonFormField<String>, 'Province'), findsOneWidget);
    expect(find.widgetWithText(DropdownButtonFormField<String>, 'District'), findsOneWidget);
  });

  // ── 4. Forgot password screen ────────────────────────────────────────────

  testWidgets('8. Forgot password screen shows email form', (tester) async {
    await tester.pumpWidget(_testApp(const ForgotPasswordScreen()));
    await tester.pump();

    expect(find.text('Reset Password'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'you@example.com'), findsOneWidget);
    expect(find.text('Send reset instructions'), findsOneWidget);
  });

  testWidgets('9. Forgot password has back to login navigation', (tester) async {
    await tester.pumpWidget(_testApp(const ForgotPasswordScreen()));
    await tester.pump();

    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    expect(find.text('you@example.com'), findsOneWidget);
  });

  // ── 5. Season screen ─────────────────────────────────────────────────────

  testWidgets('10. Season screen shows Rwanda seasons info', (tester) async {
    await tester.pumpWidget(_testApp(const SeasonScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Rwanda Seasons'), findsOneWidget);
    expect(find.textContaining('farming calendar'), findsOneWidget);
  });

  // ── 6. AppSettings ───────────────────────────────────────────────────────

  test('11. AppSettings defaults notifications to true', () async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.init();
    expect(AppSettings.notificationsEnabled, isTrue);
    expect(AppSettings.notificationsNotifier.value, isTrue);
  });

  test('12. AppSettings persists notifications toggle off', () async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.init();

    await AppSettings.setNotifications(false);
    expect(AppSettings.notificationsEnabled, isFalse);
    expect(AppSettings.notificationsNotifier.value, isFalse);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('cropsense_notifications_v1'), isFalse);
  });

  test('13. AppSettings restores saved notification preference', () async {
    SharedPreferences.setMockInitialValues({'cropsense_notifications_v1': false});
    await AppSettings.init();
    expect(AppSettings.notificationsEnabled, isFalse);
    expect(AppSettings.notificationsNotifier.value, isFalse);
  });

  // ── 7. Rwanda locations data ─────────────────────────────────────────────

  test('14. Rwanda locations has all 5 provinces', () {
    final provinces = RwandaLocations.data.keys.toList();
    expect(provinces, contains('Kigali City'));
    expect(provinces, contains('Eastern Province'));
    expect(provinces, contains('Western Province'));
    expect(provinces, contains('Northern Province'));
    expect(provinces, contains('Southern Province'));
  });

  test('15. Each province has districts', () {
    for (final province in RwandaLocations.data.keys) {
      final data = RwandaLocations.data[province]!;
      final districts = (data['districts'] as Map).keys;
      expect(districts.isNotEmpty, isTrue, reason: '$province has no districts');
    }
  });

  test('16. Rwamagana is a district in Eastern Province', () {
    final eastern = RwandaLocations.data['Eastern Province']!;
    final districts = (eastern['districts'] as Map).keys.toList();
    expect(districts, contains('Rwamagana'));
  });

  // ── 8. ValueNotifier reactivity ──────────────────────────────────────────

  test('17. Notifications notifier fires on toggle', () async {
    SharedPreferences.setMockInitialValues({});
    await AppSettings.init();

    final values = <bool>[];
    AppSettings.notificationsNotifier.addListener(() {
      values.add(AppSettings.notificationsNotifier.value);
    });

    await AppSettings.setNotifications(false);
    await AppSettings.setNotifications(true);

    expect(values, [false, true]);
  });

  // ── 9. Navigation ────────────────────────────────────────────────────────

  testWidgets('18. Tapping Register link navigates to register screen', (tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, 'Register'));
    await tester.pumpAndSettle();

    expect(find.text('Create Account'), findsOneWidget);
  });

  testWidgets('19. Tapping Forgot Password navigates to reset screen', (tester) async {
    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    await tester.tap(find.text('Forgot password?'));
    await tester.pumpAndSettle();

    expect(find.text('Reset Password'), findsOneWidget);
  });

  // ── 10. Locale & overflow ─────────────────────────────────────────────────

  testWidgets('20. Login screen renders without overflow', (tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(_testApp(const LoginScreen()));
    await tester.pump();

    expect(find.text('CropSense AI'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Forgot password?'), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

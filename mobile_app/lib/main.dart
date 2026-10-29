import 'widgets/app_snack_bar.dart';
import 'screens/shared_job_screen.dart';
import 'services/job_links.dart';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'screens/login_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/contractor_home_screen.dart';
import 'services/api_service.dart';
import 'services/kyc_camera.dart';
import 'theme/app_theme.dart';
import 'services/push_notifications.dart';
import 'screens/notifications_screen.dart';
import 'widgets/adaptive_viewport.dart';
import 'theme/appearance_controller.dart';

final _navigator = GlobalKey<NavigatorState>();
final _messenger = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  await api.restoreSession();
  await KycCamera.instance.restoreLostPhoto();
  api.addListener(() {
    if (api.session == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (api.session == null) {
          _navigator.currentState?.popUntil((route) => route.isFirst);
        }
      });
    }
  });
  final push = PushNotifications.instance;
  await push.initialize();
  push.attach(api);
  push.onOpen = () {
    if (api.session != null) {
      _navigator.currentState?.push(
        MaterialPageRoute<void>(builder: (_) => NotificationsScreen(api: api)),
      );
    }
  };
  push.onForeground = (title) {
    if (api.session != null) {
      _messenger.currentState?.showSnackBar(
        AppSnackBar(content: Text(title), kind: NoticeKind.info),
      );
    }
  };
  final appearance = AppearanceController();
  await appearance.restore();
  runApp(ThoXayApp(api: api, appearance: appearance));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => push.openInitialIfNeeded(),
  );
}

class ThoXayApp extends StatefulWidget {
  const ThoXayApp({super.key, required this.api, this.appearance});
  final ApiService api;
  final AppearanceController? appearance;
  @override
  State<ThoXayApp> createState() => _ThoXayAppState();
}

class _ThoXayAppState extends State<ThoXayApp> {
  late final AppearanceController _appearance =
      widget.appearance ?? AppearanceController();
  ApiService get api => widget.api;
  @override
  void dispose() {
    if (widget.appearance == null) _appearance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppearanceScope(
    controller: _appearance,
    child: ListenableBuilder(
      listenable: Listenable.merge([api, _appearance]),
      builder: (context, _) => MaterialApp(
        title: 'Thợ Xây',
        navigatorKey: _navigator,
        scaffoldMessengerKey: _messenger,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => AdaptiveViewport(child: child!),
        theme: AppTheme.forRole(
          api.session?.role,
          brightness: _appearance.brightness,
          outdoor: _appearance.mode == DisplayMode.outdoor,
        ),
        locale: const Locale('vi', 'VN'),
        supportedLocales: const [Locale('vi', 'VN'), Locale('en', 'US')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: ListenableBuilder(
          listenable: api,
          builder: (context, _) {
            if (api.session == null) return LoginScreen(api: api);
            final session = api.session!;
            if (session.role == 'ROLE_WORKER') {
              return SharedJobGate(
                api: api,
                jobId: JobLinks.parse(Uri.base),
                child: WorkerHomeScreen(api: api),
              );
            }
            if (session.role == 'ROLE_CONTRACTOR') {
              return SharedJobGate(
                api: api,
                jobId: JobLinks.parse(Uri.base),
                child: ContractorHomeScreen(api: api),
              );
            }
            return Scaffold(
              appBar: AppBar(title: const Text('Tài khoản Thợ Xây')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_user_outlined, size: 64),
                      const SizedBox(height: 16),
                      Text(
                        session.fullName,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Text(session.phoneNumber),
                      Text(
                        session.role == 'ROLE_ADMIN'
                            ? 'Quản trị hệ thống · /admin/dashboard'
                            : session.role == 'ROLE_WORKER'
                            ? 'Thợ'
                            : 'Chủ thầu',
                      ),
                      const SizedBox(height: 24),
                      OutlinedButton(
                        onPressed: api.logout,
                        child: const Text('Đăng xuất'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    ),
  );
}

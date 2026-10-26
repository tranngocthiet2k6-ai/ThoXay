import 'package:flutter/material.dart';

import 'screens/login_screen.dart';
import 'screens/worker_home_screen.dart';
import 'screens/contractor_home_screen.dart';
import 'services/api_service.dart';
import 'theme/app_theme.dart';
import 'services/push_notifications.dart';
import 'screens/notifications_screen.dart';

final _navigator = GlobalKey<NavigatorState>();
final _messenger = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  await api.restoreSession();
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
      _messenger.currentState?.showSnackBar(SnackBar(content: Text(title)));
    }
  };
  runApp(ThoXayApp(api: api));
  WidgetsBinding.instance.addPostFrameCallback(
    (_) => push.openInitialIfNeeded(),
  );
}

class ThoXayApp extends StatelessWidget {
  const ThoXayApp({super.key, required this.api});
  final ApiService api;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Thợ Xây',
    navigatorKey: _navigator,
    scaffoldMessengerKey: _messenger,
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light,
    home: ListenableBuilder(
      listenable: api,
      builder: (context, _) {
        if (api.session == null) return LoginScreen(api: api);
        final session = api.session!;
        if (session.role == 'ROLE_WORKER') {
          return WorkerHomeScreen(api: api);
        }
        if (session.role == 'ROLE_CONTRACTOR') {
          return ContractorHomeScreen(api: api);
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
  );
}

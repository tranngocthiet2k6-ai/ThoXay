import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiService();
  await api.restoreSession();
  runApp(ThoXayApp(api: api));
}

class ThoXayApp extends StatelessWidget {
  const ThoXayApp({super.key, required this.api});
  final ApiService api;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Thợ Xây',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff176b52)),
          scaffoldBackgroundColor: const Color(0xfff5f7f6),
          inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.white),
          useMaterial3: true,
        ),
        home: ListenableBuilder(
            listenable: api,
            builder: (context, _) {
              if (api.session == null) return LoginScreen(api: api);
              final session = api.session!;
              return Scaffold(
                appBar: AppBar(title: const Text('Tài khoản Thợ Xây')),
                body: Center(
                    child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.verified_user_outlined, size: 64),
                    const SizedBox(height: 16),
                    Text(session.fullName,
                        style: Theme.of(context).textTheme.headlineSmall),
                    Text(session.phoneNumber),
                    Text(session.role == 'ROLE_ADMIN'
                        ? 'Quản trị hệ thống · /admin/dashboard'
                        : session.role == 'ROLE_WORKER'
                            ? 'Thợ'
                            : 'Chủ thầu'),
                    const SizedBox(height: 24),
                    OutlinedButton(
                        onPressed: api.logout, child: const Text('Đăng xuất')),
                  ]),
                )),
              );
            }),
      );
}

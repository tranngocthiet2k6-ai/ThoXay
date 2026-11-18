import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/location_service.dart';
import '../widgets/brand_logo.dart';
import '../widgets/home_navigation.dart';
import 'worker_home_screen.dart';
import 'contractor_home_screen.dart';
import 'contractor_team_screen.dart';
import 'wallet_screen.dart';
import 'profile_screen.dart';
import 'settings_screen.dart';
import 'qr_hub_screen.dart';
import '../widgets/figma_design.dart';

/// One route, one AppBar, one NavigationBar. Tab state survives tab changes.
class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.api,
    required this.worker,
    this.location,
  });
  final ApiService api;
  final bool worker;
  final LocationService? location;
  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0, _workerTab = 0, _profileRevision = 0, _teamRevision = 0;
  final _visited = <int>{0};
  void _select(int index) => setState(() {
    _index = index;
    if (index < 2) _workerTab = index;
    _visited.add(index);
  });
  Future<void> _settings() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => SettingsScreen(api: widget.api)),
    );
    if (mounted && widget.api.session != null) {
      setState(() => _profileRevision++);
    }
  }

  Widget _tab(int index, Widget Function() build) => _visited.contains(index)
      ? TickerMode(enabled: _index == index, child: build())
      : const SizedBox.shrink();
  @override
  Widget build(BuildContext context) {
    final titles = widget.worker
        ? ['Tìm việc', 'Việc của tôi', 'Quét QR', 'Ví tiền', 'Hồ sơ']
        : ['Công trình', 'Đội thợ', 'Quét QR', 'Ví tiền', 'Hồ sơ'];
    final profile = _tab(
      4,
      () => ProfileScreen(
        key: ValueKey('profile-$_profileRevision'),
        api: widget.api,
        embedded: true,
      ),
    );
    final wallet = _tab(3, () => WalletScreen(api: widget.api, embedded: true));
    final qr = _tab(
      2,
      () => QrHubScreen(
        api: widget.api,
        worker: widget.worker,
        active: _index == 2,
        onWorkerSaved: () => setState(() => _teamRevision++),
      ),
    );
    return FigmaScreenTheme(
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 16,
          title: Row(
            children: [
              const BrandLogo(height: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  titles[_index],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          actions: [
            HomeInboxActions(api: widget.api),
            IconButton(
              tooltip: 'Cài đặt',
              onPressed: _settings,
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: IndexedStack(
          index: widget.worker ? (_index < 2 ? 0 : _index - 1) : _index,
          children: widget.worker
              ? [
                  TickerMode(
                    enabled: _index < 2,
                    child: WorkerHomeContent(
                      api: widget.api,
                      location: widget.location,
                      tab: _workerTab,
                      onTabChanged: _select,
                    ),
                  ),
                  qr,
                  wallet,
                  profile,
                ]
              : [
                  TickerMode(
                    enabled: _index == 0,
                    child: ContractorHomeContent(api: widget.api),
                  ),
                  _tab(
                    1,
                    () => ContractorTeamScreen(
                      key: ValueKey('team-$_teamRevision'),
                      api: widget.api,
                      onDiscover: () => _select(0),
                    ),
                  ),
                  qr,
                  wallet,
                  profile,
                ],
        ),
        bottomNavigationBar: HomeNavigation(
          api: widget.api,
          worker: widget.worker,
          selectedIndex: _index,
          onSelected: _select,
        ),
      ),
    );
  }
}

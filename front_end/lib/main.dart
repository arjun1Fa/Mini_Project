import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/app_config.dart';
import 'theme/app_theme.dart';
import 'screens/add_food_screen.dart';
import 'screens/history_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/manual_entry_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/splash_screen.dart';
import 'services/offline_service.dart';
import 'screens/auth_screen.dart';
import 'providers/api_provider.dart';
import 'providers/connectivity_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline storage
  await OfflineService.init();

  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: NutriVisionApp()));
}

class NutriVisionApp extends ConsumerWidget {
  const NutriVisionApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navigatorKey = ref.watch(navigatorKeyProvider);

    return MaterialApp(
      title: 'NutriVision',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      home: const SplashScreen(),
      routes: {
        '/home': (_) => const AppShell(),
        '/login': (_) => const AuthScreen(),
      },
    );
  }
}

// ── Destination model ─────────────────────────────────
class _Dest {
  final String label;
  final IconData icon;
  final IconData iconSelected;

  const _Dest(this.label, this.icon, this.iconSelected);
}

const _destinations = [
  _Dest('Add Food', Icons.add_circle_outline, Icons.add_circle),
  _Dest('History', Icons.bar_chart_outlined, Icons.bar_chart),
  _Dest('Insights', Icons.lightbulb_outline, Icons.lightbulb),
  _Dest('Profile', Icons.person_outline, Icons.person),
];

// ── App Shell ──────────────────────────────────────────
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  late final List<Widget> _screens = [
    AddFoodScreen(
      onGoToHistory: () => _go(1),
      onGoToManual: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          return Scaffold(
            backgroundColor: AppColors.cream,
            appBar: AppBar(
              backgroundColor: AppColors.cream.withOpacity(0.95),
              elevation: 0,
              iconTheme: const IconThemeData(color: AppColors.ink),
              title: Text('Manual Entry', style: GoogleFonts.dmSerifDisplay(fontSize: 18, color: AppColors.ink)),
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppColors.border),
              ),
            ),
            body: const ManualEntryScreen(),
          );
        }));
      }
    ),
    const HistoryScreen(),
    const InsightsScreen(),
    const ProfileScreen(),
  ];

  final _titles = ['Add Food', 'History', 'Insights', 'Profile'];

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 720;

    if (isWide) {
      return _DesktopShell(
        index: _index,
        onDestinationSelected: _go,
        screens: _screens,
        titles: _titles,
      );
    } else {
      return _MobileShell(
        index: _index,
        onDestinationSelected: _go,
        screens: _screens,
        titles: _titles,
      );
    }
  }
}

// ── Desktop / tablet shell (NavigationRail) ────────────
class _DesktopShell extends StatelessWidget {
  final int index;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> screens;
  final List<String> titles;

  const _DesktopShell({
    required this.index,
    required this.onDestinationSelected,
    required this.screens,
    required this.titles,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // ── Sidebar ──
          Container(
            width: 240,
            color: AppColors.ink,
            child: Column(
              children: [
                const SizedBox(height: 40),
                // Logo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.leafLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text('🌿', style: TextStyle(fontSize: 20)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.dmSerifDisplay(
                            fontSize: 22, color: AppColors.cream),
                        children: [
                          const TextSpan(text: 'Nutri'),
                          TextSpan(
                            text: 'Vision',
                            style: GoogleFonts.dmSerifDisplay(
                                color: AppColors.leafLight),
                          ),
                        ],
                      ),
                    ),
                  ]),
                ),

                const SizedBox(height: 36),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // Nav items
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    itemCount: _destinations.length,
                    itemBuilder: (ctx, i) {
                      final dest = _destinations[i];
                      final selected = index == i;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () => onDestinationSelected(i),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 13),
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.leaf
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(children: [
                                Icon(
                                  selected ? dest.iconSelected : dest.icon,
                                  size: 18,
                                  color: selected
                                      ? Colors.white
                                      : AppColors.inkFaint,
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  dest.label,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: selected
                                        ? Colors.white
                                        : AppColors.inkFaint,
                                  ),
                                ),
                              ]),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(color: Colors.white12, height: 1),

                // User footer
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(children: [
                    Container(
                      width: 38, height: 38,
                      decoration: const BoxDecoration(
                          color: AppColors.leaf, shape: BoxShape.circle),
                      child: Center(
                        child: Text('N',
                            style: GoogleFonts.dmSans(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('NutriVision User',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.cream),
                              overflow: TextOverflow.ellipsis),
                          Text('AI Food Diary',
                              style: GoogleFonts.dmSans(
                                  fontSize: 11, color: AppColors.inkFaint)),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // ── Content ──
          Expanded(
            child: Column(
              children: [
                // Top bar
                Container(
                  height: 68,
                  color: AppColors.cream.withOpacity(0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('Good morning 👋',
                              style: GoogleFonts.dmSans(
                                  fontSize: 13, color: AppColors.inkMuted)),
                          Text(titles[index],
                              style: GoogleFonts.dmSerifDisplay(
                                  fontSize: 20, color: AppColors.ink)),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: AppColors.creamDark,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          _formattedDate(),
                          style: GoogleFonts.dmMono(
                              fontSize: 12, color: AppColors.inkMuted),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: AppColors.border),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.03),
                          end: Offset.zero,
                        ).animate(anim),
                        child: child,
                      ),
                    ),
                    child: KeyedSubtree(
                      key: ValueKey(index),
                      child: screens[index],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mobile shell (BottomNavigationBar) ────────────────
class _MobileShell extends ConsumerWidget {
  final int index;
  final ValueChanged<int> onDestinationSelected;
  final List<Widget> screens;
  final List<String> titles;

  const _MobileShell({
    required this.index,
    required this.onDestinationSelected,
    required this.screens,
    required this.titles,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOffline = connectivityAsync.whenOrNull(data: (v) => !v) ?? false;
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(
              color: AppColors.leafLight,
              borderRadius: BorderRadius.circular(7),
            ),
            child: const Center(child: Text('🌿', style: TextStyle(fontSize: 14))),
          ),
          const SizedBox(width: 10),
          Text(titles[index],
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18, color: AppColors.ink)),
        ]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.creamDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(_formattedDate(),
                  style: GoogleFonts.dmMono(
                      fontSize: 10, color: AppColors.inkMuted)),
            ),
          ),
        ],
        backgroundColor: AppColors.cream.withOpacity(0.95),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: AppColors.border),
        ),
      ),
      body: Column(
        children: [
          // ── Offline Banner ──
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: isOffline ? 36 : 0,
            color: AppColors.amber,
            child: isOffline
                ? Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off, size: 14, color: Colors.white),
                        const SizedBox(width: 8),
                        Text('No Internet Connection',
                            style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey(index),
                child: screens[index],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: index,
          onTap: onDestinationSelected,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.cream,
          selectedItemColor: AppColors.leaf,
          unselectedItemColor: AppColors.inkFaint,
          selectedLabelStyle: GoogleFonts.dmSans(
              fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              GoogleFonts.dmSans(fontSize: 11, fontWeight: FontWeight.w400),
          elevation: 0,
          items: _destinations.map((d) => BottomNavigationBarItem(
            icon: Icon(d.icon),
            activeIcon: Icon(d.iconSelected),
            label: d.label,
          )).toList(),
        ),
      ),
    );
  }
}

String _formattedDate() {
  final now = DateTime.now();
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final dayName = days[now.weekday - 1];
  return '$dayName, ${months[now.month - 1]} ${now.day}';
}

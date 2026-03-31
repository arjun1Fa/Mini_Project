import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';
import 'auth_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  String _gender = 'Male';
  String _activity = 'Lightly Active';
  String _goal = 'Gain Muscle';
  String _plateType = 'standard';

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(text: '28');
  final _heightCtrl = TextEditingController(text: '178');
  final _weightCtrl = TextEditingController(text: '75');
  final _calorieCtrl = TextEditingController(text: '2000');

  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    await ref.read(profileProvider.notifier).load();
    final profile = ref.read(profileProvider).profile;
    if (profile != null && mounted) {
      setState(() {
        _nameCtrl.text = profile.fullName ?? '';
        _calorieCtrl.text = profile.dailyGoalKcal.toString();
        _plateType = profile.plateType;
        _loaded = true;
      });
    } else {
      // Use Supabase user email as fallback name
      final user = Supabase.instance.client.auth.currentUser;
      if (mounted) {
        setState(() {
          _nameCtrl.text = user?.email?.split('@').first ?? '';
          _loaded = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _calorieCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final updates = <String, dynamic>{
      'full_name': _nameCtrl.text.trim(),
      'daily_goal_kcal': int.tryParse(_calorieCtrl.text) ?? 2000,
      'plate_type': _plateType,
    };

    final ok = await ref.read(profileProvider.notifier).updateProfile(updates);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? '✅ Profile saved successfully!' : '❌ Failed to save',
          style: GoogleFonts.dmSans(),
        ),
        backgroundColor: ok ? AppColors.leaf : AppColors.amber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _logout() async {
    try {
      final auth = ref.read(authServiceProvider);
      await auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error signing out: $e', style: GoogleFonts.dmSans()),
          backgroundColor: AppColors.amber,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isWide = MediaQuery.of(context).size.width > 700;

    if (profileState.isLoading && !_loaded) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.leaf, strokeWidth: 2),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            label: 'Account',
            title: 'Your Profile',
            subtitle: 'Manage your personal details and goals',
          ),

          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildLeft()),
                const SizedBox(width: 24),
                Expanded(child: _buildRight()),
              ],
            )
          else
            Column(children: [
              _buildLeft(),
              const SizedBox(height: 20),
              _buildRight(),
            ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildLeft() {
    final user = Supabase.instance.client.auth.currentUser;
    final initials = _nameCtrl.text.isNotEmpty
        ? _nameCtrl.text[0].toUpperCase()
        : (user?.email?[0].toUpperCase() ?? 'N');

    return Column(
      children: [
        // Hero card
        NvCard(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                    color: AppColors.leaf, shape: BoxShape.circle),
                child: Center(
                  child: Text(initials,
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 36, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _nameCtrl.text.isEmpty ? 'NutriVision User' : _nameCtrl.text,
                style: GoogleFonts.dmSerifDisplay(
                    fontSize: 22, color: AppColors.ink),
              ),
              const SizedBox(height: 4),
              Text(
                user?.email ?? '',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 24),
              const Divider(color: AppColors.border),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _profileStat('—', 'Meals'),
                  _profileStat('—', 'Day Streak'),
                  _profileStat('—', 'Avg Score'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Personal info
        NvCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Personal Info',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18, color: AppColors.ink)),
              const SizedBox(height: 20),

              _label('Name'),
              TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Your name')),
              const SizedBox(height: 16),

              _label('Age'),
              TextField(
                  controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Your age')),
              const SizedBox(height: 16),

              _label('Gender'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ['Male', 'Female', 'Other']
                    .map((g) => NvChip(
                          label: g,
                          selected: _gender == g,
                          onTap: () => setState(() => _gender = g),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 16),

              _label('Height & Weight'),
              Row(children: [
                Expanded(
                  child: TextField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: 'Height (cm)'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _weightCtrl,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(hintText: 'Weight (kg)'),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRight() {
    return Column(
      children: [
        // Goals card
        NvCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Activity & Goals',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18, color: AppColors.ink)),
              const SizedBox(height: 20),

              _label('Activity Level'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'Sedentary',
                  'Lightly Active',
                  'Moderately Active',
                  'Very Active'
                ]
                    .map((a) => NvChip(
                          label: a,
                          selected: _activity == a,
                          onTap: () => setState(() => _activity = a),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              _label('Goal'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children:
                    ['Lose Weight', 'Maintain Weight', 'Gain Muscle']
                        .map((g) => NvChip(
                              label: g,
                              selected: _goal == g,
                              onTap: () => setState(() => _goal = g),
                            ))
                        .toList(),
              ),
              const SizedBox(height: 20),

              _label('Plate Type'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ('standard', 'Standard'),
                  ('thali', 'Thali'),
                  ('katori', 'Katori'),
                  ('side', 'Side'),
                ]
                    .map((e) => NvChip(
                          label: e.$2,
                          selected: _plateType == e.$1,
                          onTap: () =>
                              setState(() => _plateType = e.$1),
                        ))
                    .toList(),
              ),
              const SizedBox(height: 20),

              _label('Daily Calorie Target'),
              TextField(
                controller: _calorieCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'e.g. 2000'),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _save,
                  child: const Text('Save Changes'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // Account card
        NvCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Account',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18, color: AppColors.ink)),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.amber,
                    side: const BorderSide(color: AppColors.amber),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('Log Out',
                      style: GoogleFonts.dmSans(
                          fontWeight: FontWeight.w600, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileStat(String val, String label) {
    return Column(children: [
      Text(val,
          style: GoogleFonts.dmSerifDisplay(
              fontSize: 24, color: AppColors.ink)),
      const SizedBox(height: 4),
      Text(label,
          style:
              GoogleFonts.dmSans(fontSize: 12, color: AppColors.inkMuted)),
    ]);
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}

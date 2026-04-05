import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';
import '../providers/profile_provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isEditing = false;
  bool _loaded = false;

  // Editable fields
  String _gender = 'Male';
  String _activity = 'Lightly Active';
  String _goal = 'Gain Muscle';
  String _plateType = 'standard';

  final _nameCtrl = TextEditingController();
  final _ageCtrl = TextEditingController(text: '28');
  final _heightCtrl = TextEditingController(text: '178');
  final _weightCtrl = TextEditingController(text: '75');
  final _calorieCtrl = TextEditingController(text: '2000');

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
        if (profile.age != null) _ageCtrl.text = profile.age.toString();
        if (profile.heightCm != null) _heightCtrl.text = profile.heightCm.toString();
        if (profile.weightKg != null) _weightCtrl.text = profile.weightKg.toString();
        if (profile.gender != null && ['Male', 'Female', 'Other'].contains(profile.gender)) {
          _gender = profile.gender!;
        }
        if (profile.activityLevel != null && ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active'].contains(profile.activityLevel)) {
          _activity = profile.activityLevel!;
        }
        if (profile.goal != null && ['Lose Weight', 'Maintain Weight', 'Gain Muscle'].contains(profile.goal)) {
          _goal = profile.goal!;
        }
        _loaded = true;
      });
    } else {
      if (mounted) {
        setState(() {
          _nameCtrl.text = '';
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
      'age': int.tryParse(_ageCtrl.text),
      'height_cm': double.tryParse(_heightCtrl.text),
      'weight_kg': double.tryParse(_weightCtrl.text),
      'gender': _gender,
      'activity_level': _activity,
      'goal': _goal,
    };

    final ok = await ref.read(profileProvider.notifier).updateProfile(updates);

    if (mounted) {
      setState(() => _isEditing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
          ok ? '✅ Profile saved successfully!' : '❌ Failed to save. Check your connection.',
          style: GoogleFonts.dmSans(),
        ),
        backgroundColor: ok ? AppColors.leaf : AppColors.amber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  String get _userEmail {
    try {
      return Supabase.instance.client.auth.currentUser?.email ?? 'No email';
    } catch (_) {
      return 'No email';
    }
  }

  String get _displayName {
    final name = _nameCtrl.text.trim();
    return name.isNotEmpty ? name : 'NutriVision User';
  }

  String get _initials {
    final name = _displayName;
    final parts = name.split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  static const _plateLabels = {
    'standard': 'Standard',
    'thali': 'Thali',
    'katori': 'Katori',
    'side': 'Side',
  };

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);

    // Loading state
    if (profileState.isLoading && !_loaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.leaf, strokeWidth: 2),
            const SizedBox(height: 16),
            Text('Loading profile…',
                style: GoogleFonts.dmSans(color: AppColors.inkMuted, fontSize: 14)),
          ],
        ),
      );
    }

    // Error state with retry
    if (profileState.error != null && !_loaded) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('😕', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text('Could not load profile',
                style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppColors.ink)),
            const SizedBox(height: 8),
            Text('Check your internet connection',
                style: GoogleFonts.dmSans(fontSize: 14, color: AppColors.inkMuted)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _loaded = false);
                _loadProfile();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.leaf,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with edit button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: SectionHeader(
                  label: 'Account',
                  title: 'Your Profile',
                  subtitle: 'Manage your personal details and goals',
                ),
              ),
              if (!_isEditing)
                TextButton.icon(
                  onPressed: () => setState(() => _isEditing = true),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: Text('Edit',
                      style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.leaf),
                ),
            ],
          ),

          // ── Hero Card ──
          _buildHeroCard(),
          const SizedBox(height: 20),

          // ── Personal Info ──
          _buildPersonalInfo(),
          const SizedBox(height: 20),

          // ── Goals & Preferences ──
          _buildGoals(),
          const SizedBox(height: 20),

          // ── Action Buttons ──
          if (_isEditing) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() => _isEditing = false);
                      _loadProfile(); // revert changes
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Cancel',
                        style: GoogleFonts.dmSans(
                            color: AppColors.inkMuted, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.leaf,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text('Save Changes', style: GoogleFonts.dmSans()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],

          // ── Logout ──
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                await ref.read(authServiceProvider).signOut();
                if (mounted) {
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (r) => false);
                }
              },
              icon: const Icon(Icons.logout, size: 18),
              label: Text('Log Out', style: GoogleFonts.dmSans(fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.amber,
                side: BorderSide(color: AppColors.amber.withOpacity(0.4)),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Hero Card ──────────────────────────────────────────
  Widget _buildHeroCard() {
    return NvCard(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
                color: AppColors.leaf, shape: BoxShape.circle),
            child: Center(
              child: Text(_initials,
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 36, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _displayName,
            style: GoogleFonts.dmSerifDisplay(fontSize: 22, color: AppColors.ink),
          ),
          const SizedBox(height: 4),
          Text(
            _userEmail,
            style: GoogleFonts.dmSans(fontSize: 13, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }

  // ── Personal Info Card ────────────────────────────────
  Widget _buildPersonalInfo() {
    return NvCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Personal Info',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18, color: AppColors.ink)),
              const Spacer(),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.leafPale,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('EDITING',
                      style: GoogleFonts.dmMono(
                          fontSize: 10, color: AppColors.leaf, letterSpacing: 1)),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isEditing) ...[
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
                  decoration: const InputDecoration(hintText: 'Height (cm)'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _weightCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Weight (kg)'),
                ),
              ),
            ]),
          ] else ...[
            _readOnlyRow('Name', _displayName),
            _readOnlyRow('Age', '${_ageCtrl.text} years'),
            _readOnlyRow('Gender', _gender),
            _readOnlyRow('Height', '${_heightCtrl.text} cm'),
            _readOnlyRow('Weight', '${_weightCtrl.text} kg'),
          ],
        ],
      ),
    );
  }

  // ── Goals Card ────────────────────────────────────────
  Widget _buildGoals() {
    return NvCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Activity & Goals',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 18, color: AppColors.ink)),
              const Spacer(),
              if (_isEditing)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.leafPale,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('EDITING',
                      style: GoogleFonts.dmMono(
                          fontSize: 10, color: AppColors.leaf, letterSpacing: 1)),
                ),
            ],
          ),
          const SizedBox(height: 20),

          if (_isEditing) ...[
            _label('Activity Level'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: ['Sedentary', 'Lightly Active', 'Moderately Active', 'Very Active']
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
              children: ['Lose Weight', 'Maintain Weight', 'Gain Muscle']
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
              children: _plateLabels.entries
                  .map((e) => NvChip(
                        label: e.value,
                        selected: _plateType == e.key,
                        onTap: () => setState(() => _plateType = e.key),
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
          ] else ...[
            _readOnlyRow('Activity Level', _activity),
            _readOnlyRow('Goal', _goal),
            _readOnlyRow('Plate Type', _plateLabels[_plateType] ?? 'Standard'),
            _readOnlyRow('Daily Calories', '${_calorieCtrl.text} kcal'),
          ],
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────

  Widget _readOnlyRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.inkMuted, fontWeight: FontWeight.w500)),
          Text(value,
              style: GoogleFonts.dmSans(
                  fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w600)),
        ],
      ),
    );
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

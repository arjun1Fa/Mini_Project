import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoggedIn = false;
  String _gender = 'Male';
  String _activity = 'Lightly Active';
  String _goal = 'Gain Muscle';

  final _nameCtrl = TextEditingController(text: 'Alex Johnson');
  final _ageCtrl = TextEditingController(text: '28');
  final _heightCtrl = TextEditingController(text: '178');
  final _weightCtrl = TextEditingController(text: '75');
  final _calorieCtrl = TextEditingController(text: '2000');

  @override
  void dispose() {
    _nameCtrl.dispose(); _ageCtrl.dispose();
    _heightCtrl.dispose(); _weightCtrl.dispose();
    _calorieCtrl.dispose();
    super.dispose();
  }

  void _save() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ Profile saved successfully!', style: GoogleFonts.dmSans()),
      backgroundColor: AppColors.leaf,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoggedIn) {
      return _buildLoginView();
    }

    final isWide = MediaQuery.of(context).size.width > 700;

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

  Widget _buildLoginView() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 400),
        child: NvCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('NutriVision',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 28, color: AppColors.ink)),
              const SizedBox(height: 16),
              const Text('Please login or sign up to view and manage your profile.',
                  textAlign: TextAlign.center),
              const SizedBox(height: 32),
              const TextField(
                decoration: InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              const TextField(
                obscureText: true,
                decoration: InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () => setState(() => _isLoggedIn = true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.leaf,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Login / Sign Up'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeft() {
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
                  child: Text('A',
                      style: GoogleFonts.dmSerifDisplay(
                          fontSize: 36, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 16),
              Text('Alex Johnson',
                  style: GoogleFonts.dmSerifDisplay(
                      fontSize: 22, color: AppColors.ink)),
              const SizedBox(height: 4),
              Text('Member since Jan 2025',
                  style: GoogleFonts.dmSans(
                      fontSize: 13, color: AppColors.inkMuted)),
              const SizedBox(height: 24),
              const Divider(color: AppColors.border),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _profileStat('24', 'Meals'),
                  _profileStat('7', 'Day Streak'),
                  _profileStat('70', 'Avg Score'),
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
              TextField(controller: _nameCtrl,
                  decoration: const InputDecoration(hintText: 'Your name')),
              const SizedBox(height: 16),

              _label('Age'),
              TextField(controller: _ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(hintText: 'Your age')),
              const SizedBox(height: 16),

              _label('Gender'),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: ['Male', 'Female', 'Other'].map((g) => NvChip(
                  label: g,
                  selected: _gender == g,
                  onTap: () => setState(() => _gender = g),
                )).toList(),
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
                spacing: 8, runSpacing: 8,
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
                spacing: 8, runSpacing: 8,
                children: ['Lose Weight', 'Maintain Weight', 'Gain Muscle']
                    .map((g) => NvChip(
                          label: g,
                          selected: _goal == g,
                          onTap: () => setState(() => _goal = g),
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
                  onPressed: () => setState(() => _isLoggedIn = false),
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
          style: GoogleFonts.dmSerifDisplay(fontSize: 24, color: AppColors.ink)),
      const SizedBox(height: 4),
      Text(label,
          style: GoogleFonts.dmSans(fontSize: 12, color: AppColors.inkMuted)),
    ]);
  }

  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text.toUpperCase(),
        style: GoogleFonts.dmSans(
          fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 0.8, color: AppColors.inkMuted,
        ),
      ),
    );
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: GoogleFonts.dmSans()),
      backgroundColor: AppColors.ink,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_theme.dart';
import '../widgets/widgets.dart';

class ManualEntryScreen extends StatefulWidget {
  const ManualEntryScreen({super.key});

  @override
  State<ManualEntryScreen> createState() => _ManualEntryScreenState();
}

class _ManualEntryScreenState extends State<ManualEntryScreen> {
  final _nameCtrl = TextEditingController();
  final _calCtrl = TextEditingController();
  final _proCtrl = TextEditingController();
  final _carbCtrl = TextEditingController();
  final _fatCtrl = TextEditingController();
  final _portionCtrl = TextEditingController();

  String _mealType = 'Lunch';
  final _mealTypes = ['Breakfast', 'Lunch', 'Dinner', 'Snack'];

  final _suggestions = [
    ('🍗', 'Chicken Breast'),
    ('🍚', 'White Rice'),
    ('🥦', 'Broccoli'),
    ('🥚', 'Boiled Egg'),
    ('🥑', 'Avocado'),
    ('🐟', 'Salmon'),
  ];

  static const _emojiMap = {
    'chicken': '🍗', 'rice': '🍚', 'broccoli': '🥦',
    'egg': '🥚', 'avocado': '🥑', 'salmon': '🐟',
    'pizza': '🍕', 'salad': '🥗', 'ramen': '🍜',
    'burger': '🍔', 'pasta': '🍝', 'wrap': '🥙',
  };

  String get _previewEmoji {
    final low = _nameCtrl.text.toLowerCase();
    for (final e in _emojiMap.entries) {
      if (low.contains(e.key)) return e.value;
    }
    return '🍽️';
  }

  int get _cal => int.tryParse(_calCtrl.text) ?? 0;
  int get _pro => int.tryParse(_proCtrl.text) ?? 0;
  int get _carb => int.tryParse(_carbCtrl.text) ?? 0;
  int get _fat => int.tryParse(_fatCtrl.text) ?? 0;

  @override
  void dispose() {
    _nameCtrl.dispose(); _calCtrl.dispose(); _proCtrl.dispose();
    _carbCtrl.dispose(); _fatCtrl.dispose(); _portionCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('⚠️ Please enter a food name', style: GoogleFonts.dmSans()),
        backgroundColor: AppColors.amber,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('✅ ${_nameCtrl.text} added to your log!', style: GoogleFonts.dmSans()),
      backgroundColor: AppColors.leaf,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
    _nameCtrl.clear(); _calCtrl.clear(); _proCtrl.clear();
    _carbCtrl.clear(); _fatCtrl.clear(); _portionCtrl.clear();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 700;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(
            label: 'Log Manually',
            title: 'Manual Entry',
            subtitle: 'Enter your meal details below',
          ),

          if (isWide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildForm()),
                const SizedBox(width: 24),
                Expanded(flex: 2, child: _buildPreview()),
              ],
            )
          else
            Column(children: [
              _buildForm(),
              const SizedBox(height: 20),
              _buildPreview(),
            ]),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return NvCard(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Meal Details',
              style: GoogleFonts.dmSerifDisplay(fontSize: 20, color: AppColors.ink)),
          const SizedBox(height: 24),

          _label('Food Name'),
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(hintText: 'e.g., Grilled Chicken Breast'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 20),

          _label('Quick Suggestions'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _suggestions.map((s) {
              final (emoji, name) = s;
              return GestureDetector(
                onTap: () {
                  setState(() => _nameCtrl.text = '$emoji $name');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text('$emoji $name',
                      style: GoogleFonts.dmSans(
                          fontSize: 13,
                          color: AppColors.inkSoft,
                          fontWeight: FontWeight.w500)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          _label('Meal Type'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _mealTypes.map((t) => NvChip(
              label: t,
              selected: _mealType == t,
              onTap: () => setState(() => _mealType = t),
            )).toList(),
          ),
          const SizedBox(height: 20),

          _label('Portion Size'),
          TextField(
            controller: _portionCtrl,
            decoration: const InputDecoration(hintText: 'e.g., 200g or 1 serving'),
          ),
          const SizedBox(height: 20),

          _label('Nutritional Information (Optional)'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 3.5,
            children: [
              TextField(controller: _calCtrl, decoration: const InputDecoration(hintText: 'Calories'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
              TextField(controller: _proCtrl, decoration: const InputDecoration(hintText: 'Protein g'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
              TextField(controller: _carbCtrl, decoration: const InputDecoration(hintText: 'Carbs g'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
              TextField(controller: _fatCtrl, decoration: const InputDecoration(hintText: 'Fat g'), keyboardType: TextInputType.number, onChanged: (_) => setState(() {})),
            ],
          ),
          const SizedBox(height: 24),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Add to Log'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    return NvCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'LIVE PREVIEW',
            style: GoogleFonts.dmMono(
                fontSize: 11, letterSpacing: 1.2, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.cream,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(_previewEmoji,
                    style: const TextStyle(fontSize: 36)),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Center(
            child: Text(
              _nameCtrl.text.isEmpty ? 'Your meal' : _nameCtrl.text,
              textAlign: TextAlign.center,
              style: GoogleFonts.dmSerifDisplay(
                  fontSize: 18, color: AppColors.ink),
            ),
          ),
          const SizedBox(height: 24),

          _previewRow('Calories', _cal, 800, AppColors.amber),
          const SizedBox(height: 12),
          _previewRow('Protein', _pro, 60, AppColors.leafLight),
          const SizedBox(height: 12),
          _previewRow('Carbs', _carb, 100, AppColors.sky),
          const SizedBox(height: 12),
          _previewRow('Fat', _fat, 50, AppColors.gold),
        ],
      ),
    );
  }

  Widget _previewRow(String label, int val, int max, Color color) {
    return Row(children: [
      SizedBox(
        width: 60,
        child: Text(label,
            style: GoogleFonts.dmSans(
                fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: LinearProgressIndicator(
            value: max > 0 ? (val / max).clamp(0.0, 1.0) : 0,
            minHeight: 5,
            backgroundColor: AppColors.creamDark,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        width: 30,
        child: Text(
          val > 0 ? '$val' : '—',
          textAlign: TextAlign.right,
          style: GoogleFonts.dmMono(fontSize: 11, color: AppColors.inkMuted),
        ),
      ),
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

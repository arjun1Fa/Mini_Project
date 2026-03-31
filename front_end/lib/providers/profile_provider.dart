import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import 'api_provider.dart';

/// State for the user profile.
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({this.profile, this.isLoading = false, this.error});

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref _ref;

  ProfileNotifier(this._ref) : super(const ProfileState());

  /// Fetch profile from the API.
  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);

    try {
      final api = _ref.read(apiServiceProvider);
      final profile = await api.getProfile();
      state = state.copyWith(profile: profile, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        // Keep previously loaded profile if available
        profile: state.profile,
      );
    }
  }

  /// Update profile fields on the server and locally.
  Future<bool> updateProfile(Map<String, dynamic> fields) async {
    try {
      final api = _ref.read(apiServiceProvider);
      await api.updateProfile(fields);

      // Update local state
      final current = state.profile ?? const UserProfile();
      state = state.copyWith(
        profile: current.copyWith(
          fullName: fields['full_name'] as String? ?? current.fullName,
          dailyGoalKcal:
              fields['daily_goal_kcal'] as int? ?? current.dailyGoalKcal,
          plateType: fields['plate_type'] as String? ?? current.plateType,
          units: fields['units'] as String? ?? current.units,
        ),
      );
      return true;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      return false;
    }
  }
}

final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(ref);
});

/// User model for stats and profile-derived data.
/// [stats] typically comes from the backend (e.g. profiles.stats or a dedicated stats table).
class UserModel {
  UserModel({this.stats});

  final Map<String, dynamic>? stats;

  /// Build from the current profile map (e.g. Supabase profile with optional [stats]).
  factory UserModel.fromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return UserModel(stats: null);
    final s = profile['stats'];
    final statsMap = s is Map<String, dynamic> ? s : (s is Map ? Map<String, dynamic>.from(s) : null);
    return UserModel(stats: statsMap);
  }
}

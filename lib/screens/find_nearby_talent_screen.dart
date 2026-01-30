import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import 'profile_detail_screen.dart';

class FindNearbyTalentScreen extends StatefulWidget {
  const FindNearbyTalentScreen({super.key});

  @override
  State<FindNearbyTalentScreen> createState() => _FindNearbyTalentScreenState();
}

class _FindNearbyTalentScreenState extends State<FindNearbyTalentScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _cards = [];
  Map<String, dynamic>? _myProfile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        setState(() {
          _cards = [];
          _isLoading = false;
        });
        return;
      }

      final profile = await SupabaseService.getCurrentUserProfile();
      _myProfile = profile;
      final userType = (profile?['user_type'] as String?)?.trim().toLowerCase();
      if (userType == null || userType.isEmpty) {
        setState(() {
          _cards = [];
          _isLoading = false;
        });
        return;
      }

      double? lat = SupabaseService.lastKnownLocation.value?.lat;
      double? lon = SupabaseService.lastKnownLocation.value?.lon;
      lat ??= (profile?['latitude'] as num?)?.toDouble();
      lon ??= (profile?['longitude'] as num?)?.toDouble();

      if (lat == null || lon == null) {
        setState(() {
          _cards = [];
          _isLoading = false;
        });
        return;
      }

      final raw = (profile?['talents'] as List<dynamic>?) ?? <dynamic>[];
      final myTalents = raw.map((e) => e.toString()).toList();

      final cards = await SupabaseService.getMatchingCards(
        userType: userType,
        currentLatitude: lat,
        currentLongitude: lon,
        userTalentsOrGoals: myTalents,
        currentUserId: user.id,
      );

      setState(() {
        _cards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load nearby: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Nearby Talent')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: _cards.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 120),
                        Center(child: Text('No results.')),
                      ],
                    )
                  : ListView.separated(
                      itemCount: _cards.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, i) {
                        final c = _cards[i];
                        final name = (c['name'] as String?) ?? 'Unknown';
                        final dist = (c['distance_meters'] as num?)?.toDouble();
                        return ListTile(
                          title: Text(name),
                          subtitle: Text(dist == null ? '' : '${dist.toStringAsFixed(0)} m'),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProfileDetailScreen(
                                  profile: c,
                                  currentUserProfile: _myProfile,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
    );
  }
}


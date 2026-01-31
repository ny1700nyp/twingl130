import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/category_service.dart';
import '../services/supabase_service.dart';
import '../utils/time_utils.dart';
import '../widgets/category_selector_widget.dart';

class OnboardingScreen extends StatefulWidget {
  final String? initialUserType;
  final Map<String, dynamic>? existingProfile;

  const OnboardingScreen({
    super.key,
    this.initialUserType,
    this.existingProfile,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _aboutController = TextEditingController();

  bool _isSaving = false;
  String _userType = 'trainer';
  String _gender = 'Prefer not to say';
  List<String> _talents = [];
  final Set<String> _teachingMethods = {'onsite', 'online'};

  double? _latitude;
  double? _longitude;

  String? _mainPhotoDataUrl;

  bool _dummyLocationOffsetApplied = false;
  bool _dummyDataPrefilled = false;
  final math.Random _dummyRng = math.Random();

  @override
  void initState() {
    super.initState();
    final initType = (widget.initialUserType ?? '').trim().toLowerCase();
    if (initType == 'trainer' || initType == 'trainee') {
      _userType = initType;
    }
    final existing = widget.existingProfile;
    if (existing != null) {
      final t = (existing['user_type'] as String?)?.trim().toLowerCase();
      if (t == 'trainer' || t == 'trainee') _userType = t!;
      _nameController.text = (existing['name'] as String?) ?? '';
      final age = existing['age'];
      if (age is int) _ageController.text = age.toString();
      _gender = (existing['gender'] as String?) ?? _gender;
      _aboutController.text = (existing['about_me'] as String?) ?? '';
      final talents = (existing['talents'] as List<dynamic>?)?.map((e) => e.toString()).toList();
      if (talents != null) _talents = talents;
      final methods = (existing['teaching_methods'] as List<dynamic>?)?.map((e) => e.toString()).toList();
      if (methods != null) {
        _teachingMethods
          ..clear()
          ..addAll(methods);
      }
      final lat = existing['latitude'];
      final lon = existing['longitude'];
      if (lat is num) _latitude = lat.toDouble();
      if (lon is num) _longitude = lon.toDouble();
      _mainPhotoDataUrl = existing['main_photo_path'] as String?;
    }
    _maybeLoadCurrentLocation();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.existingProfile == null && _isAnonymousSession()) {
        // Dummy profiles are always trainer.
        setState(() {
          _userType = 'trainer';
        });
        _prefillDummyOnboardingData(regenerate: false);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _aboutController.dispose();
    super.dispose();
  }

  Future<void> _maybeLoadCurrentLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }

      final p = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
        timeLimit: const Duration(seconds: 10),
      );
      final adjusted = _maybeApplyDummyLocationOffset(p);
      if (!mounted) return;
      setState(() {
        _latitude = adjusted.latitude;
        _longitude = adjusted.longitude;
      });

      await SupabaseService.setLastKnownLocationForCurrentUser(
        lat: adjusted.latitude,
        lon: adjusted.longitude,
      );
    } catch (_) {
      // Location is optional for onboarding; allow user to continue.
    }
  }

  bool _isAnonymousSession() {
    try {
      final token = Supabase.instance.client.auth.currentSession?.accessToken;
      if (token == null || token.isEmpty) return false;
      final parts = token.split('.');
      if (parts.length != 3) return false;
      final normalized = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded);
      return map is Map<String, dynamic> && map['is_anonymous'] == true;
    } catch (_) {
      return false;
    }
  }

  Position _maybeApplyDummyLocationOffset(Position original) {
    if (!_isAnonymousSession()) return original;
    if (_dummyLocationOffsetApplied) return original;

    // 1..12 km random offset
    final distanceKm = 1 + _dummyRng.nextInt(12); // 1..12
    final bearing = _dummyRng.nextDouble() * 2 * math.pi;

    const earthRadiusKm = 6371.0;
    final lat1 = original.latitude * (math.pi / 180.0);
    final lon1 = original.longitude * (math.pi / 180.0);
    final dr = distanceKm / earthRadiusKm;

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(dr) + math.cos(lat1) * math.sin(dr) * math.cos(bearing),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(dr) * math.cos(lat1),
          math.cos(dr) - math.sin(lat1) * math.sin(lat2),
        );

    double wrapLon(double lonRad) {
      var x = lonRad;
      while (x > math.pi) {
        x -= 2 * math.pi;
      }
      while (x < -math.pi) {
        x += 2 * math.pi;
      }
      return x;
    }

    final newLat = lat2 * (180.0 / math.pi);
    final newLon = wrapLon(lon2) * (180.0 / math.pi);

    _dummyLocationOffsetApplied = true;
    return Position(
      latitude: newLat,
      longitude: newLon,
      timestamp: original.timestamp,
      accuracy: original.accuracy,
      altitude: original.altitude,
      altitudeAccuracy: original.altitudeAccuracy,
      heading: original.heading,
      headingAccuracy: original.headingAccuracy,
      speed: original.speed,
      speedAccuracy: original.speedAccuracy,
    );
  }

  Future<List<String>> _loadAllCategoryItemsFlat() async {
    final categories = await CategoryService.loadCategories();
    final out = <String>[];
    for (final c in categories) {
      for (final sub in c.subItems) {
        out.addAll(sub.items);
      }
    }
    return out.where((e) => e.trim().isNotEmpty).toList();
  }

  List<String> _pickRandomUnique(List<String> items, int count) {
    final unique = items.toSet().toList();
    unique.shuffle(_dummyRng);
    final maxN = math.min(6, unique.length);
    final n = math.max(1, math.min(count, maxN));
    return unique.take(n).toList();
  }

  Future<void> _prefillDummyOnboardingData({required bool regenerate}) async {
    if (_dummyDataPrefilled && !regenerate) return;
    _dummyDataPrefilled = true;

    const firstNames = <String>[
      'John','Michael','David','James','Robert','William','Christopher','Daniel','Matthew','Joshua',
      'Andrew','Joseph','Anthony','Ryan','Nicholas','Samuel','Benjamin','Jonathan','Brandon','Kevin',
    ];
    const lastNames = <String>[
      'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller','Davis','Rodriguez','Martinez',
      'Hernandez','Lopez','Gonzalez','Wilson','Anderson','Thomas','Taylor','Moore','Jackson','Martin',
    ];
    final first = firstNames[_dummyRng.nextInt(firstNames.length)];
    final last = lastNames[_dummyRng.nextInt(lastNames.length)];
    final name = '$first $last';

    const genders = ['man', 'woman', 'non-binary', 'Prefer not to say'];
    final gender = genders[_dummyRng.nextInt(genders.length)];
    final age = 18 + _dummyRng.nextInt(38); // 18..55

    final allItems = await _loadAllCategoryItemsFlat();
    final picked = _pickRandomUnique(allItems, 1 + _dummyRng.nextInt(6));

    final aboutTemplates = <String>[
      'Friendly trainer who loves helping beginners.',
      'Patient and structured lessons, focused on progress.',
      'I tailor sessions to your goals and schedule.',
      'Let’s build skills with practical exercises.',
      'Supportive coaching with clear feedback.',
    ];
    final about = aboutTemplates[_dummyRng.nextInt(aboutTemplates.length)];

    if (!mounted) return;
    setState(() {
      _userType = 'trainer';
      _nameController.text = name;
      _gender = gender;
      _ageController.text = age.toString();
      _talents = picked;
      _teachingMethods
        ..clear()
        ..add('online')
        ..add(_dummyRng.nextBool() ? 'onsite' : 'online');
      _aboutController.text = about;
      // Photos are intentionally NOT filled; user attaches manually.
    });
  }

  Future<void> _pickMainPhoto() async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      final mime = _guessMimeType(file.name);
      final b64 = base64Encode(bytes);
      if (!mounted) return;
      setState(() {
        _mainPhotoDataUrl = 'data:$mime;base64,$b64';
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to pick photo: $e')),
      );
    }
  }

  String _guessMimeType(String filename) {
    final lower = filename.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'image/jpeg';
  }

  Future<void> _save() async {
    if (_isSaving) return;
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You are not logged in.')),
      );
      return;
    }

    if (_talents.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least 1 talent/goal.')),
      );
      return;
    }

    // Photo required (dummy 포함 수동 첨부)
    if ((_mainPhotoDataUrl ?? '').trim().isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a main photo.')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final name = _nameController.text.trim();
      final age = int.tryParse(_ageController.text.trim());
      final about = _aboutController.text.trim();

      final payload = <String, dynamic>{
        'user_id': user.id,
        'user_type': _userType,
        'name': name,
        'gender': _gender,
        'age': age,
        'latitude': _latitude,
        'longitude': _longitude,
        'talents': _talents,
        'teaching_methods': _teachingMethods.toList(),
        'about_me': about.isEmpty ? null : about,
        'main_photo_path': _mainPhotoDataUrl,
        'updated_at': TimeUtils.nowUtcIso(),
      };

      await SupabaseService.upsertProfile(payload);

      // Also update location fields via helper (keeps behavior consistent elsewhere).
      if (_latitude != null && _longitude != null) {
        await SupabaseService.updateUserLocation(
          latitude: _latitude!,
          longitude: _longitude!,
        );
      }

      if (!mounted) return;
      if (widget.existingProfile != null) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save profile: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDummy = widget.existingProfile == null && _isAnonymousSession();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Onboarding'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (isDummy)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text('Demo mode: random data is filled (photos skipped).'),
                      ),
                      TextButton(
                        onPressed: _isSaving ? null : () => _prefillDummyOnboardingData(regenerate: true),
                        child: const Text('Regenerate'),
                      ),
                    ],
                  ),
                ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'trainer', label: Text('Trainer')),
                  ButtonSegment(value: 'trainee', label: Text('Trainee')),
                ],
                selected: {_userType},
                onSelectionChanged: isDummy ? null : (s) => setState(() => _userType = s.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Name is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'man', child: Text('Man')),
                  DropdownMenuItem(value: 'woman', child: Text('Woman')),
                  DropdownMenuItem(value: 'non-binary', child: Text('Non-binary')),
                  DropdownMenuItem(value: 'Prefer not to say', child: Text('Prefer not to say')),
                ],
                onChanged: (v) => setState(() => _gender = v ?? 'Prefer not to say'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Age (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              CategorySelectorWidget(
                selectedItems: _talents,
                onSelectionChanged: (v) => setState(() => _talents = v),
                title: _userType == 'trainer' ? 'What can you teach?' : 'What do you want to learn?',
                hint: 'Select up to 6.',
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Onsite'),
                    selected: _teachingMethods.contains('onsite'),
                    onSelected: (v) => setState(() {
                      v ? _teachingMethods.add('onsite') : _teachingMethods.remove('onsite');
                    }),
                  ),
                  FilterChip(
                    label: const Text('Online'),
                    selected: _teachingMethods.contains('online'),
                    onSelected: (v) => setState(() {
                      v ? _teachingMethods.add('online') : _teachingMethods.remove('online');
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _aboutController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'About me (optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isSaving ? null : _pickMainPhoto,
                    icon: const Icon(Icons.photo),
                    label: const Text('Pick main photo'),
                  ),
                  const SizedBox(width: 12),
                  if (_mainPhotoDataUrl != null)
                    const Text('Selected', style: TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

